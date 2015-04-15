/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.view2;


/**
 * function called by the slider when there is a new input
 */
typedef void SliderInput(double newValue);



class Slider
{


  final HTML.DivElement sliderContainer;


  final String variableName;

  final SliderInput input;

  //the variable counter
  HTML.DivElement counter;

  bool _beingChanged = false;

  /**
   * the slider itself
   */
  HTML.RangeInputElement _slider;

  Slider(this.sliderContainer, this.variableName, this.input,
         {double min: 0.0,
         double max: 100.0,
         double initialValue: 1.0,
         double by: 1.0}) {

    sliderContainer.classes = ["center","horizontal","layout"];

    counter = new HTML.DivElement();
    counter.text = "$variableName $initialValue";
    sliderContainer.append(counter);

    _slider = new HTML.RangeInputElement();
    _slider.min = "$min";
    _slider.max = "$max";
    _slider.value = "$initialValue";
    _slider.step = "$by";
    _slider.onChange.listen((e){
      input(double.parse(_slider.value));
      counter.text = "$variableName ${_slider.value}";
    });

    _slider.onMouseDown.listen((e)=>_beingChanged=true);
    _slider.onMouseUp.listen((e)=>_beingChanged=false);

    _slider.style.width = "100%";

    sliderContainer.append(_slider);



  }

  /**
   * Call this if the slider value is changed from somewhere else other than user input
   */
  void updateExogenously(double value)
  {

    if(_beingChanged)
      return;

    _slider.value = "$value";
    counter.text = "$variableName $value";
  }


}
