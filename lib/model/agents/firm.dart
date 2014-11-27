/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.model;

/**
 * an inventory with a bunch of traders and plants
 */
class Firm extends Object with Inventory{


  final Map<String,ZeroKnowledgeTrader> salesDepartments = new HashMap();
  final Map<String,ZeroKnowledgeTrader> purchasesDepartments = new HashMap();
  List<SISOPlant> plants;


  /**
   * this gets assigned when start is called
   */
  Schedule _schedule;
  List<toStart> todo = new List();


  start(Schedule s)
  {
    assert(_schedule==null);
    _schedule = s;
    //start all the startable
    for(toStart t in todo)
    {
      t(this,s);
    }
    todo.clear();
  }

  /**
   * add to the map and auto-schedules to start when the firm starts
   */
  void addSalesDepartment(ZeroKnowledgeTrader sales)
  {
    /**
     * store in map
     */
    assert(!salesDepartments.containsKey(sales.goodType));
    salesDepartments[sales.goodType]=sales;
    assert(salesDepartments.containsKey(sales.goodType));

    //prepare to start
    startWhenPossible((f,s)=>sales.start(s));

  }

  /**
   * add to the map and auto-schedules to start when the firm starts
   */
  void addPurchasesDepartment(ZeroKnowledgeTrader purchases)
  {
    /**
     * store in map
     */
    assert(!purchasesDepartments.containsKey(purchases.goodType));
    purchasesDepartments[purchases.goodType]=purchases;
    assert(purchasesDepartments.containsKey(purchases.goodType));

    //prepare to start
    startWhenPossible((f,s)=>purchases.start(s));

  }


  /**
   * give a function that is called immediately if the firm has started or at
   * start() otherwise
   */
  void startWhenPossible(toStart startable)
  {
    //if we have been started already
    if(_schedule !=null)
      startable(this,_schedule);
      //otherwise it add it to the list of things to start
    else
      todo.add(startable);
  }


}


/**
 * additional functions to call when start(...) is called on the firm or
 * immediately if the firm has already started
 */
typedef void toStart(Firm f, Schedule s);