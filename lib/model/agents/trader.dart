/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.model;



/**
 * this is an interface of somebody who has inventory and can be told when
 * trades happen (which is a pre-requisite to trade)
 */
abstract class Trader
{

  /**
   * this is usually to record the price and sales. It doesn't really change inventory,
   * that's already been done when this is called
   */
  void notifyOfTrade(double quantity, double price, double stockouts);

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

  /**
   * How many "stockouts" (customers we could have traded with at current
   * prices) we have seen today. Not every market gives out this information
   */
  double get  stockouts;

  /**
   * the maximum the trader is willing to trade. Willing doesn't mean able,
   * this is an additional constraint due to strategy rather than means. (for
   * example a seller that could, given the price, sell 100 units a day but
   * throttles it down to 25 sales a day by imposing a quota of 25).
   */
  double get quota;

  double predictPrice(double expectedChangeInQuantity);

  void earn(double moneyAmount);

  void receive(double goodAmount);

  void remove(double goodAmount);

  void spend(double moneyAmount);

  get good;

  Data get data;

}


/**
 * a simple inventory that records information about last closing price. This is useful only for testing, really
 */
class DummyTrader implements Trader
{


  InventoryCrossSection _inventory;
  InventoryCrossSection _money;

  double _lastClosingPrice = double.NAN;

  double lastOfferedPrice = double.NAN;

  double stockouts = double.NAN;


  DummyTrader([String goodType= "gas"])
  {
    var totalInventory = new Inventory(); //its own inventory
    _inventory=(totalInventory).getSection(goodType);
    _money=totalInventory.getSection("money");
  }

  DummyTrader.fromMarket(Market market):
  this(market.goodType);


  void notifyOfTrade(double quantity, double price, double stockouts) {
    _lastClosingPrice = price;
    this.stockouts = stockouts;
  }

  earn(double amount)=>_money.receive(amount);


  spend(double amount)=> _money.remove(amount);


  receive(double amount)=>_inventory.receive(amount);



  remove(double amount)=>_inventory.remove(amount);


  double get quota => double.MAX_FINITE;

  get good =>  _inventory.amount;

  get data=>null;

  get money =>_money.amount;

  double get lastClosingPrice => _lastClosingPrice;

  double get currentOutflow => double.NAN;

  double get currentInflow => double.NAN;

  String get goodType =>_inventory.goodType;

  double predictPrice(double expectedChangeInQuantity)=> _lastClosingPrice;



}

/**
 * can be buyer or seller of a specific good. Can be an independent trader or
 * a department for a firm (if given a reference to the firm's inventory).
 */
class ZeroKnowledgeTrader implements Trader
{
  final InventoryCrossSection _inventory;
  final InventoryCrossSection _money;

  Data _data;

  double dailyInflow;

  /**
   * how it prices its goods
   */
  AdaptiveStrategy pricing;

  /**
   * how much it is willing to buy/sell?
   */
  AdaptiveStrategy quoting;

  /**
   * how it trades
   */
  TradingStrategy tradingStrategy;

  /**
   * strictly speaking the trader doesn't need a predictor. But in many cases
   * there is one associated to it and it makes sense for it to be here.
   */
  PricePredictor predictor = new LastPricePredictor();

  /**
   * market to trade in
   */
  final Market market;

  //stats:
  double _lastClosingPrice = double.NAN;

  double _stockouts =0.0;

  double lastOfferedPrice = double.NAN;

  final List<DawnEvent> dawnEvents = new List();

  ZeroKnowledgeTrader(Market market,this.pricing,this.quoting,
                      this.tradingStrategy,
                      Inventory totalInventory):
  _inventory = totalInventory.getSection(market.goodType),
  _money  = totalInventory.getSection(market.moneyType),
  this.market = market
  {
    _data = new Data.TraderData(this);
  }



  void dawn(Schedule s)
  {
    _stockouts = 0.0; //reset stockouts counter
    for(DawnEvent e in dawnEvents)
      e(this);

  }

  /**
   * store the trade results
   */
  void notifyOfTrade(double quantity, double price,double stockouts) {
    _lastClosingPrice=price;
    _stockouts += stockouts;
  }


  void trade(Schedule s)
  {
    tradingStrategy.step(this,market,_data,pricing,quoting);
  }

  /**
   * start data and strategies and schedule yourself
   */
  void start(Schedule schedule)
  {
    //start the datal
    _data.start(schedule);
    //register yourself
    tradingStrategy.start(schedule,this,market,_data, pricing, quoting);
    //strategies start
    predictor.start(this,schedule,data);

    schedule.scheduleRepeating(Phase.DAWN,dawn);
    schedule.scheduleRepeating(Phase.PLACE_QUOTES,trade);

  }

  double get predictedSlope=>predictPrice(1.0)-predictPrice(0.0);


  double predictPrice(double expectedChangeInQuantity) => predictor
  .predictPrice(this,expectedChangeInQuantity);


  double get quota => quoting.value;

  earn(double amount)=>_money.receive(amount);


  spend(double amount)=> _money.remove(amount);


  receive(double amount)=>_inventory.receive(amount);


  remove(double amount)=>_inventory.remove(amount);



  String get goodType  => _inventory.goodType;

  Data get data =>_data;


  get good =>  _inventory.amount;

  get money =>_money.amount;

  double get lastClosingPrice=>_lastClosingPrice;

