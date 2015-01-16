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
  void set price(double value)
  {
    //whenever you set a new value also step!
    //this is a relatively silly way not to deal with mouse event listeners
    // for release
    presentation.price = value;

    presentation.step();

  }
  double get price=>presentation.price;

  bool get ready => customersAttracted.isFinite;

  bool get shortage=>ready && customersAttracted > 50;

  bool get equilibrium=> ready && customersAttracted == 50;

  bool get unsoldInventory=> ready && customersAttracted < 50;


  String get colorCustomers => customersAttracted == 50 ? "green_highlight" :
                               "red_highlight";


  ZKPresentation get agent => presentation.agent;
  double customersAttracted = double.NAN;
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


  void set price(double value)
  {
    //whenever you set a new value also step!
    //this is a relatively silly way not to deal with mouse event listeners
    // for release
  presentation.price = value;


  }
}