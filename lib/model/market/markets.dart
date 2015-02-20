part of lancaster.model;

/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

/*

Unlike the good old generic java model where this come from, here I am mostly going to deal with one kind of market:
set quotes at the beginning of the day, clear them by mid-day and forget them all.
As such all the infrastructure to update/delete quotes is useless.
I am also going to change how some customers work. For fixed demand I used to have to instantiate many "customer agents" who always
 asked the same price every day. Here I am probably just going to have a curve that does that.
 */

/**
 * interface for markets that allow sales quotes
 */


abstract class Market{


  final TradeStream _tradeStreamer = new TradeStream();

  Data data;


  void start(Schedule s){
    _tradeStreamer.start(s);
    data = new Data.MarketData(this);
    data.start(s);
  }

  num get averageClosingPrice;

  num get quantityTraded;

  /**
   * basically count the inflow of the registered sellers (a proxy for total
   * production)
   */
  num get sellersInflow;

  /**
   * basically count the inflow of the registered sellers (a proxy for total
   * consumption)
   */
  num get buyersOutflow;

  /**
   * what is the good exchanged here?
   */
  String get goodType;

  /**
   * what is that good exchanged for
   */
  String get moneyType;

  /**
   * a stream narrating the trades that have occurred
   */
  Stream<TradeEvent> get tradeStream=>_tradeStreamer.stream;


}

abstract class AsksOrderBook{

  final Set<Trader> sellers = new HashSet();

  final List<_TradeQuote> _asks = new List();

  final QuoteStream _askStreamer = new QuoteStream();

  void startAsks(Schedule s){
    _askStreamer.start(s);
  }


  placeSaleQuote(Trader seller, num amount, num unitPrice) {
    assert(sellers.contains(seller));
    _asks.add(new _TradeQuote(seller,amount,unitPrice));
    //log it
    _askStreamer.log(seller,amount,unitPrice);

  }


  /**
   * after this is called the last element in the list is the best
   */
  void sortAsks(){
    //sort quotes (last will be the best since last is faster to remove, I think)
    _asks.shuffle(); //shuffle it to avoid first agent to always go first/last
    _asks.sort((q1,q2)=>(-q1.pricePerunit.compareTo(q2.pricePerunit)));
  }

  /**
   * a stream narrating the quotes that have been placed
   */
  Stream<QuoteEvent> get asksStream => _askStreamer.stream;



}

abstract class SellerMarket extends Market with AsksOrderBook{}

abstract class BuyerMarket extends Market with BidsOrderBook{}


class BidsOrderBook{

  final Set<Trader> buyers = new LinkedHashSet();

  final List<_TradeQuote> _bids = new List();

  final QuoteStream _bidStreamer = new QuoteStream();

  void startBids(Schedule s){
    _bidStreamer.start(s);
  }

  void sortAsks(){
    //sort quotes (last will be the best since last is faster to remove, I think)
    _bids.shuffle(); //shuffle it to avoid first agent to always go first/last
    _bids.sort((q1,q2)=>(q1.pricePerunit.compareTo(q2.pricePerunit)));
  }

  placeBuyerQuote(Trader buyer,num amount,num unitPrice){
    assert(buyers.contains(buyer));
    _bids.add(new _TradeQuote(buyer,amount,unitPrice) );

    _bidStreamer.log(buyer,amount,unitPrice);
  }

  /**
   * a stream narrating the quotes that have been placed
   */
  Stream<QuoteEvent> get bidStream=>_bidStreamer.stream;

  /**
   * after this is called the last element in the list is the best
   */
  void sortBids(){
    //sort quotes (last will be the best since last is faster to remove, I think)
    _bids.shuffle(); //shuffle it to avoid first agent to always go first/last
    _bids.sort((q1,q2)=>(q1.pricePerunit.compareTo(q2.pricePerunit)));
  }



}


/**
 * a market where the buying is "done" by a fixed demand curve while the
 * sellers are normal agents
 */
class ExogenousSellerMarket extends SellerMarket with OneSideMarketClearer{


  final String goodType;
  final String moneyType;



  ExogenousCurve demand;

  static const String DB_ADDRESS = "default.market.ExogenousSellerMarket";


  num _moneyExchanged = 0.0;

