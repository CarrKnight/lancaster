/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.view;


class ControlBarBase{


  /**
   * the presentation of the model
   */
  ModelPresentation _presentation;

  /**
   * A timer to use to make the model step on its own
   */
  Timer stepper;

  Duration stepTime = const Duration(milliseconds: 15);


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

  @NgOneWayOneTime('period')
  set period(int newValue)
  {
    stepTime = new Duration(milliseconds:newValue);
  }


  int get day => _presentation.day;

  bool get running => stepper!=null;
  void step()=>_presentation.step();
  void step100Days()=>_presentation.step100Times();

}

@Component(
    selector: 'controlbar',
    templateUrl: 'packages/lancaster/view/controlbar/controlbar.html',
    publishAs: 'bar')
class ControlBar extends ControlBarBase
{
}
@Component(
    selector: 'controlbar-paper',
    templateUrl: 'packages/lancaster/view/controlbar/paperbar.html',
    cssUrl: 'packages/lancaster/view/controlbar/paperbar.css',
    publishAs: 'bar')
class PaperControlBar extends ControlBarBase
{
}