/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.view;

/**
 * just a container for the presentation and the subviews/charts
 */

abstract class ZKView{

  /**
   * the presentation object
   */
  ZKPresentation _presentation;



  @NgOneWay('presentation')
  set presentation(ZKPresentation presentation)
  {
    _presentation = presentation;
  }


  ZKPresentation get presentation => _presentation;




}



@Component(
    selector: 'zk-buyer',
    templateUrl: 'packages/lancaster/view/containers/zk_buyer.html',
    cssUrl: 'packages/lancaster/view/containers/zk.css')
class ZKBuyer extends ZKView{}

@Component(
    selector: 'zk-seller',
    templateUrl: 'packages/lancaster/view/containers/zk_seller.html',
    cssUrl: 'packages/lancaster/view/containers/zk.css')
class ZKSeller extends ZKView{}
