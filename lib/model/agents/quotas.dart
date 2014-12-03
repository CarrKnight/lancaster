/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.model;


/**
 * The other side of pricing strategy, basically how much should the size of
 * quotes placed (in terms of max amount bought or sold).
 */
abstract class QuotaStrategy
{

  /**
   * to call by the user, probably every day.
   */
  updateQuoteSize(Trader t, Data data);

  /**
   * the max quantity to buy/sell when placing a quote
   */
  double get quoteSize;

}


/**
 * always same max quantity to trade. Useful for buyers that use price rather
 * than quotas to manipulate inflow
 */
class FixedQuota implements QuotaStrategy
{

  double maxQuoteSize;

  FixedQuota([this.maxQuoteSize=1000.0]);

  updateQuoteSize(Trader t, Data data) {}

  double get quoteSize=>maxQuoteSize;


}

/**
 * quote size is just goods owned.
 */
class AllOwned implements QuotaStrategy
{



  AllOwned._internal();

  static AllOwned instance = new AllOwned._internal();

  double inventory;

  updateQuoteSize(Trader t, Data data) {
    inventory = t.good;
  }

  double get quoteSize=>inventory;

  factory AllOwned()=>instance;



}