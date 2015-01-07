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
    publishAs: 'gui')
class ModelGUI {

  ModelPresentation presentation;


  ModelGUI()
  {
    SimpleSellerScenario scenario =new SimpleSellerScenario.buffer();
    this.presentation = new ModelPresentation.SimpleSeller(
        new Model(1,scenario),scenario);
  }


  SimpleMarketPresentation get market => presentation.gasPresentation;
  



}
