/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.model;


/**
 * basically a fixed demand or supply curve
 */
abstract class ExogenousCurve
{

  /**
   * how much is sold/bought at this offer price
   */
  double quantityAtThisPrice(double price);

  /**
   * tell the curve this much [quantity] has been sold/bought
   */
  double recordTrade(double quantity);

  /**
   * restore original curve (no quantity traded)
   */
  double reset();

  double get quantityTraded;

}


class LinearCurve implements ExogenousCurve
{

  double intercept;

  double slope;

  double quantityTraded = 0.0;


  LinearCurve(this.intercept, this.slope);

  double quantityAtThisPrice(double price) =>
    (intercept + slope * price)-quantityTraded;


  double recordTrade(double quantity)=> quantityTraded+=quantity;

  double reset()=>quantityTraded = 0.0;


}