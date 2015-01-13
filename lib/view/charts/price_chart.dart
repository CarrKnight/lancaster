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
 * plots interesting zk stuff
 */
@Component(
    selector: 'zk-priceplot',
    templateUrl: 'packages/lancaster/view/charts/plot.html',
    cssUrl: 'packages/lancaster/view/charts/plot.css'
    )
class ZKTimeSeriesChart extends BaseTimeSeriesChart implements ShadowRootAware {


  List<String> get selectedColumns=> ["offeredPrice","Target","Equilibrium"];
}


