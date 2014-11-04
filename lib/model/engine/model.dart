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

  Scenario.simpleSeller({initialPrice : 100.0, dailyFlow : 40.0,
                        intercept:100.0,slope:-1.0}):
  this((Model model){
    LinearDemandMarket market = new LinearDemandMarket(intercept:intercept,
                                                       slope:slope);
    model.gasMarket = market;
    //initial price 0
    FixedInflowSeller seller = new FixedInflowSeller.bufferInventory(dailyFlow,
    market,initialPrice:initialPrice);
    model.agents.add(seller);



    market.start(model.schedule);
    seller.start(model.schedule);


  });


}