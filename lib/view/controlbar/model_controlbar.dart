/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.view;

//todo make this into a simple component with a button to press to pass time
@Component(
    selector: 'controlbar',
    templateUrl: 'packages/lancaster/view/controlbar/controlbar.html',
    publishAs: 'bar'
)
class ControlBar
{


  /**
   * the presentation of the model
   */
  ModelPresentation _presentation;




  @NgOneWay('model-presentation')
  set presentation(ModelPresentation presentation)
  {
    _presentation = presentation;

  }

  int get day => _presentation.day;

  void step()=>_presentation.step();
  void step100Days()=>_presentation.step100Times();

}