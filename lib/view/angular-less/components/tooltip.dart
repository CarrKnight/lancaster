/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */


//this is almost copy-pasted from the angular tutorial.
part of lancaster.view2;







class Tooltip {
  final HTML.Element element;

  String message;

  HTML.Element tooltipElem;

  /**
   * listeners
   */
  StreamSubscription onEnter;
  StreamSubscription onLeave;



  Tooltip(this.element,this.message) {
    StreamSubscription onListen =
    element.onMouseEnter.listen((HTML.MouseEvent event) =>
    _createTemplate(event));
    StreamSubscription onLeave =
    element.onMouseLeave.listen((_) => _destroyTemplate());
  }

  void _createTemplate(HTML.MouseEvent event) {
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

    tooltipElem.style
      ..position = "absolute"
      ..top = "${event.page.y - 10}px"
      ..left = "${event.page.x + 10}px";

    print("pos y: ${event.page.y} x:  ${event.page.x} ");


    // Add the tooltip to the document body. We add it here because we need to position it
    // absolutely, without reference to its parent element.
    HTML.document.body.append(tooltipElem);
  }

  void _destroyTemplate() {
    tooltipElem.remove();
    tooltipElem == null;
  }


  void killTooltip(){
    if(onEnter != null)
      onEnter.cancel();
    if(onLeave != null)
      onLeave.cancel();
    if(tooltipElem != null)
      _destroyTemplate();
  }
}