/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.model;


/**
 * the price predictor's job is to predict what might be the future price,
 * taking into consideration possible production changes
 */
abstract class PricePredictor{

  /**
   * predict the price this trader will set for buying/selling after a
   * specific change in input. [quantityChange] is the  expected change in
   * input needed or output produced.
   */
  double predictPrice(Trader trader,double currentQuantity);
}


/**
 * always predicts last CLOSING price. Also is a singleton
 */
class LastPricePredictor implements PricePredictor
{

  static final  LastPricePredictor _singleton = new LastPricePredictor
  ._internal();

  LastPricePredictor._internal();

  /**
   *  always predicts last CLOSING price
   */
  factory LastPricePredictor(){
    return _singleton;
  }

  double predictPrice(Trader trader, double changeInInput) =>
  trader.lastClosingPrice;
}