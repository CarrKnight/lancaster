/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.view;


/**
 * the root of a simple simulation using OneMarketCompetitive scenario with
 * standard parameters
 */

@Component(
    selector: 'marshallian-micro',
    templateUrl: 'packages/lancaster/view/scenario/onemarket/onemarketgui.html')
class MarshallianMicroGUI {

  MarshallianMicroPresentation presentation;


  MarshallianMicroGUI()
  {
    OneMarketCompetition scenario =new OneMarketCompetition();
    this.presentation = new MarshallianMicroPresentation(
        new Model(new DateTime.now().millisecondsSinceEpoch,scenario),scenario);
  }


  ZKPresentation get hr => presentation.hr;
  ZKPresentation get sales => presentation.sales;


}