/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.model;

/**
 * an inventory with a bunch of traders and plants
 */
class Firm extends Object with Inventory{


  Map<String,ZeroKnowledgeTrader> salesDepartments;
  Map<String,ZeroKnowledgeTrader> purchaseDepartments;
  List<SISOPlant> plants;


  /**
   * this gets assigned when start is called
   */
  Schedule _schedule;
  List<toStart> todo = new List();



}


/**
 * additional functions to call when start(...) is called on the firm or
 * immediately if the firm has already started
 */
typedef void toStart(Firm f, Schedule s);