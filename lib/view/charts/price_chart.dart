/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.view;


/**
 * plots everything
 */
@Component(
    selector: 'priceplot',
    templateUrl: 'packages/lancaster/view/charts/plot.html',
    cssUrl: 'packages/lancaster/view/charts/plot.css'
    )
class TimeSeriesChart extends BaseTimeSeriesChart implements ShadowRootAware {


  List<String> get selectedColumns=> null;
}


/**
 * plots useful price stuff for zk. Target and Equilibrium are given by the
 * scenario (sometimes)
 */
@Component(
    selector: 'zk-priceplot',
    templateUrl: 'packages/lancaster/view/charts/plot.html',
    cssUrl: 'packages/lancaster/view/charts/plot.css'
    )
class ZKTimeSeriesChart extends BaseTimeSeriesChart implements ShadowRootAware {


  List<String> get selectedColumns=> ["offeredPrice","Target","Equilibrium"];
}




/**
 * plots useful price stuff for zk. Q Equilibrium might be given by the
 * scenario/presentation
 * */
@Component(
    selector: 'zk-quantity',
    templateUrl: 'packages/lancaster/view/charts/plot.html',
    cssUrl: 'packages/lancaster/view/charts/plot.css'
    )
class ZKQuantityTimeSeriesChart extends BaseTimeSeriesChart implements
ShadowRootAware {


  List<String> get selectedColumns=> ["inflow","outflow","Q Equilibrium"];
}