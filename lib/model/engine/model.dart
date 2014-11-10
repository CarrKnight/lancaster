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

  Random _random;

  final List<Object> agents = new List();

  //this can be set at any time, but usually it is set by the scenario
  Market gasMarket;

  //this can be set at any time, but usually it is set by the scenario
  Market laborMarket;

  //this is never null, but the default scenario is empty
  Scenario scenario;

  Model(int seed, [givenScenario = null]){
    _random = new Random(seed);
    this.scenario = givenScenario != null ? givenScenario :  new Scenario.empty();
  }

  //starts the scenario, that's all
  void start()
  {
    scenario.start(this);
  }

  Schedule get schedule => _schedule;




}

/**
 * strictly speaking this could be the scenario already. Unfortunately
 * typedefs aren't mockable so instead I wrap this function type around a
 * "scenario" class
 */
typedef void ModelInitialization(Model model);

class Scenario{

  final ModelInitialization scenario;

  Scenario(this.scenario);

  Scenario.empty():this((Model model){});

  void start(Model model)=>scenario(model);

  Scenario.simpleSeller({minInitialPrice : 100.0,
                        maxInitialPrice:100, dailyFlow : 40.0,
                        intercept:100.0,slope:-1.0,minP:0.05,maxP:.5,minI:0.05,
                        maxI:.5,int seed:1,int competitors:1}):
  this((Model model){
    ExogenousSellerMarket market = new ExogenousSellerMarket.linear(intercept:intercept,
    slope:slope);
    market.start(model.schedule);

    Random random = new Random(seed);
    model.gasMarket = market;
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


  Scenario.simpleBuyer({minInitialPrice : 100.0,
                       maxInitialPrice:100, dailyTarget : 40.0,
                       intercept:0.0,slope:1.0,minP:0.05,maxP:.5,minI:0.05,
                       maxI:.5,int seed:1,int competitors:1}):
  this((Model model){
    ExogenousBuyerMarket market = new ExogenousBuyerMarket.linear(intercept:intercept,
    slope:slope);
    market.start(model.schedule);
    model.gasMarket = market;
    //initial price 0
    Random random = new Random(seed);
    for(int i=0; i< competitors; i++) {
      double p = random.nextDouble() * (maxP - minP) + minP;
      double i = random.nextDouble() * (maxI - minI) + minI;
      double initialPrice = random.nextDouble() *
      (maxInitialPrice - minInitialPrice) + minInitialPrice;

      ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader.PIDBuyer(market,
      flowTarget:dailyTarget,initialPrice:initialPrice,p:p,i:i);
      model.agents.add(seller);
      seller.start(model.schedule);

    }






  });


}