  ExogenousSellerMarket.linear( {num intercept : 100.0,
                                num slope:-1.0,
                                String goodType : "gas",
                                String moneyType: "money"}):
  this(new LinearCurve(intercept,slope),goodType:goodType,moneyType:moneyType);


  ExogenousSellerMarket.LinearFromDB(
      ParameterDatabase db,
      String containerPath
      )
  :this.linear(intercept : db.getAsNumber("$containerPath.intercept","$DB_ADDRESS.intercept"),
               slope : db.getAsNumber("$containerPath.slope","$DB_ADDRESS.slope"),
               goodType : db.getAsString("$containerPath.goodType","$DB_ADDRESS.goodType"),
               moneyType : db.getAsString("$containerPath.moneyType","$DB_ADDRESS.moneyType"));

  /**
   * demand = w*L of the previous day
   */
  static FixedBudget linkedToWageDemand(Model model, String laborType, num intercept) {
    var budgetDemand = () => model.markets[laborType].data.getLatestObservation
                             ("price") * model.markets[laborType].data.getLatestObservation
                             ("quantity") ;

    FixedBudget fixedBudget = new FixedBudget(budgetDemand,intercept);
    return fixedBudget;
  }


  factory ExogenousSellerMarket.linkedToWagesFromModelFromDB(
      Model model,
      String laborType,
      ParameterDatabase db,
      String containerPath
      )
  => new ExogenousSellerMarket.linkedToWagesFromModel(model,
                                     db.getAsString("$containerPath.laborType","$DB_ADDRESS.laborType"),
                                     intercept : db.getAsNumber("$containerPath.intercept","$DB_ADDRESS.intercept"),
                                     moneyType : db.getAsString("$containerPath.moneyType","$DB_ADDRESS.moneyType"));


  factory ExogenousSellerMarket.linkedToWagesFromModel( Model model,
                                                        String laborType,
                                                        {
                                                        String goodType : "gas",
                                                        //additional budget or penalty
                                                        num intercept : 0.0,
                                                        String moneyType: "money"})
  {
    var fixedBudget = linkedToWageDemand(model, laborType, intercept);
    return new ExogenousSellerMarket(fixedBudget,
                                     goodType:goodType, moneyType:moneyType);

  }

  /**
   * demand = w*L of the previous day
   */
  factory ExogenousSellerMarket.linkedToWagesFromData( Data laborData,
                                                       {
                                                       String goodType : "gas",
                                                       String moneyType: "money"})
  {
    var budgetDemand = ()=>laborData.getLatestObservation
                           ("price") *laborData.getLatestObservation
                           ("quantity") ;

    return new ExogenousSellerMarket(new FixedBudget(budgetDemand),
                                     goodType:goodType, moneyType:moneyType);

  }


  ExogenousSellerMarket(ExogenousCurve this.demand, {String goodType : "gas"
  , String moneyType: "money"}):
  this.goodType = goodType, this.moneyType = moneyType;

  void start(Schedule s){
    super.start(s);
    startAsks(s);
    s.scheduleRepeating(Phase.DAWN,_resetMarket);
    s.scheduleRepeating(Phase.CLEAR_MARKETS,_clearMarket);
  }

  void _resetMarket(Schedule s){
    _asks.clear();
    demand.reset();
    _moneyExchanged = 0.0;

  }

  void _clearMarket(Schedule s){
    sortAsks();
    _moneyExchanged = clearMarket(demand,_asks,_tradeStreamer,true);
  }


  num get averageClosingPrice => demand.quantityTraded == 0 ? double.NAN :
                                    _moneyExchanged/demand.quantityTraded;

  num get quantityTraded=> demand.quantityTraded;

  /**
   * since buyers aren't really agentized assume everything traded is consumed
   */
  num get buyersOutflow => quantityTraded;

  /**
   * sum up all inflow of registered sellers
   */
  num get sellersInflow =>
  sellers.fold(0.0,(prev,e)=>prev+e.currentInflow);



}

/**
 * a market where the buying is "done" by a fixed demand curve while the
 * sellers are normal agents
 */
class ExogenousBuyerMarket extends BuyerMarket with OneSideMarketClearer{


  final String goodType;

  final String moneyType;


  final ExogenousCurve supply;

