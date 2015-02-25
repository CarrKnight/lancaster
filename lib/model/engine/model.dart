part of lancaster.model;
/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */


/**
 * a model is just:
 *  - a parameter database
 *  - a schedule
 *  - a scenario
 *  - a randomizer
 *  - a list of agents
 *  - possibly markets
 */
class Model {

  final Schedule _schedule = new Schedule();

  ParameterDatabase parameters;

  Random random;

  final List<Object> agents = new List();

  final Map<String,Market> markets = new HashMap();

  //this is never null, but the default scenario is empty
  Scenario scenario;

  Model(int seed, [Scenario givenScenario = null]){
    random = new Random(seed);
    this.scenario = givenScenario != null ? givenScenario :  new SimpleScenario.empty();
  }

  Model.randomSeed([Scenario givenScenario = null]):
  this(new DateTime.now().millisecondsSinceEpoch,givenScenario);


  Model.fromJSON(String json, [int seed = null])
  {
    this.parameters = new ParameterDatabase(json,seed);
    random = parameters.random;
    this.scenario = _generateScenarioFromDatabase(parameters);
  }


  //starts the scenario, that's all
  void start()
  {
    scenario.start(this);
  }

  Schedule get schedule => _schedule;




}

/**
 *scenarios' jobs is to set up agents and markets
 */

abstract class Scenario{


  void start(Model model);
}


Scenario _generateScenarioFromDatabase(ParameterDatabase db)
{
  String strategyName = db.getAsString("run.scenario");
  if (strategyName == "OneMarketCompetition")
    return new OneMarketCompetition();

  throw new Exception("don't know what $strategyName is regarding hr pricing!");
}


typedef void ModelInitialization(Model model);





class SimpleSellerScenario extends Scenario
{

  num dailyFlow;

  ModelInitialization initializer;

  final num intercept;

  final num slope;

  void start(Model model)=>initializer(model);


  SimpleSellerScenario.buffer({minInitialPrice : 100.0,
                              maxInitialPrice:100, this.dailyFlow : 40.0,
                              this.intercept:100.0,this.slope:-1.0,minP:0.05,
                              maxP:.5,
                              minI:0.05,
                              maxI:.5,int seed:1,int competitors:1})
  {
    initializer = (Model model) {
      ExogenousSellerMarket market = new ExogenousSellerMarket.linear(intercept:intercept,
                                                                      slope:slope);
      market.start(model.schedule);

      Random random = new Random(seed);
      model.markets["gas"] = market;
      //initial price 0
      for (int i = 0; i < competitors; i++) {
        num p = random.nextDouble() * (maxP - minP) + minP;
        num i = random.nextDouble() * (maxI - minI) + minI;
        num initialPrice = random.nextDouble() *
                              (maxInitialPrice - minInitialPrice) + minInitialPrice;

        PIDAdaptive pricing =
        new PIDAdaptive.StockoutSeller(initialPrice:initialPrice, p:p, d:0.0,
                                       i:i);
        ExogenousSellerScenario toReturn =new ExogenousSellerScenario._internal(
                (num price){(pricing.pid as PIDController).offset = price;},()
            =>pricing.value);

        ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader.PIDBufferSellerFixedInflow(dailyFlow,
                                                                                        market, initialPrice:initialPrice, p:p, i:i);
        model.agents.add(seller);
        seller.start(model.schedule);
      }
    };
  }

  SimpleSellerScenario.stockout({minInitialPrice : 100.0,
                                maxInitialPrice:100, this.dailyFlow : 40.0,
                                this.intercept:100.0,this.slope:-1.0,minP:0.05,
                                maxP:.5,
                                minI:0.05,
                                maxI:.5,int seed:1,int competitors:1})
  {
    initializer = (Model model) {
      ExogenousSellerMarket market = new ExogenousSellerMarket.linear(intercept:intercept,
                                                                      slope:slope);
      market.start(model.schedule);

      Random random = new Random(seed);
      model.markets["gas"] = market;
      //initial price 0
      for (int i = 0; i < competitors; i++) {
        num p = random.nextDouble() * (maxP - minP) + minP;
        num i = random.nextDouble() * (maxI - minI) + minI;
        num initialPrice = random.nextDouble() *
                              (maxInitialPrice - minInitialPrice) + minInitialPrice;
        var inventory = new Inventory();
        PIDAdaptive pricing =
        new PIDAdaptive.StockoutSeller(initialPrice:initialPrice, p:p, d:0.0,
                                       i:i);
        ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader(market,pricing,
                                                             new AllOwned(),
                                                             new SimpleSellerTrading(),
                                                             inventory);
        seller.dawnEvents.add(BurnInventories());
        ZeroKnowledgeTrader.addDailyInflowAndDepreciation( seller,dailyFlow,0.0);
        model.agents.add(seller);
        seller.start(model.schedule);
      }
    };
  }

