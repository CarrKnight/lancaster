/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.presentation;

/**
 * basically a "decorator" of the model. It creates the presentation objects
 * and starts them
 */
class ModelPresentation
{

  /**
   * the gui-less model
   */
  final Model _model;


  /**
   * grabs the model, starts it and initialize presentations!
   */
  ModelPresentation(this._model) {
    _model.start();
    var market = _model.markets["gas"];
    if(market != null) {
      gasPresentation = new SimpleMarketPresentation(market);
      gasPresentation.start(_model.schedule);
    }
  }

  ModelPresentation.empty(this._model)
  {
    _model.start();
  }

  factory ModelPresentation.SimpleSeller(Model model,
                                         SimpleSellerScenario scenario) {
    ModelPresentation presentation = new ModelPresentation.empty(model);
    presentation.gasPresentation =
    new SimpleMarketPresentation.seller(model.markets["gas"],
                                        scenario.dailyFlow,
                                            ()=>scenario.equilibriumPrice);
    presentation.gasPresentation.start(model.schedule);
    return presentation;
  }
  /**
   *
   * the presentation object of the gas market
   */
  SimpleMarketPresentation gasPresentation;


  final StreamController<StepEvent> _stepSteamer = new  StreamController.broadcast();


  /**
   * a stream with no information but that fires every time there is a step!
   */
  Stream<StepEvent> get stepStream => _stepSteamer.stream;

  /**
   * a way for the view to step the model without taking a reference to it
   */
  void step(){_model.schedule.simulateDay();
    _stepSteamer.add(new StepEvent(day) );
  }



  /**
   * easy way to see what day is it from view
   */
  int get day=>_model.schedule.day;

}



class SimpleFirmPresentation extends ModelPresentation
{

  ZKPresentation sales;
  ZKPresentation hr;


  factory SimpleFirmPresentation(Model model,
                              SimpleFirmScenario scenario) {
    SimpleFirmPresentation presentation = new SimpleFirmPresentation._internal
    (model);

    ZeroKnowledgeTrader salesDepartment = scenario.mainFirm.salesDepartments["gas"];
    presentation.sales = new ZKPresentation(salesDepartment);
    //in the time series we want to put the price and quantity equilibrium
    presentation.sales.addDailyObserver("Equilibrium",()=>90.0);
    presentation.sales.addDailyObserver("Q Equilibrium",()=>10.0);

    presentation.sales.repository.addCurve(scenario.goodmarket.demand,
                                        "Good Demand");
    presentation.sales.repository.addDynamicVLine(()=>salesDepartment.data
    .getLatestObservation("inflow"),"Target");



    ZeroKnowledgeTrader hrDepartment = scenario.mainFirm
    .purchasesDepartments["labor"];
    presentation.hr = new ZKPresentation(hrDepartment);
    //in the time series we want to put the target and the equilibrium
    presentation.hr..addDailyObserver("Target", ()=>hrDepartment.data
    .getLatestObservation("pricer_target"));
    presentation.hr.addDailyObserver("Equilibrium", ()=>10.0);
    presentation.hr.addDailyObserver("Q Equilibrium",()=>10.0);

    presentation.hr.repository.addDynamicVLine(()=>hrDepartment.data
    .getLatestObservation("pricer_target"),"Target");
    presentation.hr.repository.addCurve(scenario.laborMarket.supply,"Labor Supply");


    presentation.sales.start(model.schedule);
    presentation.hr.start(model.schedule);

    return presentation;
  }

  SimpleFirmPresentation._internal(Model model):
  super.empty(model);
}

typedef void DoubleSetter(num newValue);
/**
 * this is basically the "learned competitor" test gui
 */
class MarshallianMicroPresentation extends ModelPresentation
{

  //the first firm sales department gets presented. If there are more, the others are ignored!
  ZKPresentation sales;
  ZKPresentation hr;

  MarshallianMicroPresentation._internal(Model model):
  super.empty(model)
  {
    //empty/useless setters
    hrTargetGetter = ()=> hr== null? double.NAN : hr.trader.data
   .getLatestObservation("pricer_target");
    targetSetter = (num value){}; //doesn't set a thing
  }