  static const String DB_ADDRESS = "default.money.ExogenousBuyerMarket";


  num _moneyExchanged = 0.0;

  ExogenousBuyerMarket.linear( {num intercept : 0.0,
                               num slope:1.0,
                               String goodType : "gas",
                               String moneyType: "money" }):
  this(new LinearCurve(intercept,slope),goodType:goodType,moneyType:moneyType);


  ExogenousBuyerMarket.LinearFromDB(
      ParameterDatabase db,
      String containerPath
      )
  :this.linear(intercept : db.getAsNumber("$containerPath.intercept","$DB_ADDRESS.intercept"),
               slope : db.getAsNumber("$containerPath.slope","$DB_ADDRESS.slope"),
               goodType : db.getAsString("$containerPath.goodType","$DB_ADDRESS.goodType"),
               moneyType : db.getAsString("$containerPath.moneyType","$DB_ADDRESS.moneyType"));


  ExogenousBuyerMarket.InfinitelyElasticFromDB( ParameterDatabase db,
                                                String containerPath)
  :this.infinitelyElastic(db.getAsNumber("$containerPath.inelasticPrice","$DB_ADDRESS.inelasticPrice"),
                          goodType : db.getAsString("$containerPath.goodType","$DB_ADDRESS.goodType"),
                          moneyType : db.getAsString("$containerPath.moneyType","$DB_ADDRESS.moneyType"));


  ExogenousBuyerMarket.infinitelyElastic(num price, {
  String goodType : "gas",
  String moneyType: "money" }):
  this(new InfinitelyElasticAsk(price),goodType:goodType,moneyType:moneyType,
       pricePolicy: FIXED_PRICE(price));


  ExogenousBuyerMarket(ExogenousCurve this.supply, {String goodType : "gas",
  String moneyType: "money", pricePolicy : null}):
  this.goodType = goodType,
  this.moneyType = moneyType
  {
    if(pricePolicy != null)
      this.pricePolicy = pricePolicy;
  }

  void start(Schedule s){
    super.start(s);
    startBids(s);
    s.scheduleRepeating(Phase.DAWN,_resetMarket);
    s.scheduleRepeating(Phase.CLEAR_MARKETS,_clearMarket);
  }

  void _resetMarket(Schedule s){
    _bids.clear();
    supply.reset();
    _moneyExchanged = 0.0;

  }

  void _clearMarket(Schedule s){
    sortAsks();
    _moneyExchanged = clearMarket(supply,_bids,_tradeStreamer,false);
  }


  num get averageClosingPrice => supply.quantityTraded == 0 ? double.NAN :
                                    _moneyExchanged/supply.quantityTraded;

  num get quantityTraded=> supply.quantityTraded;


  /**
   * Buyer outflow
   */
  num get buyersOutflow =>   buyers.fold(0.0,(prev,b)=>prev+b.currentOutflow);


  /**
   * since buyers aren't really agentized assume everything on the market has
   * just been produced
   */
  num get sellersInflow=> quantityTraded;




}


class _TradeQuote
{

  num _amount;

  final num _pricePerUnit;

  final Trader _owner;

  _TradeQuote(this._owner, this._amount,this._pricePerUnit);


  Trader get owner => _owner;
  get pricePerunit=> _pricePerUnit;
  get amount=> _amount;

  set amount(num newAmount){
    _amount = newAmount;
    if(this.amount < 0)
      throw "A quote has negative amount!";
  }

}


//easy functions for trading

void sold(Trader seller, num amount, num price, [num stockouts = 0.0]){

  seller.earn(price*amount);
  seller.remove(amount);
  seller.notifyOfTrade(amount,price,stockouts);

}

void bought(Trader buyer, num amount, num price, [num stockouts = 0.0]){

  buyer.spend(price*amount);
  buyer.receive(amount);
  buyer.notifyOfTrade(amount,price,stockouts);


}

void tradeBetweenTwoAgents(Trader buyer, Trader seller, num amount,
                           num price ){
  sold(seller,amount,price);
  bought(buyer,amount,price);
}

/**
 * a loggable event: a trade occurred
 */
class TradeEvent{

  final Trader seller;

  final Trader buyer;

  final num amount;

  final num unitPrice;

  final int day;

