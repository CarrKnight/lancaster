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
  double recordTrade(double quantity, double price);

  /**
   * restore original curve (no quantity traded)
   */
  void reset();

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


  double hypotheticalQuantityAtThisPrice(double price)
  =>(intercept + slope * price);


  double recordTrade(double quantity, double price)=> quantityTraded+=quantity;

  void reset(){quantityTraded = 0.0;}


}

/**
 * useful for infinitely elastic supply or just useless markets where
 * everything you want to buy gets bought(above the minimum price)
 */
class InfinitelyElasticAsk implements ExogenousCurve
{

  double quantityTraded = 0.0;

  double minPrice;


  InfinitelyElasticAsk([this.minPrice=0.0]);

  double quantityAtThisPrice(double price) => price >= minPrice ?
  double.MAX_FINITE : 0.0;


  double recordTrade(double quantity, double price)=> quantityTraded+=quantity;

  void reset(){quantityTraded = 0.0;}


}

typedef double ComputeBudget();

/**
 * basically there is a fixed pool of money that can be spent
 */
class FixedBudget implements ExogenousCurve
{

  /**
   * if true then money unspent is available the next day
   */
  bool cumulative = false;

  final ComputeBudget computeBudget;

  double quantityTraded =0.0;

  double budget = 0.0;

  double recordTrade(double quantity, double price) {
    budget -= quantity * price;
    quantityTraded+= quantity; //update counter
    assert(budget>=-1);
  }

  double quantityAtThisPrice(double price) {
    if(price > 0)
      return budget/price;
    else
      return double.INFINITY;
  }

  void reset() {
    quantityTraded = 0.0;
    if(!cumulative)
      budget = 0.0;
    double newBudget = computeBudget();
    if(newBudget.isFinite)
      budget += newBudget;
  }

  FixedBudget(this.computeBudget);

}


/**
 * basically there is a fixed pool of goods that can be bought/sold
 */
class FixedSupply implements ExogenousCurve
{

  double dailyQuantity = 100.0;


  FixedSupply(this.dailyQuantity);

  double quantityTraded =0.0;


  double recordTrade(double quantity, double price) {
    quantityTraded+= quantity; //update counter
    assert(dailyQuantity>=quantityTraded);
    return quantityTraded;
  }

  double quantityAtThisPrice(double price) {
    if(price > 0)
      return max(dailyQuantity-quantityTraded,0.0);
    else
      return 0.0;
  }

  void reset() {
    quantityTraded = 0.0;
  }


}