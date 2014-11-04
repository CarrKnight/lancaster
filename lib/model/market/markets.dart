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


  void start(Schedule s){
    _tradeStreamer.start(s);
  }

  double get averageClosingPrice;

  double get quantitySold;

  String get goodType;

  /**
   * a stream narrating the trades that have occurred
   */
  Stream<TradeEvent> get tradeStream=>_tradeStreamer.stream;


}

abstract class AsksOrderBook{

  final Set<Trader> sellers = new LinkedHashSet();

  final List<_TradeQuote> _asks = new List();

  final QuoteStream _askStreamer = new QuoteStream();

  void startAsks(Schedule s){
    _askStreamer.start(s);
  }


  placeSaleQuote(Trader seller, double amount, double unitPrice) {
    assert(sellers.contains(seller));
    _asks.add(new _TradeQuote(seller,amount,unitPrice));
    //log it
    _askStreamer.log(seller,amount,unitPrice);

  }




  /**
   * a stream narrating the quotes that have been placed
   */
  Stream<QuoteEvent> get asksStream => _askStreamer.stream;



}

abstract class BidsOrderBook{

  final Set<Trader> buyers = new LinkedHashSet();

  final List<_TradeQuote> _bids = new List();

  placeBuyerQuote(Trader buyer,double amount,double unitPrice){
    assert(buyers.contains(buyer));
    _bids.add(new _TradeQuote(buyer,amount,unitPrice) );
  }

  bool registerBuyer(Trader buyer);
  /**
   * a stream narrating the quotes that have been placed
   */
  Stream<QuoteEvent> get bidStream;



}


/**
 * a market where the buying is "done" by a fixed linear demand while the sellers are normal agents
 */
class LinearDemandMarket extends Market with AsksOrderBook{


  final String goodType;






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





  LinearDemandMarket({num intercept : 100.0, num slope:-1.0,
                     String goodType : "gas" }):
  this.goodType = goodType
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
    super.start(s);
    startAsks(s);
    s.scheduleRepeating(Phase.DAWN,_resetMarket);
    s.scheduleRepeating(Phase.CLEAR_MARKETS,_clearMarket);
  }

  void _resetMarket(Schedule s){
    _asks.clear();
    _soldToday = 0.0;
    _moneyExchanged = 0.0;

  }

  void _clearMarket(Schedule s){
    //sort quotes (last will be the best since last is faster to remove, I think)
    _asks.shuffle(); //shuffle it to avoid first agent to always go first/last
    _asks.sort((q1,q2)=>(-q1.pricePerunit.compareTo(q2.pricePerunit)));

    //as long as there are quotes
    while(_asks.isNotEmpty){

      var best = _asks.last;
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
      _tradeStreamer.log(best.owner,null,amountTraded,price);

      //if we filled the quote
      if(amountTraded == best.amount) {
        var removed = _asks.removeLast();
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







  double get averageClosingPrice => _soldToday == 0 ? double.NAN :
  _moneyExchanged/_soldToday;

  double get quantitySold=> _soldToday;




}

class _TradeQuote
{

  double _amount;

  final double _pricePerUnit;

  final Trader _owner;

  _TradeQuote(this._owner, this._amount,this._pricePerUnit);


  Trader get owner => _owner;
  get pricePerunit=> _pricePerUnit;
  get amount=> _amount;

  set amount(double newAmount){
    _amount = newAmount;
    if(this.amount < 0)
      throw "A quote has negative amount!";
  }

}


//easy functions for trading

void sold(Trader seller, double amount, double price){

  seller.earn(price*amount);
  seller.remove(amount);
  seller.notifyOfTrade(amount,price);

}

void bought(Trader buyer, double amount, double price){

  buyer.spend(price*amount);
  buyer.receive(amount);


}

void tradeBetweenTwoAgents(Trader buyer, Trader seller, double amount,
                           double price ){
  sold(seller,amount,price);
  bought(buyer,amount,price);
}

/**
 * a loggable event: a trade occurred
 */
class TradeEvent{

  final Trader seller;

  final Trader buyer;

  final double amount;

  final double unitPrice;

  final int day;

  TradeEvent(this.seller, this.buyer, this.amount, this.unitPrice, this.day);


}

/**
 * a loggable event: a quote was placed
 */
class QuoteEvent{

  final Trader seller;

  final double amount;

  final double unitPrice;

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


class QuoteStream{

  bool listenedTo = false;

  bool started = false;

  Schedule _schedule;


  StreamController<QuoteEvent> _controller;

  QuoteStream() {
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

  void log(Trader trader,double amount, double unitPrice){
    if(started && listenedTo) //if you can log, do log
      _controller.add(new QuoteEvent(trader,amount,unitPrice,_schedule.day));
  }


  Stream<QuoteEvent> get stream=>  _controller.stream;

}


class TradeStream{

  bool listenedTo = false;

  bool started = false;

  Schedule _schedule;


  StreamController<TradeEvent> _controller;

  TradeStream() {
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

  void log(Trader seller,Trader buyer,double amount, double unitPrice){
    if(started && listenedTo) //if you can log, do log
      _controller.add(
          new TradeEvent(seller,buyer,amount,unitPrice,
          _schedule.day));
  }


  Stream<TradeEvent> get stream=>  _controller.stream;

}

/**
 * basically a bunch of streams of  market "events" that loggers and views can
 * listen to
 */
class StreamsForMarkets{

  /**
   * this boolean is useful to ignore events unless you have listeners
   */
  bool recordAsks = false;

  /**
   * this boolean is useful to ignore events unless you have listeners
   */
  bool recordTrades = false;

  /**
   * this boolean is useful to ignore events unless you have listeners
   */
  bool recordBids = false;

  /**
   * before start gets called nothing gets logged
   */
  bool started = false;

  /**
   * needed only to store days
   */
  Schedule _schedule;

  StreamController<TradeEvent> _trades;

  StreamController<QuoteEvent> _asks;

  StreamController<QuoteEvent> _bids;








}