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




  /**
   * a way for the view to step the model without taking a reference to it
   */
  void step()=> _model.schedule.simulateDay();

  /**
   * a way for the view to step the model 100 times without taking a reference
   * to it
   */
  void step100Times(){
    for(int i=0; i<100; i++)
    {
      _model.schedule.simulateDay();
    }
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
    //in the time series we want to put the target and the equilibrium
    presentation.sales.addDailyObserver("Target",()=>salesDepartment.data
    .getLatestObservation("inflow"));
    presentation.sales.addDailyObserver("Equilibrium",()=>90.0);
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