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


  StreamController<MarketEvent> _marketStream;

  final Market _market;

  SimpleMarketPresentation(this._market) {
    _marketStream = new StreamController(
                                           onListen: (){listenedTo = true;},
                                           onCancel: (){listenedTo = false;});

  }


  /**
   * start streaming prices and quantities to the view
   */
  start(Schedule schedule){
    schedule.scheduleRepeating(Phase.GUI,(schedule)=>_broadcastMarketStatus());
  }


  /**
   * stream only if it is listened to
   */
  _broadcastMarketStatus(){
    if(listenedTo)
      _marketStream.add(new MarketEvent(_market.averageClosingPrice,
                                        _market.quantitySold));
  }


  Stream<TradeEvent> get tradeStream => _market.tradeStream;
  Stream<MarketEvent> get marketStream => _marketStream.stream;

}

class MarketEvent{

  final double price;

  final double quantity;

  MarketEvent(this.price, this.quantity);


}