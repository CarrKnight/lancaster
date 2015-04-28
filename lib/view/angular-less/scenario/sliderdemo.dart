/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.view2;

/**
 * The good old slider-demo, this time without any angular component.
 */
class SliderDemoBase
{

  SliderDemoPresentation presentation;

  /**
   * HTML objects
   */
  //the root
  HTML.Element _root;
  //try to set the correct the price!
  HTML.SpanElement _instruction;

  //the quantity counter
  HTML.LIElement _quantity;
  HTML.LIElement _explanation;
  //bullet points
  HTML.UListElement _list;

  Slider _slider;

  //price is a computed property (really just a delegation from presentation)
  void set price(num value)
  {
    //whenever you set a new value also step!
    //this is a relatively silly way not to deal with mouse event listeners
    // for release
    presentation.price = value;
  }


  _buildSlider(HTML.Element root ) {

    _root = root;


    HTML.DivElement container = new HTML.DivElement();
    _root.append(container);

    //tell people to do stuff
    _instruction = new HTML.SpanElement();
    _instruction.text = "Try to set the \"correct\" cheese price";
    container.append(_instruction);

    _list = new HTML.UListElement();
    //this is fixed
    _list.append(new HTML.LIElement()
                   ..text = "You had 50 kilos of cheese to sell");
    //initially that's all there is
    container.append(_list);

    HTML.DivElement sliderContainer = new HTML.DivElement();
    _slider = new Slider(sliderContainer,"Price", (double newValue)=>price=newValue);
    container.append(sliderContainer);



  }

  /**
   * called each step!
   */
  _updateView()
  {

    _slider.updateExogenously(presentation.price);



    if(_quantity == null)
    {
      _quantity = new HTML.LIElement();
      _list.append(_quantity);

    }
    else
      _quantity.innerHtml = "";

    if(ready) {

      _quantity.append(new HTML.Text("You attracted enough customers to sell "));
      _quantity.append(new HTML.SpanElement()
                         ..text = "$customersAttracted"
                         ..classes = ["$colorCustomers"]);
      _quantity.append(new HTML.Text(" kilos of cheese"));

      if(_explanation == null)
      {
        _explanation = new HTML.LIElement();
        _list.append(_explanation);
      }
      if(equilibrium)
      {
        _explanation.text = "Congratulations!";
        _explanation.classes = ["green_highlight"];

      }
      else{
        _explanation.classes = ["red_highlight"];
        if(unsoldInventory)
          _explanation.text = "Some cheese spoiled unsold";
        else
          _explanation.text = "Your price attracted too many customers";

      }
    }




  }

  num get price=>presentation.price;

  num customersAttracted = double.NAN;

  bool get ready => customersAttracted.isFinite;

  bool get shortage=>ready && customersAttracted > 50;

  bool get equilibrium=> ready && customersAttracted == 50;

  bool get unsoldInventory=> ready && customersAttracted < 50;


  String get colorCustomers => customersAttracted == 50 ? "green_highlight" :
                               "red_highlight";

}

/**
 * slider demo with single seller and fixed demand
 */
class SliderDemoGUI extends SliderDemoBase
{



  //price is a computed property (really just a delegation from presentation)
  void set price(num value)
  {
    //whenever you set a new value also step!
    //this is a relatively silly way not to deal with mouse event listeners
    // for release
    super.price = value;

    presentation.step();
  }

  SliderDemoGUI(String selector)
  {


    //build the model objects
    ExogenousSellerScenario scenario = new ExogenousSellerScenario(initialPrice : 1.0);
    this.presentation = new SliderDemoPresentation(
        new Model(new DateTime.now().millisecondsSinceEpoch,scenario),scenario,50.0
        );

    //listen to the stream
    this.presentation.stream.listen((event){
      customersAttracted=event.customersAttracted;
      _updateView();
    });

    _buildSlider(HTML.querySelector(selector));

  }


  SliderDemoGUI.PID(String selector)
  {
    ExogenousSellerScenario scenario = new ExogenousSellerScenario.stockoutPID
    (initialPrice:1.0);
    this.presentation = new SliderDemoPresentation(
        new Model(new DateTime.now().millisecondsSinceEpoch,scenario),scenario,50.0);
    //listen to the stream
    this.presentation.stream.listen((event){
      customersAttracted=event.customersAttracted;
      _updateView();
    });

    //add a control bar

    var root = HTML.querySelector(selector);
    HTML.DivElement controlBar = new HTML.DivElement();
    ControlBar bar = new ControlBar(controlBar,presentation,"PID",(){});
    root.append(controlBar);
    HTML.DivElement slider = new HTML.DivElement();
    _buildSlider(slider);
    root.append(slider);
  }


}


