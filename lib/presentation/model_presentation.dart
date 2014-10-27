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
  final Model model;


  /**
   * grabs the model, starts it and initialize presentations!
   */
  ModelPresentation(this.model) {
    model.start();
    _initializePresentations();
  }
  /**
   *
   * the presentation object of the gas market
   */
  SimpleMarketPresentation gasPresentation;

  _initializePresentations(){
    var market = model.gasMarket;
    if(market != null) {
      gasPresentation = new SimpleMarketPresentation(market);
      gasPresentation.start(model.schedule);
    }
  }

}