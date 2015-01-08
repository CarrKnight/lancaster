/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.presentation;



/**
 * presentation class for a zero knowledge trader/department
 */
class ZKPresentation {

  /**
   * Useful only for plotting, keep track of where vertical lines should go
   */
  final Map<String, double> verticalLines = new HashMap();
  final Map<String, DataGatherer> verticalLineGatherers = new HashMap();

  /**
   * Useful only for plotting, keep track of where horizontal lines should go
   */
  final Map<String, double> horizontalLines= new HashMap();
  final Map<String, DataGatherer> horizontalLineGatherers= new HashMap();

  /**
   * Useful only for plotting, keep track of additional time serieses
   */
  final Map<String, List<double>> additionalObservations = new HashMap();
  final Map<String, DataGatherer> additionalObservers = new HashMap();

  /**
   * Useful only for plotting, keep track of additional parameters
   */
  final CurveRepository repository = new CurveRepository();


  /**
   * this boolean is useful to ignore events unless you have listeners
   */
  bool listenedTo = false;

  StreamController<ZKEvent> streamer = new StreamController();


  /**
   * the trader we all know and love
   */
  final ZeroKnowledgeTrader trader;


  ZKPresentation(this.trader);




  /**
   * start streaming prices and quantities to the view
   */

  start(Schedule schedule){
    schedule.scheduleRepeating(Phase.GUI,(schedule)=>_broadcastEndDay(schedule));
  }


  /**
   * stream only if it is listened to.
   */
  _broadcastEndDay(Schedule schedule){


    //fill curves
    horizontalLineGatherers.forEach((name,dg)=>horizontalLines[name]=dg());
    verticalLineGatherers.forEach((name,dg)=>verticalLines[name]=dg());
    additionalObservers.forEach((name,dg)
                                =>additionalObservations[name].add(dg()));


    //stream event
    if(streamer.hasListener)
      streamer.add(new ZKEvent(trader,this));

  }


  Stream<ZKEvent> get zkStream => streamer.stream;



}

/**
 * event to fire every-time the presentation is ready with new data
 */
class ZKEvent
{
  final ZeroKnowledgeTrader trader;

  final ZKPresentation presentation;

  ZKEvent(this.trader,this.presentation);


}