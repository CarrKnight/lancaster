/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */


//this is almost copy-pasted from the angular tutorial.
part of lancaster.view;







@Decorator(selector: '[tooltip]')
class Tooltip {
  final HTML.Element element;

  @NgOneWay('tooltip')
  String message;

  HTML.Element tooltipElem;

  /**
   * listeners
   */
  StreamSubscription onEnter;
  StreamSubscription onLeave;



  Tooltip(this.element) {
    StreamSubscription onListen =
    element.onMouseEnter.listen((_) => _createTemplate());
    StreamSubscription onLeave =
    element.onMouseLeave.listen((_) => _destroyTemplate());
  }

  void _createTemplate() {
    print("tooltip!");
    assert(message != null);

    tooltipElem = new HTML.DivElement();
    tooltipElem.classes = [ "tooltip"];



    HTML.SpanElement textSpan = new HTML.SpanElement()
      ..appendText(message)
      ..style.color = "white"
      ..style.fontSize = "smaller"
      ..style.paddingBottom = "5px";

    tooltipElem.append(textSpan);



    tooltipElem.style
      ..padding = "5px"
      ..paddingBottom = "0px"
      ..backgroundColor = "black"
      ..borderRadius = "5px"
      ..width = "${textSpan.attributes["width"]}px";

    // position the tooltip.
    var topRight = element.getBoundingClientRect().topRight;
    var lowLeft = element.getBoundingClientRect().bottomLeft;


    tooltipElem.style
      ..position = "absolute"
      ..top = "${(topRight.y + lowLeft.y)/2 + 10}px"
      ..left = "${(topRight.x+ lowLeft.x)/2 + 10}px";

    print("pos topRight: ${topRight}");


    // Add the tooltip to the document body. We add it here because we need to position it
    // absolutely, without reference to its parent element.
    HTML.document.body.append(tooltipElem);
  }

  void _destroyTemplate() {
    tooltipElem.remove();
  }


  void killTooltip(){
    onEnter.cancel();
    onLeave.cancel();
  }
}