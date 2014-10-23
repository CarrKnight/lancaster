/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
library agents.seller;

import 'package:lancaster/model/tools/inventory.dart';
import 'package:lancaster/model/market/markets.dart';
import 'package:lancaster/model/engine/schedule.dart';
import 'package:lancaster/model/agents/pricing.dart';
import 'package:lancaster/model/tools/agent_data.dart';

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
class DummySeller implements Seller
{

  final Inventory _inventory = new Inventory();

  double _lastClosingPrice = double.NAN;


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

  double get lastClosingPrice => _lastClosingPrice;

  double get lastOfferedPrice => double.NAN;

  double get currentOutflow => double.NAN;

  double get currentInflow => double.NAN;


}


/**
 * a simple seller with fixed daily inflow and a pid pricer
 */
class FixedInflowSeller implements Seller
{
  final Inventory _inventory = new Inventory();

  AgentData _data;

  double dailyInflow;

  PricingStrategy pricing;

  /**
   * market to trade in
   */
  final MarketForSellers market;


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

  FixedInflowSeller(this.dailyInflow,this.market,this.pricing,
                    [double this.depreciationRate=0.0])
  {
    dawn = (s){
      //depreciate
      assert(depreciationRate >=0 && depreciationRate <=1);
      remove(gas * depreciationRate);
      //daily inflow
      receive(dailyInflow);
      _currentInflow = dailyInflow;
      //reset the rest
      _currentOutflow = 0.0;
      _lastOfferedPrice = 0.0;
    };

    placeQuote = (s){
      pricing.updatePrice(_data);
      if(gas > 0) //if you have anything to sell
        market.placeSaleQuote(this,gas,pricing.price);
      _lastOfferedPrice = pricing.price;

    };

    _data = new AgentData.SellerDefault(this);
  }

  /**
   * a simple PID seller
   */
  FixedInflowSeller.flowsTarget(double dailyInflow,MarketForSellers market,
                                {double depreciationRate:0.0,double initialPrice:100.0}):
  this(dailyInflow,market,new PIDPricing.DefaultSeller(initialPrice:initialPrice),depreciationRate);


  FixedInflowSeller.bufferInventory(double dailyInflow,MarketForSellers market,
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
    market.registerSeller(this);
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
  hire(int people)=>_inventory.hire(people);
  fire(int people)=>_inventory.fire(people);



  get gas =>_inventory.gas;
  get labor=>_inventory.labor;
  get money => _inventory.money;

  double get lastOfferedPrice=>_lastOfferedPrice;

  double get lastClosingPrice=>_lastClosingPrice;

  double get currentOutflow =>_currentOutflow;

  double get currentInflow=> _currentInflow;


}