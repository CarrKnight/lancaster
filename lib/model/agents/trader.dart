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
  double lastOfferedPrice;

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
class DummyTrader implements Trader
{

  final InventoryCrossSection _inventory;

  double _lastClosingPrice = double.NAN;


  DummyTrader([String goodType= "gas"]):
  _inventory=new InventoryCrossSection(new Inventory(),goodType);

  DummyTrader.fromMarket(Market market):
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
  double set lastOfferedPrice(double d) => double.NAN;

  double get currentOutflow => double.NAN;

  double get currentInflow => double.NAN;

  String get goodType =>_inventory.goodType;


}


class ZeroKnowledgeTrader implements Trader
{
  final CountedCrossSection _inventory;

  Data _data;

  double dailyInflow;

  PricingStrategy pricing;

  TradingStrategy tradingStrategy;

  /**
   * market to trade in
   */
  final Market market;

  //stats:
  double _lastClosingPrice = double.NAN;

  double _currentOutflow = 0.0;

  double _currentInflow =0.0;

  double lastOfferedPrice = double.NAN;

  final List<DawnEvent> dawnEvents = new List();

  ZeroKnowledgeTrader(Market market,this.pricing,this.tradingStrategy,
                      Inventory totalInventory):
  _inventory = new CountedCrossSection(totalInventory, market.goodType),
  this.market = market{
    _data = new Data.SellerDefault(this);
  }



  void dawn(Schedule s)
  {
    _inventory.resetCount();
    for(DawnEvent e in dawnEvents)
      e(this);

  }

  /**
   * store the trade results
   */
  void notifyOfTrade(double quantity, double price) {
    _lastClosingPrice=price;
  }


  void trade(Schedule s)
  {
    tradingStrategy.step(this,market,_data,pricing);
  }

  /**
   * start data and strategies and schedule yourself
   */
  void start(Schedule schedule)
  {
    //start the datal
    _data.start(schedule);
    //register yourself
    tradingStrategy.start(schedule,this,market,_data,pricing);

    schedule.scheduleRepeating(Phase.DAWN,dawn);
    schedule.scheduleRepeating(Phase.PLACE_QUOTES,trade);

  }

  earn(double amount) =>  _inventory.earn(amount);


  spend(double amount) => _inventory.spend(amount);


  receive(double amount) =>_inventory.receive(amount);


  remove(double amount) =>_inventory.remove(amount);


  String get goodType  => _inventory.goodType;


  double get money => _inventory.money;


  double get good => _inventory.good;

  double get lastClosingPrice=>_lastClosingPrice;

  double get currentOutflow =>_inventory.outflow;

  double get currentInflow=> _inventory.inflow;

  /**
   * seller or sales-department targeting inflow=outflow
   */
  factory ZeroKnowledgeTrader.PIDSeller(SellerMarket market,
                                        {double initialPrice:100.0,
                                        Inventory totalInventory : null})
  {
    //if no total inventory given, this is an independent trader
    if(totalInventory == null)
      totalInventory = new Inventory();

    ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader(market,
    new PIDPricing.DefaultSeller(initialPrice:initialPrice),
    new SimpleSellerTrading(), totalInventory);

    return seller;
  }

  factory ZeroKnowledgeTrader.PIDBuyer(BuyerMarket market,
                                       {double flowTarget:10.0,
                                       double initialPrice:0.0,
                                       double p: PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                                       double i: PIDController.DEFAULT_INTEGRAL_PARAMETER,
                                       double d: PIDController.DEFAULT_DERIVATIVE_PARAMETER,
                                       Inventory totalInventory : null})
  {
    //if no total inventory given, this is an independent trader
    if(totalInventory == null)
      totalInventory = new Inventory();
    ZeroKnowledgeTrader buyer = new ZeroKnowledgeTrader(market,
    new PIDPricing.FixedInflowBuyer(flowTarget:flowTarget,
    initialPrice:initialPrice,p:p,i:i,d:d), new SimpleBuyerTrading(),
    totalInventory);

    return buyer;
  }

  /**
   * seller or sales-department targeting inflow=outflow with buffer inventory
   */
  factory ZeroKnowledgeTrader.PIDBufferSeller(SellerMarket market,
                                              {double depreciationRate:0.0,
                                              double initialPrice:100.0,
                                              double optimalInventory:100.0,
                                              double criticalInventory:10.0,
                                              double p:
                                              PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                                              double i:
                                              PIDController.DEFAULT_INTEGRAL_PARAMETER,
                                              double d:
                                              PIDController.DEFAULT_DERIVATIVE_PARAMETER,
                                              Inventory totalInventory:null})
  {
    //if no total inventory given, this is an independent trader
    if(totalInventory == null)
      totalInventory = new Inventory();

    ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader(market,
    new BufferInventoryPricing.simpleSeller(optimalInventory:optimalInventory,
    criticalInventory:criticalInventory,initialPrice:initialPrice,p:p,d:d,i:i),
    new SimpleSellerTrading(), totalInventory);

    return seller;
  }

//utility for factories
  static addDailyInflowAndDepreciation(ZeroKnowledgeTrader seller,
                                       double dailyInflow, double depreciationRate) {
    seller.dawnEvents.add(FixedInflowEvent(dailyInflow));
    if (depreciationRate > 0.0) {
      assert(depreciationRate <= 1.0);
      seller.dawnEvents.add(DepreciationEvent(depreciationRate));
    }
  }