class ChartsDemoGUI
{


  SliderDemoPresentation presentation;

  /**
   * HTML objects
   */
  //the root
  HTML.Element _root;

  ChartsDemoGUI.WithCharts(String selector)
  {
    ExogenousSellerScenario scenario = new ExogenousSellerScenario.stockoutPID
    (initialPrice:1.0);
    this.presentation = new SliderDemoPresentation(
        new Model(new DateTime.now().millisecondsSinceEpoch,scenario),scenario,50.0);


    var root = HTML.querySelector(selector);
    HTML.DivElement controlBar = new HTML.DivElement();
    ControlBar bar = new ControlBar(controlBar,presentation,"PID",()
    {
      //clear if you must
      while(root.hasChildNodes())
        root.firstChild.remove();
      new ChartsDemoGUI.WithCharts(selector);
    });
    root.append(controlBar);
    var chart = new HTML.DivElement();
    root.append(chart);

    new ZKSellerSimple(chart,presentation.agent);

  }

  /**
   * with charts + slider to change target
   */
  ChartsDemoGUI.ChangeInEndowment(String selector,{double resizeScale : 1.0})
  {
    ExogenousSellerScenario scenario = new ExogenousSellerScenario.stockoutPID
    (initialPrice:1.0,dailyFlow:20.0);
    this.presentation = new SliderDemoPresentation(
        new Model(new DateTime.now().millisecondsSinceEpoch,scenario),scenario,20.0);



    var root = HTML.querySelector(selector);
    HTML.DivElement controlBar = new HTML.DivElement();
    ControlBar bar = new ControlBar(controlBar,presentation,"PID",()
    {
      //clear if you must
      while(root.hasChildNodes())
        root.firstChild.remove();
      new ChartsDemoGUI.ChangeInEndowment(selector,resizeScale:resizeScale);
    });
    root.append(controlBar);
    var chart = new HTML.DivElement();
    root.append(chart);

    new ZKSellerSimple(chart,presentation.agent,resizeScale: resizeScale);

    HTML.DivElement slider = new HTML.DivElement();
    slider.style.zoom = "$resizeScale";
    root.append(slider);
    new Slider(slider,"Daily Endowment",(value)=>presentation.inflow=value,initialValue:presentation.inflow);

  }

  ChartsDemoGUI.ChangeInDemand(String selector, {double resizeScale : 1.0})
  {
    ExogenousSellerScenario scenario = new ExogenousSellerScenario.stockoutPID
    (initialPrice:1.0,dailyFlow:20.0);
    this.presentation = new SliderDemoPresentation(
        new Model(new DateTime.now().millisecondsSinceEpoch,scenario),scenario,20.0);
    //listen to the stream


    var root = HTML.querySelector(selector);
    HTML.DivElement controlBar = new HTML.DivElement();
    controlBar.style.zoom = "$resizeScale";
    ControlBar bar = new ControlBar(controlBar,presentation,"PID",()
    {
      //clear if you must
      while(root.hasChildNodes())
        root.firstChild.remove();
      new ChartsDemoGUI.ChangeInDemand(selector,resizeScale:resizeScale);
    });
    root.append(controlBar);
    var chart = new HTML.DivElement();
    root.append(chart);

    new ZKSellerSimple(chart,presentation.agent,resizeScale: resizeScale);


    HTML.DivElement slider = new HTML.DivElement();
    slider.style.zoom = "$resizeScale";
    root.append(slider);
    new Slider(slider,"Demand Intercept",(value)=>presentation.intercept=value,
               initialValue:presentation.intercept, max: 300.0);
    slider = new HTML.DivElement();
    slider.style.zoom = "$resizeScale";
    root.append(slider);
    new Slider(slider,"Demand Slope",(value)=>presentation.slope=value,
               initialValue:presentation.slope, max: -0.5,min: -3.0,by:0.1);

  }

}


class ProductionDemoGUI
{

  MarshallianMicroPresentation presentation;
  OneMarketCompetition scenario;
  Model model;

  ZKPresentation get hr => presentation.hr;
  ZKPresentation get sales => presentation.sales;

  ProductionDemoGUI._internal(String json,[bool macro=false]) {



    model = new Model.fromJSON(json);

    scenario = model.scenario;
    //make sure it's the right scenario
    if(macro)
      scenario.goodMarket = new ExogenousSellerMarket.linkedToWagesFromModel("labor");


    presentation = new MarshallianMicroPresentation.fixedTarget(model,scenario);


    //listen to the presentation to update prices
    presentation.hr.stream.listen((event)=>wage=event.trader.lastOfferedPrice);
    presentation.sales.stream.listen((event)=>price=event.trader
    .lastOfferedPrice);

  }


