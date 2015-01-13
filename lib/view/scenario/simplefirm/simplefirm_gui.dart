/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.view;


/**
 * the root of a simple simulation using SimpleFirm scenario
 */

@Component(
    selector: 'simple-firm-gui',
    templateUrl: 'packages/lancaster/view/scenario/simplefirm/simplefirmgui.html')
class SimpleFirmGUI {

  SimpleFirmPresentation presentation;


  SimpleFirmGUI()
  {
    SimpleFirmScenario scenario =new SimpleFirmScenario();
    this.presentation = new SimpleFirmPresentation(
        new Model(new DateTime.now().millisecondsSinceEpoch,scenario),scenario);
  }


  ZKPresentation get hr => presentation.hr;
  ZKPresentation get sales => presentation.sales;


}