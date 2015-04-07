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

  ZKSellerSimple(this._parent, this._presentation)
  {

    _parent.style.width = "100%";


    HTML.DivElement left = new HTML.DivElement()
    ..style.border ="0px"
    ..style.padding ="0px"
    ..style.width ="50%"
    ..style.float ="left"
    ;
    _parent.append(left);

    new SellerBeveridge(left,_presentation);

    HTML.DivElement right = new HTML.DivElement()
      ..style.border ="0px"
      ..style.padding ="0px"
      ..style.width ="50%"
      ..style.float ="right"
    ;
    _parent.append(right);

    new ZKStockoutTimeSeriesChart(_presentation,right);

    HTML.DivElement clearer = new HTML.DivElement();
    clearer.style.clear="both";

    _parent.append(clearer);

  }


}
/*
parent {
    width: 100%;

}
div#one {
    border: 0px;
    padding: 0px;

    width: 50%;
    float: left;
}
div#two {
    border: 0px;
    padding: 0px;

    width: 50%;

    float: right;
}
 */