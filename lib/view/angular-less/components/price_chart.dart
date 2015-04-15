/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.view2;


class TimeSeriesChart extends BaseTimeSeriesChart {

  TimeSeriesChart(Presentation p, HTML.DivElement e)
  :
  super(p,e);


  List<String> get selectedColumns=> null;
}


/**
 * plots useful price stuff for zk. Target and Equilibrium are given by the
 * scenario (sometimes)
 */

class ZKTimeSeriesChart extends BaseTimeSeriesChart {



  ZKTimeSeriesChart(Presentation p, HTML.DivElement e)
  :
  super(p,e);

  List<String> get selectedColumns=> ["offeredPrice",
  "Target","Equilibrium"];
}




/**
 * plots useful price stuff for zk. Q Equilibrium might be given by the
 * scenario/presentation
 * */
class ZKQuantityTimeSeriesChart extends BaseTimeSeriesChart {

  ZKQuantityTimeSeriesChart(Presentation p, HTML.DivElement e)
  :
  super(p,e);

  List<String> get selectedColumns=> ["inflow","outflow","Q Equilibrium"];
}

/**
 *  Only plots "inflow" (which is standard) and "customers" which needs to be
 *  set by the presentation (probably outflow+customers)
 * */

class ZKStockoutTimeSeriesChart extends BaseTimeSeriesChart
{


  ZKStockoutTimeSeriesChart(Presentation p, HTML.DivElement e, {double resizeScale : 1.0})
  :
  super(p, e,resizeScale : resizeScale);

  List<String> get selectedColumns => ["inflow", "customers"];
}