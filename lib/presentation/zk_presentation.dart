/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.presentation;



/**
 * presentation class for a zero knowledge trader/department
 */
class ZKPresentation extends Presentation<ZKEvent> {

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

    additionalObservers.forEach((name,dg)
                                =>additionalObservations.putIfAbsent(name,
                                                                         ()=>[])
                                .add(dg()));


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