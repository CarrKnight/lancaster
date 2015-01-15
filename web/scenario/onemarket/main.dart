/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

import 'package:lancaster/view/lancaster_view.dart';
import 'package:angular/angular.dart';
import 'package:angular/application_factory.dart';

class OneMarketModule extends Module{
  OneMarketModule() {
    bind(MarshallianMicroGUI);
    bind(ControlBar);
    bind(BuyerBeveridge);
    bind(SellerBeveridge);
    bind(TimeSeriesChart);
    bind(ZKTimeSeriesChart);
    bind(ZKQuantityTimeSeriesChart);
    bind(ZKBuyer);
    bind(ZKSeller);
    bind(Tooltip);
  }
}

void main(){
  applicationFactory().addModule(new OneMarketModule()).run();

}