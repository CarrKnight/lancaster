/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.view;

/**
 * the gui root and therefore a controller. Has the presentation object which
 * in turn deals with the model itself
 */
@Component(
    selector: 'model-gui',
    templateUrl: 'packages/lancaster/view/modelgui.html',
    publishAs: 'gui',
    useShadowDom: false
      )
class ModelGUI {

  final ModelPresentation presentation;

  final String comma = "ahahah";

  ModelGUI() :
    presentation = new ModelPresentation(
        new Model(
            1,new SimpleScenario.simpleSeller()))
  {
    print("gui created");
  }


  SimpleMarketPresentation get market => presentation.gasPresentation;
  



}
