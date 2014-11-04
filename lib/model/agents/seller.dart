/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.model;



/**
 * this is an interface of somebody who has inventory and can be told when
 * trades happen (which is a pre-requisite to trade)
 */
abstract class Trader implements OneGoodInventory
{

  /**
   * this is usually to record the price and sales. It doesn't really change inventory,
   * that's already been done when this is called
   */
  void notifyOfTrade(double quantity, double price);

  /**
   * the last offered price
   */
  double get  lastOfferedPrice;

  /**
   * the last closing price
   */
  double get  lastClosingPrice;

  /**
   * the outflow since the beginning of the day
   */
  double get  currentOutflow;

  /**
   * the inflow since the beginning of the day
   */
  double get  currentInflow;
}


/**
 * a simple inventory that records information about last closing price. This is useful only for testing, really
 */
class DummySeller implements Trader
{

  final InventoryCrossSection _inventory;

  double _lastClosingPrice = double.NAN;


  DummySeller([String goodType= "gas"]):
    _inventory=new InventoryCrossSection(new Inventory(),goodType);

  DummySeller.fromMarket(Market market):
    this(market.goodType);


  void notifyOfTrade(double quantity, double price) {
    _lastClosingPrice = price;
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


  get good =>  _inventory.good;


  get money =>
  _inventory.money;

  double get lastClosingPrice => _lastClosingPrice;

  double get lastOfferedPrice => double.NAN;

  double get currentOutflow => double.NAN;

  double get currentInflow => double.NAN;

  String get goodType =>_inventory.goodType;


}


/**
 * a simple trader with fixed daily inflow and a pid pricer
 */
class FixedInflowSeller implements Trader
{
  final InventoryCrossSection _inventory;

  Data _data;

  double dailyInflow;

  PricingStrategy pricing;

  /**
   * market to trade in
   */
  final AsksOrderBook market;

  //stats:
  double _lastClosingPrice = double.NAN;

  double _currentOutflow = 0.0;

  double _currentInflow =0.0;

  double _lastOfferedPrice = double.NAN;

  double depreciationRate;


  /**
   * at dawn reset the counters, depreciates old inventory and receive new stuff .
   */
  Step dawn;

  /**
   * update PID prices and then use them to place an order
   */
  Step placeQuote;

  FixedInflowSeller(this.dailyInflow,AsksOrderBook market,this.pricing,
                    [double this.depreciationRate=0.0]):
  this.market = market,
  _inventory = new InventoryCrossSection(new Inventory(),market.goodType)
  {
    dawn = (s){
      //depreciate
      assert(depreciationRate >=0 && depreciationRate <=1);
      remove(good * depreciationRate);
      //daily inflow
      receive(dailyInflow);
      _currentInflow = dailyInflow;
      //reset the rest
      _currentOutflow = 0.0;
      _lastOfferedPrice = 0.0;
    };

    placeQuote = (s){
      pricing.updatePrice(_data);
      if(good > 0) //if you have anything to sell
        market.placeSaleQuote(this,good,pricing.price);
      _lastOfferedPrice = pricing.price;

    };

    _data = new Data.SellerDefault(this);
  }

  /**
   * a simple PID seller
   */
  FixedInflowSeller.flowsTarget(double dailyInflow,AsksOrderBook market,
                                {double depreciationRate:0.0,double initialPrice:100.0}):
  this(dailyInflow,market,new PIDPricing.DefaultSeller(initialPrice:initialPrice),depreciationRate);


  FixedInflowSeller.bufferInventory(double dailyInflow,AsksOrderBook market,
                                {double depreciationRate:0.0,
                                double initialPrice:100.0,
                                double optimalInventory:100.0,
                                double criticalInventory:10.0}):
  this
  (
      dailyInflow,market,
      new BufferInventoryPricing.simpleSeller(
          optimalInventory:optimalInventory,
          criticalInventory:criticalInventory,
          initialPrice:initialPrice)
  );


  void start(Schedule schedule){
    //register yourself
    market.sellers.add(this);
    //start the data as well
    _data.start(schedule);




    schedule.scheduleRepeating(Phase.DAWN,dawn);
    schedule.scheduleRepeating(Phase.PLACE_QUOTES,placeQuote);



  }

  /**
   * store the trade results
   */
  void notifyOfTrade(double quantity, double price) {
    _currentOutflow+=quantity;
    _lastClosingPrice=price;
  }


  earn(double amount)=>_inventory.earn(amount);


  spend(double amount)=>_inventory.spend(amount);



  receive(double amount)=> _inventory.receive(amount);



  remove(double amount) =>_inventory.remove(amount);



  get good =>_inventory.good;
  get money => _inventory.money;

  double get lastOfferedPrice=>_lastOfferedPrice;

  double get lastClosingPrice=>_lastClosingPrice;

  double get currentOutflow =>_currentOutflow;

  double get currentInflow=> _currentInflow;

  String get goodType => _inventory.goodType;


}