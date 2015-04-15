/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.view2;


typedef void Reset();


class ControlBar
{

  final HTML.DivElement container;

  HTML.AnchorElement playButton;

  HTML.AnchorElement resetButton;

  bool playing = false;

  int speed;

  Duration msPerStep = new Duration(milliseconds:80);


  final ModelPresentation presentation;

  List<StreamSubscription> listeners = [];

  ControlBar(this.container, this.presentation, String simulationId,Reset reset,
             {this.speed:80})
  {
    msPerStep = new Duration(milliseconds:speed);
    //this is how buttons look like in pure.css
    //  <a class="pure-button" href="#">A Pure Button</a>

    //add play button
    playButton = new HTML.AnchorElement()
      ..className = "pure-button pure-button-primary"
//      ..href = "#"
      ..text = "Play";

    listeners.add(
        playButton.onClick.listen((e)
                                  {
                                    playing = !playing;
                                    if(playing)
                                    {
                                      step();
                                      playButton.className="pure-button pure-button-active pure-button-primary";
                                      playButton.text = "Pause";
                                    }
                                    else
                                    {
                                      playButton.className="pure-button pure-button-primary";
                                      playButton.text = "Play";

                                    }
                                  })
        );
    //add reset button
    resetButton = new HTML.AnchorElement()
      ..className = "pure-button"
//      ..href = "#"
      ..text = "Reset";

    listeners.add(
        resetButton.onClick.listen((e)=>reset())
        );

    //add speed slider
    HTML.LabelElement label = new HTML.LabelElement()
      ..text = "Speed "
      ..htmlFor = "${simulationId}_speed";

    HTML.InputElement slider = new HTML.InputElement()
      ..type = "range"
      ..id = "${simulationId}_speed"
      ..min= "10"
      ..value= "${speed}"
      ..max = "300"
      ..step="10";

    slider.style.width = "60%";

    label.append(slider);


    HTML.SpanElement speedometer = new HTML.SpanElement();
    speedometer.style.fontSize = "0.5em";
    speedometer.text=" $speed ms";

    //listen to it
    listeners.add(

        slider.onInput.listen((e){
          speed=int.parse(slider.value);
          msPerStep = new Duration(milliseconds:speed);
          speedometer.text=" $speed ms";
        })
        );

    HTML.SpanElement dayCounter = new HTML.SpanElement();
    dayCounter.text = "";

    listeners.add(
        presentation.stepStream.listen((e)=>dayCounter.text=" Day: ${e.day}")
        );
    //add it all to the container
    container.append(playButton);
    container.append(resetButton);
    container.append(dayCounter);
  //  container.append(new HTML.BRElement());
    container.append(label);
    container.append(speedometer);


  }





  step()
  {
    if(playing)
    {
      presentation.step();
      new Timer(msPerStep,()=>step());
    }
  }

}