  double get currentOutflow =>_inventory.outflow;

  double get currentInflow=> _inventory.inflow;

  double get stockouts => _stockouts;

  /**
   * seller or sales-department targeting inflow=outflow+stockouts
   */
  factory ZeroKnowledgeTrader.PIDSeller(SellerMarket market,
                                        {double initialPrice:100.0,
                                        Inventory givenInventory : null})
  {
    //if no total inventory given, this is an independent trader
    Inventory inventory = givenInventory;
    if(givenInventory == null)
      inventory = new Inventory();

    ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader(market,
    new PIDAdaptive.DefaultSeller(initialPrice:initialPrice),
    new AllOwned(),
    new SimpleSellerTrading(), inventory);

    //independent trader needs to reset its own counters
    if(givenInventory==null)
      seller.dawnEvents.add(ResetInventories(inventory));
    return seller;
  }

  factory ZeroKnowledgeTrader.PIDBuyer(BuyerMarket market,
                                       {double flowTarget:10.0,
                                       double initialPrice:0.0,
                                       double p: PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                                       double i: PIDController.DEFAULT_INTEGRAL_PARAMETER,
                                       double d: PIDController.DEFAULT_DERIVATIVE_PARAMETER,
                                       Inventory givenInventory : null})
  {
    //if no total inventory given, this is an independent trader
    Inventory inventory = givenInventory;
    if(givenInventory == null)
      inventory = new Inventory();

    ZeroKnowledgeTrader buyer = new ZeroKnowledgeTrader(market,
    new PIDAdaptive.FixedInflowBuyer(flowTarget:flowTarget,
    initialPrice:initialPrice,p:p,i:i,d:d),
    new FixedValue(),
    new SimpleBuyerTrading(),inventory);

    //independent trader needs to reset its own counters
    if(givenInventory==null)
      buyer.dawnEvents.add(ResetInventories(inventory));

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
                                              Inventory givenInventory:null})
  {
    Inventory inventory = givenInventory;
    if(givenInventory == null)
      inventory = new Inventory();

    ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader(market,
    new BufferInventoryAdaptive.simpleSeller(optimalInventory:optimalInventory,
    criticalInventory:criticalInventory,initialPrice:initialPrice,p:p,d:d,i:i),
   new AllOwned(),
    new SimpleSellerTrading(), inventory);

    //independent trader needs to reset its own counters
    if(givenInventory==null)
      seller.dawnEvents.add(ResetInventories(inventory));

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
                                                   Inventory givenInventory:null})
  {
    ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader.PIDSeller(market,
    initialPrice:initialPrice,givenInventory:givenInventory);
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
                                                         Inventory givenInventory : null})
  {
    ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader.PIDBufferSeller(market,
    initialPrice:initialPrice,givenInventory:givenInventory,
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
             AdaptiveStrategy pricing, AdaptiveStrategy quota);

  /**
   * [[strategy]] ought to be updated within this step
   */
  void step(Trader trader, T market, Data data,AdaptiveStrategy pricing,
            AdaptiveStrategy quota);
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
             AdaptiveStrategy pricing, AdaptiveStrategy quota) {
    assert(!market.sellers.contains(trader));
    market.sellers.add(trader);
    assert(market.sellers.contains(trader));

  }

  void step(Trader trader, SellerMarket market, Data data,
            AdaptiveStrategy pricing, AdaptiveStrategy quota) {
    pricing.adapt(trader,data);
    quota.adapt(trader,data);
    double quoteSize = quota.value;
    trader.lastOfferedPrice = pricing.value;
    if(quoteSize> 0) //if you have anything to sell
      market.placeSaleQuote(trader,quoteSize,trader.lastOfferedPrice);
  }


}


/**
 * standard zero-knowledge buyer. Updates the price,
 * buys [maxOrder] every day
 */
class SimpleBuyerTrading extends TradingStrategy<BuyerMarket>
{


  /**
   * register trader as seller on the market. Nothing more
   */
  void start(Schedule s, Trader trader, BuyerMarket market, Data data,
             AdaptiveStrategy pricing, AdaptiveStrategy quota) {
    market.buyers.add(trader);

  }

  void step(Trader trader, BuyerMarket market, Data data,
            AdaptiveStrategy pricing, AdaptiveStrategy quota) {
    pricing.adapt(trader,data);
    quota.adapt(trader,data);
    double quoteSize = quota.value;
    if(quoteSize > 0)
      market.placeBuyerQuote(trader,quota.value,pricing.value);
    trader.lastOfferedPrice = pricing.value;
  }


}


/**
 * any additional thing to happen to a trader at dawn (fixed inflows,
 * outflows, cash gains, stuff like that)
 */
typedef void DawnEvent(ZeroKnowledgeTrader trader);

DawnEvent FixedInflowEvent(double inflow)=>(ZeroKnowledgeTrader trader)=>
trader.receive(inflow);

DawnEvent DepreciationEvent(double depreciationRate)=>(ZeroKnowledgeTrader trader)=>
trader.remove(depreciationRate*trader.good);

/**
 * reset inventories at dawn. Useful for independent traders.
 */
DawnEvent ResetInventories(Inventory inventory)=>(ZeroKnowledgeTrader trader)=>
inventory.resetCounters();


DawnEvent BurnInventories()=>(ZeroKnowledgeTrader trader){
  trader._inventory.remove(trader.good);
  trader._inventory._resetCounters();
};