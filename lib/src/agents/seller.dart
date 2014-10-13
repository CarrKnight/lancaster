/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

import 'package:lancaster/src/tools/inventory.dart';

/**
 * this is an interface of somebody who has inventory and can be notified of sales (which is a pre-requisite to trade)
 */
abstract class Seller implements HasInventory
{

  /**
   * this is usually to record the price and sales. It doesn't really change inventory,
   * that's already been done when this is called
   */
  void notifyOfTrade(double quantity, double price);

}


/**
 * a simple inventory that records information about last closing price. This is useful only for testing, really
 */
class DummySeller implements Seller
{

  final Inventory _inventory = new Inventory();

  double lastClosingPrice = double.NAN;


  void notifyOfTrade(double quantity, double price) {
    lastClosingPrice = price;
  }

  earn(double amount) {
    _inventory.earn(amount);
  }

  spend(double amount) {
    _inventory.spend(amount);
  }

  receive(double amount) {
    _inventory.receive(amount);

  }

  remove(double amount) {
    _inventory.remove(amount);

  }

  hire(int people) {
    _inventory.hire(people);

  }

  fire(int people) {
    _inventory.fire(people);
  }

  get gas =>  _inventory.gas;


  get labor =>
    _inventory.labor;



  get money =>
    _inventory.money;



}