  num get equilibriumPrice => intercept + slope *dailyFlow;


}


/**
 * A simple seller scenario where the sale price is set through this object.
 * Useful for an easy gui demo
 */
typedef void PriceSetter(num newPrice);


class ExogenousSellerScenario extends Scenario
{

  ModelInitialization initializer;


  Data sellerData;

  void start(Model model)=>initializer(model);

  ZeroKnowledgeTrader seller;

  final DataGatherer priceGetter;

  final PriceSetter priceSetter;

  ExogenousSellerScenario._internal(this.priceSetter,this.priceGetter);

  ExogenousSellerMarket market;

  factory ExogenousSellerScenario({initialPrice : 1.0,
                                  num dailyFlow : 50.0,
                                  num intercept:200.0,num slope:-2.0})
  {
    FixedValue pricing = new FixedValue(initialPrice);

    ExogenousSellerScenario toReturn =new ExogenousSellerScenario._internal(
            (num price){pricing.value = price;},()=>pricing.value);

    toReturn.market = new ExogenousSellerMarket.linear(intercept:intercept,slope:slope);

    toReturn.initializer = (Model model) {
      toReturn.market.start(model.schedule);

      model.markets["gas"] = toReturn.market;

      var inventory = new Inventory();
      toReturn.seller = new ZeroKnowledgeTrader(toReturn.market,pricing,
                                                new AllOwned(),
                                                new SimpleSellerTrading(),
                                                inventory);
      toReturn.seller.dawnEvents.add(BurnInventories());
      ZeroKnowledgeTrader.addDailyInflowAndDepreciation( toReturn.seller,dailyFlow,0.0);
      toReturn.sellerData =  toReturn.seller.data;

      //initial price 0
      model.agents.add( toReturn.seller);
      toReturn.seller.start(model.schedule);


    };
    toReturn.equilibriumPrice = intercept + slope *dailyFlow;
    return toReturn;
  }



  factory ExogenousSellerScenario.stockoutPID({num initialPrice : 1.0,
                                              minP:0.05,
                                              maxP:.1,minI:0.05,
                                              maxI:.1,
                                              num dailyFlow : 50.0,
                                              num intercept:200.0,
                                              num slope:-2.0})
  {
    Random random = new Random();
    num p = random.nextDouble() * (maxP - minP) + minP;
    num i = random.nextDouble() * (maxI - minI) + minI;

    PIDAdaptive pricing =
    new PIDAdaptive.StockoutSeller(initialPrice:initialPrice, p:p, d:0.0,
                                   i:i);
    ExogenousSellerScenario toReturn =new ExogenousSellerScenario._internal(
            (num price){(pricing.pid as PIDController).offset = price;},()
        =>pricing.value);
    toReturn.market = new ExogenousSellerMarket.linear(intercept:intercept,slope:slope);

    toReturn.initializer = (Model model)
    {

      toReturn.market.start(model.schedule);

      model.markets["gas"] = toReturn.market;
      //initial price 0

      var inventory = new Inventory();
      toReturn.seller = new ZeroKnowledgeTrader(toReturn.market,pricing,
                                                new AllOwned(),
                                                new SimpleSellerTrading(),
                                                inventory);
      toReturn.seller.dawnEvents.add(BurnInventories());
      ZeroKnowledgeTrader.addDailyInflowAndDepreciation(toReturn.seller,dailyFlow,0.0);
      model.agents.add(toReturn.seller);
      toReturn.seller.start(model.schedule);

      toReturn.sellerData =  toReturn.seller.data;


    };
    toReturn.equilibriumPrice = intercept + slope *dailyFlow;
    return toReturn;
  }


  num get price=>priceGetter();
  void set price(num value){priceSetter(value);}


  num get customersAttracted=>sellerData.getLatestObservation("stockouts")
                                 +sellerData.getLatestObservation("outflow");



  num equilibriumPrice;



}






/**
 * calls a function when start is called. Useful for small stuff
 */
class SimpleScenario extends Scenario{


  ModelInitialization initializer;

  SimpleScenario(this.initializer);

