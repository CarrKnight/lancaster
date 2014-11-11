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
    _initializePresentations();
  }
  /**
   *
   * the presentation object of the gas market
   */
  SimpleMarketPresentation gasPresentation;

  _initializePresentations(){
    var market = _model.markets["gas"];
    if(market != null) {
      gasPresentation = new SimpleMarketPresentation(market);
      gasPresentation.start(_model.schedule);
    }
  }


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