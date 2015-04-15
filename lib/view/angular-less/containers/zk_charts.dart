/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */


part of lancaster.view2;

/**
 * Container with time series and beveridge plot, side by side
 */

class ZKSellerSimple
{

  final HTML.DivElement _parent;

  final ZKPresentation _presentation;

  ZKSellerSimple(this._parent, this._presentation,{double resizeScale : 1.0})
  {

    _TwoDivsSideBySide frame = new _TwoDivsSideBySide(_parent,"Beveridge Curve","Time Chart");

    frame.parent.style.zoom = "$resizeScale";


    new SellerBeveridge(frame.left,_presentation,resizeScale : resizeScale);



    new ZKStockoutTimeSeriesChart(_presentation,frame.right,resizeScale : resizeScale);



  }


}

/**
 * Two beverdige curves, hr and sales, side by side
 */
class DoubleBeveridge
{
  final HTML.DivElement _parent;

  final ZKPresentation hr;

  final ZKPresentation sales;

  DoubleBeveridge(this._parent, this.hr, this.sales) {
    _TwoDivsSideBySide frame = new _TwoDivsSideBySide(_parent, "Labor Market", "Goods Market");

    new BuyerBeveridge(frame.left,hr);

    new SellerBeveridge(frame.right,sales);

  }


}

class _TwoDivsSideBySide
{
  final HTML.DivElement left;

  final HTML.HeadingElement leftTitle;

  final HTML.DivElement right;

  final HTML.HeadingElement rightTitle;

  final HTML.DivElement parent;

  final HTML.DivElement clearer;

  _TwoDivsSideBySide(this.parent, String titleOnLeft, String titleOnRight):
  right = new HTML.DivElement(),
  rightTitle = new HTML.HeadingElement.h5(),
  left = new HTML.DivElement(),
  leftTitle = new HTML.HeadingElement.h5(),
  clearer = new HTML.DivElement()
  {
    parent.style.width = "100%";


    left
      ..style.border ="0px"
      ..style.padding ="0px"
      ..style.width ="50%"
      ..style.float ="left"
    ;
    parent.append(left);
    leftTitle.text = titleOnLeft;
    left.append(leftTitle);


    right
      ..style.border ="0px"
      ..style.padding ="0px"
      ..style.width ="50%"
      ..style.float ="right"
    ;
    parent.append(right);
    rightTitle.text = titleOnRight;
    right.append(rightTitle);


    clearer.style.clear="both";

    parent.append(clearer);
  }


}