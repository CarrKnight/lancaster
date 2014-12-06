/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.model;


/**
 * Useful to output the same number all the time. I use it mostly for PID
 * buyers to tell them what is the maximum number of goods to buy if they
 * misprice (1000).
 *
 * The name is a misnomer. You can change the value at will from outside,
 * fixed means that it doesn't adapt.
 */
class FixedValue implements AdaptiveStrategy
{

  double value;

  FixedValue([this.value=1000.0]);

  adapt(Trader t, Data data) {}



}

/**
 * Returns the current inventory of the trader.
 */
class AllOwned implements AdaptiveStrategy
{



  AllOwned._internal();

  static AllOwned instance = new AllOwned._internal();

  double inventory;

  adapt(Trader t, Data data) {
    inventory = t.good;
  }

  double get value=>inventory;

  factory AllOwned()=>instance;



}