/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.view;


/**
 * the root of a simple simulation using SimpleFirm scenario
 */


class SliderDemoBase
{
  SliderDemoPresentation presentation;


  @NgTwoWay('price')
  void set price(num value)
  {
    //whenever you set a new value also step!
    //this is a relatively silly way not to deal with mouse event listeners
    // for release
    presentation.price = value;

    presentation.step();

  }
  num get price=>presentation.price;

  bool get ready => customersAttracted.isFinite;

  bool get shortage=>ready && customersAttracted > 50;

  bool get equilibrium=> ready && customersAttracted == 50;

  bool get unsoldInventory=> ready && customersAttracted < 50;


  String get colorCustomers => customersAttracted == 50 ? "green_highlight" :
                               "red_highlight";


  ZKPresentation get agent => presentation.agent;
  num customersAttracted = double.NAN;
}

@Component(
    selector: 'slider-demo-gui',
    templateUrl: 'packages/lancaster/view/scenario/sliderdemo/sliderdemogui.html',
    cssUrl: 'packages/lancaster/view/scenario/sliderdemo/sliderdemogui.css')
class SliderDemoGUI extends SliderDemoBase{
  SliderDemoGUI()
  {

    ExogenousSellerScenario scenario = new ExogenousSellerScenario
    (initialPrice:1.0);
    this.presentation = new SliderDemoPresentation(
        new Model(new DateTime.now().millisecondsSinceEpoch,scenario),scenario);

    this.presentation.stream.listen((event)=>customersAttracted=event
    .customersAttracted);
  }
}

@Component(
    selector: 'slider-demo-pid-gui',
    templateUrl: 'packages/lancaster/view/scenario/sliderdemo/augmented_sliderdemogui.html',
    cssUrl: 'packages/lancaster/view/scenario/sliderdemo/sliderdemogui.css')
class AugmentedSliderDemoGUI extends SliderDemoBase{
  AugmentedSliderDemoGUI()
  {

    ExogenousSellerScenario scenario = new ExogenousSellerScenario.stockoutPID
    (initialPrice:1.0);
    this.presentation = new SliderDemoPresentation(
        new Model(new DateTime.now().millisecondsSinceEpoch,scenario),scenario);

    this.presentation.stream.listen((event)=>customersAttracted=event
    .customersAttracted);
  }


  void set price(num value)
  {
    //whenever you set a new value also step!
    //this is a relatively silly way not to deal with mouse event listeners
    // for release
  presentation.price = value;


  }
}


@Component(
    selector: 'slider-demo-charts-gui',
    templateUrl: 'packages/lancaster/view/scenario/sliderdemo/slider_with_charts.html',
    cssUrl: 'packages/lancaster/view/scenario/sliderdemo/sliderdemogui.css')
class SliderWithChartsDemoGUI extends SliderDemoBase{
  SliderWithChartsDemoGUI()
  {

    ExogenousSellerScenario scenario = new ExogenousSellerScenario.stockoutPID
    (initialPrice:1.0);
    this.presentation = new SliderDemoPresentation(
        new Model(new DateTime.now().millisecondsSinceEpoch,scenario),scenario);

    this.presentation.stream.listen((event)=>customersAttracted=event
    .customersAttracted);
  }


  void set price(num value)
  {
    //whenever you set a new value also step!
    //this is a relatively silly way not to deal with mouse event listeners
    // for release
    presentation.price = value;


  }
}

class FixedProductionBase
{
  MarshallianMicroPresentation presentation;

  ZKPresentation get hr => presentation.hr;
  ZKPresentation get sales => presentation.sales;


  FixedProductionBase() {
    OneMarketCompetition scenario = new OneMarketCompetition();
    presentation = new MarshallianMicroPresentation.fixedTarget(
        new Model(new DateTime.now().millisecondsSinceEpoch,scenario),
        scenario,20.0);


    //listen to the presentation to update prices
    presentation.hr.stream.listen((event)=>wage=event.trader.lastOfferedPrice);
    presentation.sales.stream.listen((event)=>price=event.trader
    .lastOfferedPrice);

  }


  bool get ready => price.isFinite;
  bool get correct => price == wage;
  String get equality => correct ? "=" : price > wage ? ">" : "<";
  String get cssClass => correct ? "green_highlight" : "red_highlight";

  num price = double.NAN;
  num wage = double.NAN;
  void set target(num value){presentation.hrTarget=value;}
  num get target => presentation.hrTarget;
  int get period => 100;
}

//
@Component(
    selector: 'simple-fixed-production',
    templateUrl: 'packages/lancaster/view/scenario/sliderdemo/fixed_production.html',
    cssUrl: 'packages/lancaster/view/scenario/sliderdemo/sliderdemogui.css')
class FixedProductionGUI extends FixedProductionBase
{


}
//
@Component(
    selector: 'simple-exogenous-production',
    templateUrl: 'packages/lancaster/view/scenario/sliderdemo/exogenous_production.html',
    cssUrl: 'packages/lancaster/view/scenario/sliderdemo/sliderdemogui.css')
class ExogenousProductionGUI extends FixedProductionBase
{


}

@Component(
    selector: 'final-demo',
    templateUrl: 'packages/lancaster/view/scenario/sliderdemo/fixed_production.html',
    cssUrl: 'packages/lancaster/view/scenario/sliderdemo/sliderdemogui.css')
class FinalDemoGUI
{
  MarshallianMicroPresentation presentation;


  ZKPresentation get hr => presentation.hr;
  ZKPresentation get sales => presentation.sales;

  FinalDemoGUI() {
    OneMarketCompetition scenario = new OneMarketCompetition();
    presentation = new MarshallianMicroPresentation(
        new Model(new DateTime.now().millisecondsSinceEpoch,scenario),
        scenario);
    //listen to the presentation to update prices
    presentation.hr.stream.listen((event)=>wage=event.trader.lastOfferedPrice);
    presentation.sales.stream.listen((event)=>price=event.trader
    .lastOfferedPrice);

  }


  bool get ready => price.isFinite;

  num price = double.NAN;
  num wage = double.NAN;
  int get period => 10;

}