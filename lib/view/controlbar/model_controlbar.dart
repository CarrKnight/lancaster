/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.view;

@Component(
    selector: 'controlbar',
    templateUrl: 'packages/lancaster/view/controlbar/controlbar.html',
    publishAs: 'bar')
class ControlBar
{


  /**
   * the presentation of the model
   */
  ModelPresentation _presentation;

  /**
   * A timer to use to make the model step on its own
   */
  Timer stepper;

  static final  stepTime = const Duration(milliseconds: 10);


  String playLabel = "Start";

  void startOrPause()
  {
    if(stepper==null)
    {
      //start
      playLabel = "Pause";
      stepper = new Timer.periodic(stepTime,(timer)=>step());
    }
    else
    {
      //pause
      stepper.cancel();
      stepper = null;
      playLabel = "Start";

    }
  }

  @NgOneWayOneTime('model-presentation')
  set presentation(ModelPresentation presentation)
  {
    _presentation = presentation;

  }

  int get day => _presentation.day;

  void step()=>_presentation.step();
  void step100Days()=>_presentation.step100Times();

}