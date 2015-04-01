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
  //the slider
  HTML.RangeInputElement _slider;
  //the price counter
  HTML.DivElement _priceCounter;
  //the quantity counter
  HTML.LIElement _quantity;
  //bullet points
  HTML.UListElement _list;

  //price is a computed property (really just a delegation from presentation)
  void set price(num value)
  {
    //whenever you set a new value also step!
    //this is a relatively silly way not to deal with mouse event listeners
    // for release
    presentation.price = value;

    presentation.step();
  }


  _buildSlider(String selector ) {

    _root = HTML.querySelector(selector);

    print(_root.tagName);
    assert(_root.tagName.toLowerCase() == "section");

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
    sliderContainer.classes = ["center","horizontal","layout"];
    container.append(sliderContainer);

    _priceCounter = new HTML.DivElement();
    _priceCounter.text = "Price $price";
    sliderContainer.append(_priceCounter);

    _slider = new HTML.RangeInputElement();
    _slider.min = "0";
    _slider.max = "100";
    _slider.value = "$price";
    _slider.onChange.listen((e)=>price = double.parse(_slider.value));

    sliderContainer.append(_slider);



  }

  /**
   * called each step!
   */
  _updateView()
  {

    _slider.value = "$price";
    _priceCounter.text = "Price $price";
    print(presentation.day);

  }

  num get price=>presentation.price;

  num customersAttracted = double.NAN;

  bool get ready => customersAttracted.isFinite;

  bool get shortage=>ready && customersAttracted > 50;

  bool get equilibrium=> ready && customersAttracted == 50;

  bool get unsoldInventory=> ready && customersAttracted < 50;


}

/**
 * slider demo with single seller and fixed demand
 */
class SliderDemoGUI extends SliderDemoBase
{

  SliderDemoGUI(String selector)
  {


    //build the model objects
    ExogenousSellerScenario scenario = new ExogenousSellerScenario(initialPrice : 1.0);
    this.presentation = new SliderDemoPresentation(
        new Model(new DateTime.now().millisecondsSinceEpoch,scenario),scenario
    );

    //listen to the stream
    this.presentation.stream.listen((event){
      customersAttracted=event.customersAttracted;
      _updateView();
    });

    _buildSlider(selector);

  }



}



