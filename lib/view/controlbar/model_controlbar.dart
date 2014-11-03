/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.view;

@Component(
    selector: 'controlbar',
    templateUrl: 'packages/lancaster/view/controlbar/controlbar.html',
    publishAs: 'bar',
    useShadowDom: false
)
class ControlBar
{


  /**
   * the presentation of the model
   */
  ModelPresentation _presentation;




  @NgOneWayOneTime('model-presentation')
  set presentation(ModelPresentation presentation)
  {
    _presentation = presentation;

  }

  int get day => _presentation.day;

  void step()=>_presentation.step();
  void step100Days()=>_presentation.step100Times();

}