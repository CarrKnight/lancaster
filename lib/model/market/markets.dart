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

  double get averageClosingPrice;

  double get quantitySold;

  /**
   * a stream narrating the trades that have occurred
   */
  Stream<TradeEvent> get tradeStream;


}

abstract class MarketForSellers extends Market{


  placeSaleQuote(Seller seller,double amount,double unitPrice);

  bool registerSeller(Seller seller);

  /**
   * a stream narrating the quotes that have been placed
   */
  Stream<SalesQuoteEvent> get saleQuotesStream;


  Iterable<Seller> get registeredSellers;

}

abstract class MarketForBuyers{

  placeBuyerQuote(HasInventory buyer,double amount,double unitPrice);

}


/**
 * a market where the buying is "done" by a fixed linear demand while the sellers are normal agents
 */
class LinearDemandMarket implements MarketForSellers{

  Set<Seller> _sellers = new LinkedHashSet();


  final List<_SaleQuote> _quotes = new List();



  double _intercept;

  double _slope;

  double _soldToday = 0.0;

  double _moneyExchanged = 0.0;

  /**
   * reset market means clearing up the quote and reset the already sold counter
   */
  Step _resetMarketStep;

  /**
   * trade--> market clears
   */
  Step _marketClearStep;


  final StreamsForSellerMarkets _streams = new StreamsForSellerMarkets();



  LinearDemandMarket({num intercept : 100.0, num slope:-1.0})
  {
    assert(slope <=0);
    this._intercept = intercept.toDouble();
    this._slope = slope.toDouble();



    _resetMarketStep= (schedule){
      _resetMarket(schedule);
    };

    _marketClearStep = (schedule){
      _clearMarket(schedule);
    };


  }

  void start(Schedule s){
    _streams.start(s);
    s.scheduleRepeating(Phase.DAWN,_resetMarket);
    s.scheduleRepeating(Phase.CLEAR_MARKETS,_clearMarket);
  }

  void _resetMarket(Schedule s){
    _quotes.clear();
    _soldToday = 0.0;
    _moneyExchanged = 0.0;

  }

  void _clearMarket(Schedule s){
    //sort quotes (last will be the best since last is faster to remove, I think)
    _quotes.shuffle(); //shuffle it to avoid first agent to always go first/last
    _quotes.sort((q1,q2)=>(-q1.pricePerunit.compareTo(q2.pricePerunit)));

    //as long as there are quotes
    while(_quotes.isNotEmpty){

      var best = _quotes.last;
      var price = best._pricePerUnit;
      var maxDemandForThisPrice = (intercept + slope * price)-_soldToday; //demand minus what has been already sold today!

      if(maxDemandForThisPrice <= 0) //if the best price gets no sales, we are done
        break;

      var amountTraded = min(maxDemandForThisPrice,best.amount);
      //trade!
      sold(best.owner,amountTraded,best.pricePerunit);
      _soldToday +=amountTraded;
      _moneyExchanged +=amountTraded * best.pricePerunit;
      //log
      _streams.logTrade(best.owner,null,amountTraded,price);

      //if we filled the quote
      if(amountTraded == best.amount) {
        var removed = _quotes.removeLast();
        assert(removed == best);
      }
      else{
        assert(amountTraded < best.amount); //you must have traded less than the quote, it can never be more!
        best.amount -= amountTraded; //change the quote, even though it's pointless
        break; //bye bye
      }
    }
  }

  double get slope => _slope;

  set slope(double value){
    _slope = value;
    assert(_slope <=0);
  }

  double get intercept => _intercept;

  set intercept(double value){
    _intercept = value;
    assert(intercept>=0);

  }

  placeSaleQuote(Seller seller, double amount, double unitPrice) {
    assert(_sellers.contains(seller));
    _quotes.add(new _SaleQuote(seller,amount,unitPrice));
    //log it
    _streams.logQuote(seller,amount,unitPrice);

  }

  Stream<SalesQuoteEvent> get saleQuotesStream => _streams.saleQuotesStream;
  Stream<TradeEvent> get tradeStream => _streams.tradeStream;


  bool registerSeller(Seller seller)=>
  _sellers.add(seller);


  Iterable<Seller> get registeredSellers => _sellers;

  double get averageClosingPrice => _soldToday == 0 ? double.NAN :
  _moneyExchanged/_soldToday;

  double get quantitySold=> _soldToday;

  
  

}

class _SaleQuote
{

  double _amount;

  final double _pricePerUnit;

  final Seller _owner;

  _SaleQuote(this._owner, this._amount,this._pricePerUnit);


  Seller get owner => _owner;
  get pricePerunit=> _pricePerUnit;
  get amount=> _amount;

  set amount(double newAmount){
    _amount = newAmount;
    if(this.amount < 0)
      throw "A quote has negative amount!";
  }

}

abstract class MarketForSellersListener
{

  void tradeEvent(){}


}


//easy functions for trading

void sold(Seller seller, double amount, double price){

  seller.earn(price*amount);
  seller.remove(amount);
  seller.notifyOfTrade(amount,price);

}

void bought(HasInventory buyer, double amount, double price){

  buyer.spend(price*amount);
  buyer.receive(amount);


}

void tradeBetweenTwoAgents(HasInventory buyer, Seller seller, double amount, double price ){
  sold(seller,amount,price);
  bought(buyer,amount,price);
}

/**
 * a loggable event: a trade occurred
 */
class TradeEvent{

  final Seller seller;

  final HasInventory buyer;

  final double amount;

  final double unitPrice;

  final int day;

  TradeEvent(this.seller, this.buyer, this.amount, this.unitPrice, this.day);


}

/**
 * a loggable event: a quote was placed
 */
class SalesQuoteEvent{

  final Seller seller;

  final double amount;

  final double unitPrice;

  final int day;

  SalesQuoteEvent(this.seller, this.amount, this.unitPrice,
                  this.day);


}

/**
 * basically a bunch of streams of  market "events" that loggers and views can
 * listen to
 */
class StreamsForSellerMarkets{

  /**
   * this boolean is useful to ignore events unless you have listeners
   */
  bool recordQuotes = false;

  /**
   * this boolean is useful to ignore events unless you have listeners
   */
  bool recordTrades = false;

  /**
   * before start gets called nothing gets logged
   */
  bool started = false;

  /**
   * needed only to store days
   */
  Schedule _schedule;

  StreamController<TradeEvent> _trades;

  StreamController<SalesQuoteEvent> _quotes;



  /**
   * grab the schedule s to log days
   */

  StreamsForSellerMarkets() {
    _trades = new StreamController.broadcast(
        onListen: ()=>recordTrades=true,
        onCancel: ()=>recordTrades=false
    );
    _quotes = new StreamController.broadcast(
        onListen: ()=>recordQuotes=true,
        onCancel: ()=>recordQuotes=false
    );
  }

  void start(Schedule s){
    assert(!started);
    started = true;
    this._schedule = s;
  }


  void logTrade(Seller seller,HasInventory buyer,double amount,
                double unitPrice){
    if(started && recordTrades) //if you can log, do log
      _trades.add(new TradeEvent(seller,buyer,amount,unitPrice,_schedule.day));


  }

  void logQuote(Seller seller,double amount, double unitPrice ){
    if(started && recordQuotes) //if you can log, do log
      _quotes.add(new SalesQuoteEvent(seller,amount,unitPrice,_schedule.day));

  }

  Stream<TradeEvent> get tradeStream => _trades.stream;
  Stream<SalesQuoteEvent> get saleQuotesStream => _quotes.stream;




}