  /**
   * classic "learned competitive", a single agent acting as if in a pure
   * competitive environment
   */
  factory MarshallianMicroPresentation(Model model,
                                       OneMarketCompetition scenario) {
    MarshallianMicroPresentation presentation =
    new MarshallianMicroPresentation._internal(model);


    //acts as competitor
    scenario.hrIntializer = (ZeroKnowledgeTrader sales) {
      sales.predictor = new
      LastPricePredictor();
    };
    scenario.salesInitializer = (ZeroKnowledgeTrader sales) {
      sales.predictor = new
      LastPricePredictor();
    };




    ZeroKnowledgeTrader salesDepartment = scenario.firms.first
    .salesDepartments["gas"];
    presentation.sales = new ZKPresentation(salesDepartment);
    //in the time series we want to put the price and quantity equilibrium
    presentation.sales.addDailyObserver("Equilibrium",()=>50.0);
    presentation.sales.addDailyObserver("Q Equilibrium",()=>50.0);

    presentation.sales.repository.addCurve(scenario.goodMarket.demand,
                                           "Good Demand");
    presentation.sales.repository.addDynamicVLine(()=>salesDepartment.data
    .getLatestObservation("inflow"),"Target");



    ZeroKnowledgeTrader hrDepartment = scenario.firms.first
    .purchasesDepartments["labor"];
    presentation.hr = new ZKPresentation(hrDepartment);
    //in the time series we want to put the target and the equilibrium
    presentation.hr..addDailyObserver("Target", ()=>hrDepartment.data
    .getLatestObservation("pricer_target"));
    presentation.hr.addDailyObserver("Equilibrium", ()=>50.0);
    presentation.hr.addDailyObserver("Q Equilibrium",()=>50.0);

    presentation.hr.repository.addDynamicVLine(()=>hrDepartment.data
    .getLatestObservation("pricer_target"),"Target");
    presentation.hr.repository.addCurve(scenario.laborMarket.supply,"Labor Supply");


    presentation.sales.start(model.schedule);
    presentation.hr.start(model.schedule);

    return presentation;
  }


  /**
   * burn inventories, add a bit more curves assuming the target is fixed (also make the target settable)
   */
  factory MarshallianMicroPresentation.fixedTarget(Model model,
                                       OneMarketCompetition scenario) {


    //maximizes as PID
    scenario.salesPricingInitialization = OneMarketCompetition.STOCKOUT_SALES;

    //single agent

    //acts as competitor
    scenario.hrIntializer = (ZeroKnowledgeTrader sales) {
      sales.predictor = new
      LastPricePredictor();
    };
    scenario.salesInitializer = (ZeroKnowledgeTrader sales) {
      sales.predictor = new
      LastPricePredictor();
      //make sales burn inventories since we are doing stockouts!
      sales.dawnEvents.add(BurnInventories());
    };



    MarshallianMicroPresentation presentation =
    new MarshallianMicroPresentation._internal(model);

    ZeroKnowledgeTrader salesDepartment = scenario.firms.first
    .salesDepartments["gas"];

;
    presentation.sales = new ZKPresentation(salesDepartment);


    presentation.sales.repository.addCurve(scenario.goodMarket.demand,
                                           "Good Demand");
    presentation.sales.repository.addDynamicVLine(()=>salesDepartment.data
    .getLatestObservation("inflow"),"Target");



    ZeroKnowledgeTrader hrDepartment = scenario.firms.first
    .purchasesDepartments["labor"];
    presentation.hr = new ZKPresentation(hrDepartment);

    presentation.hr.repository.addDynamicVLine(()=>hrDepartment.data
    .getLatestObservation("pricer_target"),"Target");
    presentation.hr.repository.addCurve(scenario.laborMarket.supply,"Labor Supply");


    presentation.sales.start(model.schedule);
    presentation.hr.start(model.schedule);


    //place a better setter
    //the setter adds a new target-extractor to the maximizer
    presentation.targetSetter = (value){
      (presentation.hr.trader.pricing as PIDAdaptive).targetExtractor =
      new FixedExtractor(value);
    };
    //notice here probably the ugliest code to ever have been written.
    //i mean, it's guaranteed true but still ugh.
    presentation.hrTargetGetter = ()=>
    ((presentation.hr.trader.pricing as PIDAdaptive).targetExtractor as
    FixedExtractor).output;


    return presentation;
  }


