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
  num quantityAtThisPrice(num price);


  /**
   * tell the curve this much [quantity] has been sold/bought
   */
  num recordTrade(num quantity, num price);

  /**
   * restore original curve (no quantity traded)
   */
  void reset();

  num get quantityTraded;

}


class LinearCurve implements ExogenousCurve
{

  num intercept;

  num slope;

  num quantityTraded = 0.0;


  LinearCurve(this.intercept, this.slope);

  num quantityAtThisPrice(num price) =>
  (intercept + slope * price)-quantityTraded;


  num hypotheticalQuantityAtThisPrice(num price)
  =>(intercept + slope * price);


  num recordTrade(num quantity, num price)=> quantityTraded+=quantity;

  void reset(){quantityTraded = 0.0;}


}

/**
 * useful for infinitely elastic supply or just useless markets where
 * everything you want to buy gets bought(above the minimum price)
 */
class InfinitelyElasticAsk implements ExogenousCurve
{

  num quantityTraded = 0.0;

  num minPrice;


  InfinitelyElasticAsk([this.minPrice=0.0]);

  num quantityAtThisPrice(num price) => price >= minPrice ?
  double.MAX_FINITE : 0.0;


  num recordTrade(num quantity, num price)=> quantityTraded+=quantity;

  void reset(){quantityTraded = 0.0;}


}

typedef num ComputeBudget();

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

  num quantityTraded =0.0;

  num budget = 0.0;

  num intercept = 0.0;

  num recordTrade(num quantity, num price) {
    budget -= quantity * price;
    quantityTraded+= quantity; //update counter
    assert(budget>=-1);
  }

  num quantityAtThisPrice(num price) {
    assert(price is double);
    assert(intercept is double);
    assert(budget is double);

    if(price > 0)
      return max(budget/price + intercept,0.0);
    else
      return double.INFINITY;
  }

  void reset() {
    quantityTraded = 0.0;
    if(!cumulative)
      budget = 0.0;
    num newBudget = computeBudget();
    if(newBudget.isFinite)
      budget += newBudget;
  }

  FixedBudget(this.computeBudget,[this.intercept=0.0]);

}


/**
 * basically there is a fixed pool of goods that can be bought/sold
 */
class FixedSupply implements ExogenousCurve
{

  num dailyQuantity = 100.0;


  FixedSupply(this.dailyQuantity);

  num quantityTraded =0.0;


  num recordTrade(num quantity, num price) {
    quantityTraded+= quantity; //update counter
    assert(dailyQuantity>=quantityTraded);
    return quantityTraded;
  }

  num quantityAtThisPrice(num price) {
    if(price > 0)
      return max(dailyQuantity-quantityTraded,0.0);
    else
      return 0.0;
  }

  void reset() {
    quantityTraded = 0.0;
  }


}