  SimpleScenario.empty():this((Model model){});

  void start(Model model)=>initializer(model);





  SimpleScenario.simpleBuyer({minInitialPrice : 100.0,
                             maxInitialPrice:100, dailyTarget : 40.0,
                             intercept:0.0,slope:1.0,minP:0.05,maxP:.5,minI:0.05,
                             maxI:.5,int seed:1,int competitors:1}):
  this((Model model){
    ExogenousBuyerMarket market = new ExogenousBuyerMarket.linear(intercept:intercept,
                                                                  slope:slope);
    market.start(model.schedule);
    model.markets["gas"]=market;
    //initial price 0
    Random random = new Random(seed);
    for(int i=0; i< competitors; i++) {
      num p = random.nextDouble() * (maxP - minP) + minP;
      num i = random.nextDouble() * (maxI - minI) + minI;
      num initialPrice = random.nextDouble() *
                            (maxInitialPrice - minInitialPrice) + minInitialPrice;

      ZeroKnowledgeTrader buyer = new ZeroKnowledgeTrader.PIDBuyer(market,
                                                                   flowTarget:dailyTarget,initialPrice:initialPrice,p:p,i:i);
      model.agents.add(buyer);
      buyer.start(model.schedule);

    }
  });
}

/**
 * a simple scenario with one firm hiring a fixed number of workers to produce
 * one output to sell. For now just a way to test that every element in the firm works
 * properly
 */
class SimpleFirmScenario extends Scenario
{



  num minInitialPriceBuying = 0.0;
  num maxInitialPriceBuying = 100.0;
  num minInitialPriceSelling = 0.0;
  num maxInitialPriceSelling = 100.0;
  num demandIntercept=100.0; num demandSlope=-1.0;
  num supplyIntercept=0.0; num supplySlope=1.0;
  //sales pid
  num salesMinP=0.05; num salesMaxP=.5;
  num salesMinI=0.05; num salesMaxI=.5;
  //purchases pid
  num purchaseMinP=0.05; num purchaseMaxP=.5;
  num purchaseMinI=0.05; num purchaseMaxI=.5;
  //plant
  num productionMultiplier = 1.0;
  //worker target
  num workerTarget = 10.0;
  Firm mainFirm;
  ExogenousBuyerMarket laborMarket;
  ExogenousSellerMarket goodmarket;

  start(Model model)
  {

    mainFirm = new Firm();
    Random random = model.random;


    //build labor market
    laborMarket = new ExogenousBuyerMarket.linear
    (intercept:supplyIntercept, slope:supplySlope,goodType : "labor");
    laborMarket.start(model.schedule);
    model.markets["labor"]=laborMarket;

    //build hr
    num p = random.nextDouble() * (purchaseMaxP - purchaseMinP) + purchaseMinP;
    num i = random.nextDouble() * (purchaseMaxI - purchaseMinI) + purchaseMinI;
    num initialPrice = random.nextDouble() *
                          (maxInitialPriceBuying - minInitialPriceBuying) + minInitialPriceBuying;
    ZeroKnowledgeTrader hr = new ZeroKnowledgeTrader.PIDBuyer(laborMarket,
                                                              flowTarget:workerTarget,initialPrice:initialPrice,p:p,i:i,d:0.0,
                                                              givenInventory:mainFirm);
    mainFirm.addPurchasesDepartment(hr);

    //build sales market
    goodmarket = new ExogenousSellerMarket.linear
    (intercept:demandIntercept, slope:demandSlope);
    goodmarket.start(model.schedule);
    model.markets["gas"]=goodmarket;

    //build sales
    p = random.nextDouble() * (salesMaxP - salesMinP) + salesMinP;
    i = random.nextDouble() * (salesMaxI - salesMinI) + salesMinI;
    initialPrice = random.nextDouble() *
                   (maxInitialPriceSelling - minInitialPriceSelling) + minInitialPriceSelling;
    ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader.PIDBufferSeller(
        goodmarket, initialPrice:initialPrice, p:p, i:i,givenInventory:mainFirm);
    mainFirm.addSalesDepartment(seller);


    //build plant
    LinearProductionFunction function = new LinearProductionFunction(true,1.0);
    SISOPlant plant = new SISOPlant(mainFirm.getSection("labor"),
                                    mainFirm.getSection("gas"),function);
    mainFirm.addPlant(plant);

    model.agents.add(mainFirm);
    mainFirm.start(model.schedule);


  }



}

