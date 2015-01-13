/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.presentation;

//holds just basic interfaces

/**
 * basically just a tag for any object a presentation streams
 */
abstract class PresentationEvent{}


abstract class Presentation<E extends PresentationEvent>
{

  /**
   * must have a stream to listen to!
   */
  Stream<E> get stream;

  /**
   * holds a list of observations, useful to plot directly if the chart
   * doesn't need to make any further adjustment
   */
  Map<String, List<double>> get dailyObservations;


}