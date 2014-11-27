part of lancaster.model;
/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */


/**
 * a model is just:
 *  - a schedule
 *  - a scenario
 *  - a randomizer
 *  - a list of agents
 *  - possibly markets
 */
class Model {

  final Schedule _schedule = new Schedule();

  Random random;

  final List<Object> agents = new List();

  final Map<String,Market> markets = new HashMap();

  //this is never null, but the default scenario is empty
  Scenario scenario;

  Model(int seed, [givenScenario = null]){
    random = new Random(seed);
    this.scenario = givenScenario != null ? givenScenario :  new SimpleScenario.empty();
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


typedef void ModelInitialization(Model model);

/**
 * calls a function when start is called. Useful for small stuff
 */
class SimpleScenario extends Scenario{


  ModelInitialization initializer;

  SimpleScenario(this.initializer);

  SimpleScenario.empty():this((Model model){});

  void start(Model model)=>initializer(model);

  SimpleScenario.simpleSeller({minInitialPrice : 100.0,
                        maxInitialPrice:100, dailyFlow : 40.0,
                        intercept:100.0,slope:-1.0,minP:0.05,maxP:.5,minI:0.05,
                        maxI:.5,int seed:1,int competitors:1}):
  this((Model model){
    ExogenousSellerMarket market = new ExogenousSellerMarket.linear(intercept:intercept,
    slope:slope);
    market.start(model.schedule);

    Random random = new Random(seed);
    model.markets["gas"]=market;
    //initial price 0
    for(int i=0; i< competitors; i++) {
      double p = random.nextDouble() * (maxP - minP) + minP;
      double i = random.nextDouble() * (maxI - minI) + minI;
      double initialPrice = random.nextDouble() *
      (maxInitialPrice - minInitialPrice) + minInitialPrice;
      ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader.PIDBufferSellerFixedInflow(dailyFlow,
      market, initialPrice:initialPrice, p:p, i:i);
      model.agents.add(seller);
      seller.start(model.schedule);
    }




  });


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
      double p = random.nextDouble() * (maxP - minP) + minP;
      double i = random.nextDouble() * (maxI - minI) + minI;
      double initialPrice = random.nextDouble() *
      (maxInitialPrice - minInitialPrice) + minInitialPrice;

      ZeroKnowledgeTrader buyer = new ZeroKnowledgeTrader.PIDBuyer(market,
      flowTarget:dailyTarget,initialPrice:initialPrice,p:p,i:i);
      model.agents.add(buyer);
      buyer.start(model.schedule);

    }
  });
}

/**
 * a simple scenario with one firm hiring workers to produce one output to
 * sell. For now just a way to test that every element in the firm works
 * properly
 */
class SimpleFirmScenario extends Scenario
{



  double minInitialPriceBuying = 0.0;
  double maxInitialPriceBuying = 100.0;
  double minInitialPriceSelling = 0.0;
  double maxInitialPriceSelling = 100.0;
  double demandIntercept=100.0; double demandSlope=-1.0;
  double supplyIntercept=0.0; double supplySlope=1.0;
  //sales pid
  double salesMinP=0.05; double salesMaxP=.5;
  double salesMinI=0.05; double salesMaxI=.5;
   //purchases pid
  double purchaseMinP=0.05; double purchaseMaxP=.5;
  double purchaseMinI=0.05; double purchaseMaxI=.5;
  //plant
  double productionMultiplier = 1.0;
  //worker target
  double workerTarget = 10.0;


  start(Model model)
  {

    Firm mainFirm = new Firm();
    Random random = model.random;


    //build labor market
    ExogenousBuyerMarket laborMarket = new ExogenousBuyerMarket.linear
    (intercept:supplyIntercept, slope:supplySlope,goodType : "labor");
    laborMarket.start(model.schedule);
    model.markets["labor"]=laborMarket;

    //build hr
    double p = random.nextDouble() * (purchaseMaxP - purchaseMinP) + purchaseMinP;
    double i = random.nextDouble() * (purchaseMaxI - purchaseMinI) + purchaseMinI;
    double initialPrice = random.nextDouble() *
    (maxInitialPriceBuying - minInitialPriceBuying) + minInitialPriceBuying;
    ZeroKnowledgeTrader hr = new ZeroKnowledgeTrader.PIDBuyer(laborMarket,
    flowTarget:workerTarget,initialPrice:initialPrice,p:p,i:i,d:0.0,
    givenInventory:mainFirm);
    mainFirm.addPurchasesDepartment(hr);

    //build sales market
    ExogenousSellerMarket market = new ExogenousSellerMarket.linear
    (intercept:demandIntercept, slope:demandSlope);
    market.start(model.schedule);
    model.markets["gas"]=market;
    
    //build sales
    p = random.nextDouble() * (salesMaxP - salesMinP) + salesMinP;
    i = random.nextDouble() * (salesMaxI - salesMinI) + salesMinI;
    initialPrice = random.nextDouble() *
    (maxInitialPriceSelling - minInitialPriceSelling) + minInitialPriceSelling;
    ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader.PIDBufferSeller(
    market, initialPrice:initialPrice, p:p, i:i,givenInventory:mainFirm);
    mainFirm.addSalesDepartment(seller);


    //build plant
    SISOProductionFunction function = new SISOProductionFunction();
    SISOPlant plant = new SISOPlant(mainFirm.getSection("labor"),
    mainFirm.getSection("gas"),function);
    mainFirm.addPlant(plant);

    model.agents.add(mainFirm);
    mainFirm.start(model.schedule);

  }



}