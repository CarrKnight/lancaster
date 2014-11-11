/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.model;

/**
 * A hashmap of "inventorySection" which is just a variable double. Users
 * that only deal with a few goods are encouraged to grab the inventory
 * section and work directly with it.
 */
class Inventory implements HasInventory{

  /**
   * the inventory is a
   */
  final Map<String,InventoryCrossSection> inventory = new HashMap();

  /**
   * get the inventory section for this good or create one if it doesn't exist.
   * Useful if you need to focus on one good specifically
   */
  InventoryCrossSection getSection(String goodType){
    return inventory.putIfAbsent(goodType,()=>new InventoryCrossSection(goodType));
  }



  receive(String goodType, double amount)=>
  getSection(goodType).receive(amount);


  remove(String goodType, double amount)=>
  getSection(goodType).remove(amount);


  double hasHowMuch(String goodType)=>getSection(goodType).amount;

  /**
   * schedule itself to call reset counters every dawn
   */
  void autoresetCounters(Schedule s){
    s.scheduleRepeating(Phase.DAWN,(s)=>resetCounters());
  }

  /**
   * zeroes inflows and outflows
   */
  void resetCounters(){
    for(var section in inventory.values)
      section._resetCounters();

  }



}

abstract class HasInventory{


  double receive(String goodType, double amount);
  double remove(String goodType,double amount);

  double hasHowMuch(String goodType);

}



/**
 * A subset of the inventory only on one good and money. It should
 * be faster as it doesn't keep accessing the map.
 */
class InventoryCrossSection
{

  double _amount=0.0;

  double _inflow=0.0;
  double _outflow=0.0;

  final String goodType;

  InventoryCrossSection(String goodType) :
  this.goodType = goodType;

  receive(double amount){_amount+=amount; _inflow+=amount;}
  remove(double amount){_amount-=amount; _outflow+=amount;}

  double get amount =>_amount;
  double get inflow =>_inflow;
  double get outflow =>_outflow;

  /**
   * this zeroes inflows and outflows. It is usually called from the owning
   * inventory
   */
  _resetCounters(){ _inflow=0.0; _outflow =0.0;}

}

