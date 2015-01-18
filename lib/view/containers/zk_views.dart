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



  @NgOneWayOneTime('presentation')
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

@Component(
    selector: 'zk-seller-simple',
    templateUrl: 'packages/lancaster/view/containers/zk_seller_simple.html',
    cssUrl: 'packages/lancaster/view/containers/marketview.css')
class ZKSellerSimple extends ZKView{}


@Component(
    selector: 'double-beveridge',
    templateUrl: 'packages/lancaster/view/containers/double_beveridge.html',
    cssUrl: 'packages/lancaster/view/containers/marketview.css')
/**
 * a simple splitter of the model presentation in hr and sales presentation
 * so that you can feed that stuff in two separate beveridges
 */
class DoubleBeveridge
{
  @NgOneWayOneTime('presentation')
  MarshallianMicroPresentation presentation;


  ZKPresentation get hr => presentation.hr;
  ZKPresentation get sales => presentation.sales;

}