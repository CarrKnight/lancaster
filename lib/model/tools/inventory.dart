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
  final Map<String,InventoryGood> inventory = new HashMap();





  /**
   * get the inventory section for this good or create one if it doesn't exist.
   * Usable from the outside
   */
  InventoryGood getInventoryOfGood(String goodType){
    return inventory.putIfAbsent(goodType,()=>new InventoryGood());
  }



  receive(String goodType, double amount)=>
    getInventoryOfGood(goodType).amount+=amount;


  remove(String goodType, double amount)=>
    getInventoryOfGood(goodType).amount-=amount;


  double hasHowMuch(String goodType)=>getInventoryOfGood(goodType).amount;



}

abstract class HasInventory{


  double receive(String goodType, double amount);
  double remove(String goodType,double amount);

  double hasHowMuch(String goodType);

}


/**
 * Nothing more than a variable double to place within a map
 */
class InventoryGood
{
  double amount=0.0;
}

/**
 * any class that only has access to one good in the inventory + money
 */
abstract class OneGoodInventory{


  earn(double amount);
  spend(double amount);

  receive(double amount);
  remove(double amount);

  double get good;
  double get money;

  String get goodType;
}


/**
 * A subset of the inventory focusing only on one good and money. It should
 * be faster as it doesn't keep accessing the map.
 */
class InventoryCrossSection implements OneGoodInventory
{

  final InventoryGood _good;

  final InventoryGood _money;

  final String goodType;

  InventoryCrossSection(Inventory fullInventory, String goodType) :
    _good = fullInventory.getInventoryOfGood(goodType),
    _money = fullInventory.getInventoryOfGood("money"),
  this.goodType = goodType;

  earn(double amount){_money.amount+=amount;}
  spend(double amount){_money.amount-=amount;}

  receive(double amount){_good.amount+=amount;}
  remove(double amount){_good.amount-=amount;}

  double get good => _good.amount;
  double get money => _money.amount;
}
