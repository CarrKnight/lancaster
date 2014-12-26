/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.presentation;



/**
 * presentation class: creates series object and text logs for the view to show.
 * It needs a schedule
 */
class SimpleMarketPresentation{

  /**
   * this boolean is useful to ignore events unless you have listeners
   */
  bool listenedTo = false;



  /**
   * the broadcaster to turn market events into stream views can read
   */
  StreamController<MarketEvent> _marketStream;



  final Market _market;

  SimpleMarketPresentation(this._market) {
    _marketStream = new StreamController.broadcast(
                                           onListen: (){listenedTo = true;},
                                           onCancel: (){listenedTo = false;});

  }

  factory SimpleMarketPresentation.seller(ExogenousSellerMarket market)
  {
    SimpleMarketPresentation toReturn = new SimpleMarketPresentation(market);
    toReturn.curveRepository.addCurve(market.demand,"Demand");
    return toReturn;

  }

  factory SimpleMarketPresentation.buyer(ExogenousBuyerMarket market)
  {
    SimpleMarketPresentation toReturn = new SimpleMarketPresentation(market);
    toReturn.curveRepository.addCurve(market.supply,"supply");
    return toReturn;

  }

  final CurveRepository curveRepository = new CurveRepository();


  /**
   * start streaming prices and quantities to the view
   */
  start(Schedule schedule){
    schedule.scheduleRepeating(Phase.GUI,(schedule)=>_broadcastMarketStatus(schedule));
  }


  /**
   * stream only if it is listened to.
   */
  _broadcastMarketStatus(Schedule schedule){
    if(listenedTo)
      _marketStream.add(new MarketEvent( schedule.day,
                                        _market.averageClosingPrice,
                                        _market.quantityTraded));

  }


  Stream<TradeEvent> get tradeStream => _market.tradeStream;
  Stream<MarketEvent> get marketStream => _marketStream.stream;



}

class MarketEvent{

  final double price;

  final int day;

  final double quantity;

  MarketEvent(this.day, this.price, this.quantity);


}