  factory ProductionDemoGUI.DoubleBeveridge(String json,String selector, [bool macro=false,bool slider=false])
  {
    ProductionDemoGUI base = new ProductionDemoGUI._internal(json,macro);

    HTML.Element  root = HTML.querySelector(selector);
    //clear if you must
    while(root.hasChildNodes())
      root.firstChild.remove();

    //you need a control bar
    HTML.DivElement controlBar = new HTML.DivElement();
    root.append(controlBar);
    ControlBar bar = new ControlBar(controlBar,
                                    base.presentation,"DoubleBeveridge",
                                        ()=>new ProductionDemoGUI.DoubleBeveridge(json,selector,macro,slider),
                                    speed:150);

    if(slider)
    {
      HTML.DivElement container = new HTML.DivElement();
      root.append(container);
      container.style.zoom = ".6";
      controlBar.style.zoom = ".6";

      new Slider(container, "Target",
                     (newTarget) => base.presentation.hrTarget = newTarget, min:1.0, max:100.0,
                 initialValue:base.presentation.hrTarget.toDouble(),
                 by:1.0);
    }

    //you also need a double beveridge
    HTML.DivElement parent = new HTML.DivElement();
    root.append(parent);
    DoubleBeveridge beveridge = new DoubleBeveridge(parent,base.hr,base.sales);




  }

  /**
   * let the user play with a slider to set targets
   */
  factory ProductionDemoGUI.ExogenousProduction(String json,String selector)
  {
    ProductionDemoGUI base = new ProductionDemoGUI._internal(json);

    HTML.Element  root = HTML.querySelector(selector);
    //clear if you must
    while(root.hasChildNodes())
      root.firstChild.remove();

    //you need a control bar
    HTML.DivElement controlBar = new HTML.DivElement();
    root.append(controlBar);
    ControlBar bar = new ControlBar(controlBar,base.presentation,"ExogenousProduction",
                                        ()=>new ProductionDemoGUI.ExogenousProduction(json,selector),speed:50);
    //little div telling what the price and wages are right now
    HTML.DivElement parent = new HTML.DivElement();
    root.append(parent);
    HTML.SpanElement teller =new HTML.SpanElement();
    parent.append(teller);
    base.presentation.stepStream.listen((event){
      if(base.ready)
      {
        teller.text = "Price: ${base.price} ${base.equality} ${base.wage} : Wage";
        teller.classes = ["${base.cssClass}"];
      }
      else{
        teller.text = "";
      }
    });


    //now add a slider
    HTML.DivElement sliderRoot = new HTML.DivElement();
    root.append(sliderRoot);

    Slider slider = new Slider(sliderRoot,"Target Workers: ",(newValue)=>base.target=newValue,
                               initialValue:base.target.toDouble());


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


class SupplyAndDemandGUI
{
  OneMarketFixedWagesPresentation presentation;

  SupplyAndDemandPlot plot;

  HTML.Element  root;

  SupplyAndDemandGUI(String json, String selector, num maxX, num maxY, bool priceLine, bool laborLine) {



    Model model = new Model.fromJSON(json);

    OneMarketCompetition scenario = model.scenario;
    //make sure it's the right scenario


    OneMarketFixedWagesPresentation presentation = new OneMarketFixedWagesPresentation(model,scenario);


    root = HTML.querySelector(selector);
    //clear if you must
    while(root.hasChildNodes())
      root.firstChild.remove();

    //you need a control bar
    HTML.DivElement controlBar = new HTML.DivElement();
    root.append(controlBar);
    ControlBar bar = new ControlBar(controlBar,presentation,"Supply And Demand",
                                        ()=>new SupplyAndDemandGUI(json,selector,maxX,maxY,priceLine,laborLine),speed:80);
    //you also need a double beveridge
    HTML.DivElement parent = new HTML.DivElement();
    root.append(parent);
    plot = new SupplyAndDemandPlot.PresentationCase(parent,presentation.sales,
                                                    presentation.production,presentation.demand,
                                                    resizeScale : 0.5);
    plot.maxX = maxX;
    plot.maxY = maxY;

    if(laborLine)
      plot.curveRepository.addDynamicVLine(()=>presentation.sales.dailyObservations["inflow"].last,"Production");
    if(priceLine)
      plot.curveRepository.addDynamicHLine(()=>presentation.sales.dailyObservations["offeredPrice"].last,"Production");




  }
}