  TradeEvent(this.seller, this.buyer, this.amount, this.unitPrice, this.day);


}

/**
 * a loggable event: a quote was placed
 */
class QuoteEvent{

  final Trader seller;

  final num amount;

  final num unitPrice;

  final int day;

  QuoteEvent(this.seller, this.amount, this.unitPrice,
             this.day);


}

class _AsksStream{

  /**
   * this boolean is useful to ignore events unless you have listeners
   */
  bool recordAsks = false;

  /**
   * before start gets called nothing gets logged
   */
  bool started = false;


  StreamController<QuoteEvent> _asks;

  StreamsForMarkets() {
    _asks = new StreamController.broadcast(
        onListen: ()=>recordAsks=true,
        onCancel: ()=>recordAsks=false
        );
  }

}


abstract class TimestampedStreamBase<T>{
  bool listenedTo = false;

  bool started = false;

  Schedule _schedule;


  StreamController<T> _controller;

  TimestampedStreamBase() {
    _controller = new StreamController.broadcast(
        onListen: ()=>listenedTo=true,
        onCancel: ()=>listenedTo=false
        );
  }

  void start(Schedule s){
    assert(!started);
    started = true;
    this._schedule = s;
  }


  Stream<T> get stream=>  _controller.stream;

}


class QuoteStream extends TimestampedStreamBase<QuoteEvent>{



  void log(Trader trader,num amount, num unitPrice){
    if(started && listenedTo) //if you can log, do log
      _controller.add(new QuoteEvent(trader,amount,unitPrice,_schedule.day));
  }


}


class TradeStream extends TimestampedStreamBase<TradeEvent>{

  void log(Trader seller,Trader buyer,num amount, num unitPrice){
    if(started && listenedTo) //if you can log, do log
      _controller.add(
          new TradeEvent(seller,buyer,amount,unitPrice,
                         _schedule.day));
  }




}

/**
 * recursive clears a market where there is an orderbook against an exogenous
 * curve
 */
class OneSideMarketClearer{

  PricePolicy pricePolicy = QUOTED_PRICE;

  /**
   * expects [book] to be already sorted where last is best.
   * Returns the total amount of money that was exchanged
   */
  num clearMarket(ExogenousCurve curve, List<_TradeQuote> book,
                     TradeStream tradeStreamer,bool bookIsForSales) {

    num moneyExchanged = 0.0;
//as long as there are quotes
    while (book.isNotEmpty) {

      var best = book.last;
      var price = pricePolicy(best._pricePerUnit);
      var maxDemandForThisPrice = curve.quantityAtThisPrice(best._pricePerUnit); //demand

      // minus what has been already sold today!

      if (maxDemandForThisPrice <= 0) //if the best price gets no sales, we are done
        break;

      num amountTraded = min(maxDemandForThisPrice, best.amount);
      assert(amountTraded.isFinite);
      num stockouts = max(maxDemandForThisPrice - best.amount,0.0);
      //trade!
      if(bookIsForSales)
        sold(best.owner, amountTraded, best.pricePerunit,stockouts);
      else
        bought(best.owner,amountTraded,best.pricePerunit,stockouts);
      curve.recordTrade(amountTraded,best.pricePerunit);
      moneyExchanged += amountTraded * best.pricePerunit;
      //log
      tradeStreamer.log(best.owner, null, amountTraded, price);

      //if we filled the quote
      if (amountTraded == best.amount) {
        var removed = book.removeLast();
        assert(removed == best);
      }
      else {
        assert(amountTraded < best.amount); //you must have traded less than the quote, it can never be more!
        best.amount -= amountTraded; //change the quote, even though it's pointless
        break;
        //bye bye
      }
    }
    return moneyExchanged;
  }

}

/**
 * what is the prevailing price in a one side market given [bestQuotePrice]
 */
typedef num PricePolicy(num bestQuotePrice);

/**
 * standard price policy, trading price is the quote price.
 */
final PricePolicy QUOTED_PRICE = (x)=>x;

/**
 * closing price is always fixed price. It doesn't check that x is below
 * price, that's the clearer responsbility, not the price policy. This is
 * useful for infinitely elastic markets and the price-taking it entails.
 */
PricePolicy FIXED_PRICE(num price)
{
  return (x)=>price;
}