  /**
   * PIDSeller with exogenous fixed inflow
   */
  factory ZeroKnowledgeTrader.PIDSellerFixedInflow(double dailyInflow,
                                                  SellerMarket market,
                                                  {double depreciationRate:0.0,
                                                  double initialPrice:100.0,
                                                  Inventory totalInventory : null})
  {
    ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader.PIDSeller(market,
    initialPrice:initialPrice,totalInventory:totalInventory);
    //add events
    addDailyInflowAndDepreciation(seller, dailyInflow, depreciationRate);
    return seller;
  }
  /**
   * PIDSeller with exogenous fixed inflow
   */
  factory ZeroKnowledgeTrader.PIDBufferSellerFixedInflow(double dailyInflow,
                                                  SellerMarket market,
                                                  {double depreciationRate:0.0,
                                                  double initialPrice:100.0,
                                                  double optimalInventory:100.0,
                                                  double criticalInventory:10.0,
                                                  double p:
                                                  PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                                                  double i:
                                                  PIDController.DEFAULT_INTEGRAL_PARAMETER,
                                                  double d:
                                                  PIDController.DEFAULT_DERIVATIVE_PARAMETER,
                                                  Inventory totalInventory : null})
  {
    ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader.PIDBufferSeller(market,
    initialPrice:initialPrice,totalInventory:totalInventory,
    optimalInventory:optimalInventory, criticalInventory:criticalInventory,
    d:d,i:i,p:p);
    //add events
    addDailyInflowAndDepreciation(seller, dailyInflow, depreciationRate);
    return seller;
  }



}




/**
 * trading strategy is whatever mechanism the trader needs to actually place
 * quotes in the market.
 * It's the user responsibility to call step(...) at trade. The strategy may
 * schedule more stuff after start(...) is called.
 * The generic is there if this strategy only works for a subset of markets
 * (geographicals or for buyers or whatever)
 */
abstract class TradingStrategy<T extends Market>{

  /**
   * mostly this exists to register the trader as buyer/seller/whatever in
   * the market. There is no need to schedule yourself to step,
   * that is the user responsibility.
   */
  void start(Schedule s, Trader trader, T market, Data data,
             PricingStrategy strategy);

  /**
   * [[strategy]] ought to be updated within this step
   */
  void step(Trader trader, T market, Data data, PricingStrategy pricing);
}

/**
 * standard zero-knowledge seller. Updates the price,
 * puts everything on sale all the time.
 */
class SimpleSellerTrading extends TradingStrategy<SellerMarket>
{

  /**
   * register trader as seller on the market. Nothing more
   */
  void start(Schedule s, Trader trader, SellerMarket market, Data data,
             PricingStrategy strategy) {
    market.sellers.add(trader);

  }

  void step(Trader trader, SellerMarket market, Data data,
            PricingStrategy pricing) {
    pricing.updatePrice(data);
    if(trader.good > 0) //if you have anything to sell
      market.placeSaleQuote(trader,trader.good,pricing.price);
    trader.lastOfferedPrice = pricing.price;
  }


}


/**
 * standard zero-knowledge buyer. Updates the price,
 * buys [maxOrder] every day
 */
class SimpleBuyerTrading extends TradingStrategy<BuyerMarket>
{

  double maxOrder = 1000.0;

  /**
   * register trader as seller on the market. Nothing more
   */
  void start(Schedule s, Trader trader, BuyerMarket market, Data data,
             PricingStrategy strategy) {
    market.buyers.add(trader);

  }

  void step(Trader trader, BuyerMarket market, Data data,
            PricingStrategy pricing) {
    pricing.updatePrice(data);
    market.placeBuyerQuote(trader,maxOrder,pricing.price);
    trader.lastOfferedPrice = pricing.price;
  }


}

/**
 * any additional thing to happen to a trader at dawn (fixed inflows,
 * outflows, cash gains, stuff like that)
 */
typedef void DawnEvent(Trader trader);

DawnEvent FixedInflowEvent(double inflow)=>(Trader trader)=>
trader.receive(inflow);

DawnEvent DepreciationEvent(double depreciationRate)=>(Trader trader)=>
trader.remove(depreciationRate*trader.good);
