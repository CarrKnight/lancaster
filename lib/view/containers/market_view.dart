/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.view;

/**
 * for now just a simple list of trades + ugly chart
 */
@Component(
    selector: 'marketview',
    templateUrl: 'packages/lancaster/view/containers/marketview.html',
    cssUrl: 'packages/lancaster/view/containers/marketview.css')
class MarketView{

  /**
   * the presentation object which is our interface to the model itself
   */
  SimpleMarketPresentation _presentation;



  num price = double.NAN;

  num quantity = double.NAN;

  void _listenToModel(){
    _presentation.stream.listen((event){
      price = event.price;
      quantity = event.quantity;
    });
  }

  @NgOneWay('presentation')
  set presentation(SimpleMarketPresentation presentation)
  {
    _presentation = presentation;
    _listenToModel();
  }


  SimpleMarketPresentation get presentation => _presentation;




}