  /**
   * so this stuff is basically a way to see and modify targets from gui.
   * It's only used once in the slider demo so for most cases this is pretty
   * useless
   */
  DataGatherer hrTargetGetter;
  DoubleSetter targetSetter;

  num get hrTarget => hrTargetGetter();
  set hrTarget(num value)=>targetSetter(value);
}


class OneMarketFixedWagesPresentation extends ModelPresentation
{

  ZKPresentation sales;
  SISOProductionFunction production;
  final OneMarketCompetition scenario;
  ExogenousCurve demand;

  OneMarketFixedWagesPresentation(Model model, this.scenario)
  :super(model)
  {
    production = scenario.productionFunction;
    //acts as competitor
    //todo this stuff needs to go to the JSON
    scenario.hrIntializer = (ZeroKnowledgeTrader sales) {
      sales.predictor = new
      LastPricePredictor();
    };
    scenario.salesInitializer = (ZeroKnowledgeTrader sales) {
      sales.predictor = new
      LastPricePredictor();
    };

    ZeroKnowledgeTrader salesDepartment = scenario.firms.first
    .salesDepartments["gas"];
    sales = new ZKPresentation(salesDepartment);
    sales.start(model.schedule);

    demand = scenario.goodMarket.demand;

  }


}


/**
 * this uses the exogenous seller scenario to show the problem of the
 */
class SliderDemoPresentation extends ModelPresentation with
Presentation<SliderEvent>
{

  ZKPresentation agent;

  final ExogenousSellerScenario scenario;

  num get price=>scenario.price;
  void set price(num value){scenario.price = value;}

  /**
   * linear demand
   */
  LinearCurve demand;


  num _inflow;

  num get customersAttracted=> scenario.customersAttracted;

  factory SliderDemoPresentation(Model model,
                                 ExogenousSellerScenario scenario, num _inflow) {
    SliderDemoPresentation presentation = new SliderDemoPresentation._internal
    (model,scenario);

    presentation._inflow=_inflow;

    model.schedule.scheduleRepeating(Phase.GUI,(schedule)=>presentation
    ._broadcastEndDay(model.schedule));
    presentation.agent = new ZKPresentation(scenario.seller);
    presentation.agent.start(model.schedule);
    presentation.agent.repository.addDynamicVLine(()=>presentation._inflow,"Supply");
    presentation.demand = scenario.market.demand; //i know it's linear
    presentation.agent.repository.addCurve(scenario.market.demand,"Demand");
    var trader = presentation.agent.trader;
    presentation.agent.addDailyObserver("customers",
                                            ()=> trader.currentOutflow + trader.stockouts);

    return presentation;
  }

  SliderDemoPresentation._internal(Model model,this.scenario):
  super.empty(model);


  final StreamController streamer = new  StreamController.broadcast();



  num get inflow => _inflow;

  set inflow(num value){
    _inflow = value;
    scenario.seller.dawnEvents.clear();
    scenario.seller.dawnEvents.add(BurnInventories());
    ZeroKnowledgeTrader.addDailyInflowAndDepreciation(scenario.seller,_inflow,0.0);
  }


  Map<String, List<double>> get dailyObservations => null;

  num get intercept => demand.intercept;

  set intercept(double value) => demand.intercept = value;

  num get slope => demand.slope;

  set slope(double value) => demand.slope = value;



  /**
   * streams only if it is listened to.
   */
  Stream<SliderEvent> get stream=>streamer.stream;

  _broadcastEndDay(Schedule schedule){


    //don't need to collect data, since everything should have been done by
    // the agent data object (we redirected all observers to there too)

    //stream event
    if(streamer.hasListener)
      streamer.add(new SliderEvent(schedule.day,customersAttracted));

  }

}


class SliderEvent extends PresentationEvent
{
  final int day;

  final num customersAttracted;

  SliderEvent(this.day, this.customersAttracted);


}

class StepEvent extends PresentationEvent
{
  final int day;

  StepEvent(this.day);


}




