/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

import 'package:lancaster/view/lancaster_view.dart';
import 'package:angular/angular.dart';
import 'package:angular/application_factory.dart';

class SliderModule extends Module{
  SliderModule() {
    bind(SliderDemoGUI);
    bind(ControlBar);
    bind(PaperControlBar);
    bind(AugmentedSliderDemoGUI);
    bind(SliderWithChartsDemoGUI);
    bind(ZKSellerSimple);
    bind(ZKStockoutTimeSeriesChart);
    bind(SellerBeveridge);
  }
}

void main(){
  applicationFactory().addModule(new SliderModule()).run();

}