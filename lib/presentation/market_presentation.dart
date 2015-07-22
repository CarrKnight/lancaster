/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.presentation;



/**
 * presentation class: creates series object and text logs for the view to show.
 * It needs a schedule
 */
class SimpleMarketPresentation extends Presentation<MarketEvent>{

  /**
   * this boolean is useful to ignore events unless you have listeners
   */
  bool listenedTo = false;



  /**
   * the broadcaster to turn market events into stream views can read
   */
  StreamController<MarketEvent> _marketStream;

  /**
   * functions called at the end of the day to fill time-series observations
   */
  final Map<String,DataGatherer> additionalDataGatherers;

  /**
   * a storage/log of all the market events. Useful for plots and such
   */
  final List<MarketEvent> marketEvents = new List();
  /**
   * Storage for everything observed. Views can plot this (the x, the day, is
   * just the i of the list)
   */
  final Map<String, List<double>> dailyObservations = new HashMap();

  final Market _market;

  SimpleMarketPresentation(this._market,[this.additionalDataGatherers=null]) {
    _marketStream = new StreamController.broadcast(
        onListen: (){listenedTo = true;},
        onCancel: (){listenedTo = false;});

  }

  factory SimpleMarketPresentation.seller(ExogenousSellerMarket market,
                                          num dailyFlow,
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


    //fill observation
    //price first
    List<double> column = dailyObservations.putIfAbsent("Price", ()=>[]);
    column.add(_market.averageClosingPrice);
    //call all the gatherers to fill the matrix
    if(additionalDataGatherers != null)
      additionalDataGatherers.forEach((name,value){
        column = dailyObservations.putIfAbsent(name,()=>[]);
        column.add(value());
      });

    //create the event
    MarketEvent event =new MarketEvent( schedule.day,
                                        _market.averageClosingPrice,
                                        _market.quantityTraded);
    //add it to the log
    marketEvents.add(event);

    //stream event
    if(listenedTo)
      _marketStream.add(event);

  }

  /**
   * "bonus" stream, useful as a log maybe. Not used so far
   */
  Stream<TradeEvent> get tradeStream => _market.tradeStream;
  Stream<MarketEvent> get stream => _marketStream.stream;



}


/**
 * adds a stream link to both bids and sales
 */
class GeographicalMarketPresentation extends SimpleMarketPresentation
{
  GeographicalMarket _market;

  /**
   * we need access to the model to generate and schedule more traders
   */
  final Model _model;

  final GeoBuyerGenerator buyerGenerator;

  GeographicalMarketPresentation(GeographicalMarket _market,this._model,
                                 this.buyerGenerator,
                                 [additionalDataGatherers=null]):
  super(_market,additionalDataGatherers){
    this._market = _market;

  }


  Random get random => _model.random;

  Map<Trader, Locator> get traders => _market.locators;

  /**
   * callable by the gui to move a trader to a new location. It will echo the movement in the stream.
   */
  void move(Trader trader, Location location)
  {
    _market.getLocator(trader).location = location;
    print(_market.getLocator(trader).location);
  }


  void createNewBuyer(Location location)
  {
    buyerGenerator.generateBuyer(_model.schedule,_model.random,_market,location);
  }


  /**
   * tells whether a trader is registered as a seller or not.It assumes that if it isn't,
   * it is registered as a buyer
   */
  bool isSeller(Trader trader)
  {
    bool contained = _market.sellers.contains(trader);
    //either or
    assert(_market.buyers.contains(trader) != contained);
    return contained;
  }

  Stream<QuoteEvent> get askStream =>  _market.asksStream;
  Stream<QuoteEvent> get bidStream =>  _market.bidStream;

  Stream<MovementEvent> get movementStream => _market.movementStream;

}


class MarketEvent extends PresentationEvent{

  final num price;

  final int day;

  final num quantity;

  MarketEvent(this.day, this.price, this.quantity);

}