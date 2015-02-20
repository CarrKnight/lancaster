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



  receive(String goodType, num amount)=>
  getSection(goodType).receive(amount);


  remove(String goodType, num amount)=>
  getSection(goodType).remove(amount);


  num hasHowMuch(String goodType)=>getSection(goodType).amount;

  /**
   * zeroes inflows and outflows
   */
  void resetCounters(){
    for(var section in inventory.values)
      section._resetCounters();

  }

  num inflow(String goodType)=> getSection(goodType)._inflow;
  num outflow(String goodType)=> getSection(goodType)._outflow;



}

abstract class HasInventory{


  num receive(String goodType, num amount);
  num remove(String goodType,num amount);

  num hasHowMuch(String goodType);

}



/**
 * A subset of the inventory only on one good and money. It should
 * be faster as it doesn't keep accessing the map.
 */
class InventoryCrossSection
{

  num _amount=0.0;

  num _inflow=0.0;
  num _outflow=0.0;

  final String goodType;

  InventoryCrossSection(String goodType) :
  this.goodType = goodType;

  receive(num amount){_amount+=amount; _inflow+=amount;}
  remove(num amount){_amount-=amount; _outflow+=amount;}

  num get amount =>_amount;
  num get inflow =>_inflow;
  num get outflow =>_outflow;


  /**
   * this zeroes inflows and outflows. It is usually called from the owning
   * inventory
   */
  _resetCounters(){ _inflow=0.0; _outflow =0.0;}

}

