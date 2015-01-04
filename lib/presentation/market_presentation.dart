/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.presentation;


typedef  double DataGatherer();

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

  final Map<String,DataGatherer> additionalData;


  final Market _market;

  SimpleMarketPresentation(this._market,[this.additionalData=null]) {
    _marketStream = new StreamController.broadcast(
                                           onListen: (){listenedTo = true;},
                                           onCancel: (){listenedTo = false;});

  }

  factory SimpleMarketPresentation.seller(ExogenousSellerMarket market,
                                          double dailyFlow,
                                          DataGatherer equilibriumPrice)
  {
    SimpleMarketPresentation toReturn =
    new SimpleMarketPresentation(market,{"Equilibrium": equilibriumPrice});
    toReturn.curveRepository.addCurve(market.demand,"Demand");
    toReturn.curveRepository.addCurve(new FixedSupply(dailyFlow), "Supply");
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

    //create additional data, if needed
    Map<String,double> addendum=null;
    if(additionalData != null) {
      addendum = new HashMap();
      additionalData.forEach((name, gatherer) => addendum[name] = gatherer());
    }

    if(listenedTo)
      _marketStream.add(new MarketEvent( schedule.day,
                                        _market.averageClosingPrice,
                                        _market.quantityTraded,
                                         addendum));

  }


  Stream<TradeEvent> get tradeStream => _market.tradeStream;
  Stream<MarketEvent> get marketStream => _marketStream.stream;



}

class MarketEvent{

  final double price;

  final int day;

  final double quantity;

  final Map<String,double> additionalData;

  MarketEvent(this.day, this.price, this.quantity,
              [this.additionalData = null]);

}