/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.presentation;



/**
 * presentation class for a zero knowledge trader/department. It actually
 * stores its stuff in additional columns of the zk data
 */
class ZKPresentation extends Presentation<ZKEvent> {



  /**
   * Useful only for plotting, keep track of additional parameters
   */
  final CurveRepository repository = new CurveRepository();


  /**
   * this boolean is useful to ignore events unless you have listeners
   */
  bool listenedTo = false;

  StreamController<ZKEvent> streamer = new StreamController.broadcast();


  /**
   * the trader we all know and love
   */
  final ZeroKnowledgeTrader trader;


  String get goodType => trader.goodType;

  ZKPresentation(this.trader);


  /**
   * add a function called by the agent's data at the end of the day. This is
   * useful if we want to store it later
   */
  addDailyObserver(String name, DataGatherer dg)
  {
    trader.data.addColumn(name,dg);
  }


  /**
   * start streaming prices and quantities to the view
   */

  start(Schedule schedule){
    schedule.scheduleRepeating(Phase.GUI,(schedule)=>_broadcastEndDay(schedule));
  }


  /**
   * redirects to the data object of the trader
   */
  Map<String, List<double>> get dailyObservations => trader.data.backingMap;

  /**
   * streams only if it is listened to.
   */
  _broadcastEndDay(Schedule schedule){


    //don't need to collect data, since everything should have been done by
    // the agent data object (we redirected all observers to there too)

    //stream event
    if(streamer.hasListener)
      streamer.add(new ZKEvent(trader,this,schedule.day));

  }


  Stream<ZKEvent> get stream => streamer.stream;



}

/**
 * event to fire every-time the presentation is ready with new data
 */
class ZKEvent extends PresentationEvent
{
  final ZeroKnowledgeTrader trader;

  final ZKPresentation presentation;

  final int day;

  ZKEvent(this.trader,this.presentation,this.day);


}