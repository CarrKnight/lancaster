/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.view2;


class DrawnTrader extends Sprite
{

  // final Trader _trader;

//  DrawnTrader(this._trader);

//  Trader get trader => _trader;

  Shape _selectionContour;

  BitmapData bitmapData;

  Bitmap image;

  final Trader drawn;

  final HasLocation location;

  DrawnTrader(this.drawn,this.location,this.bitmapData) {
    var bitmap = new Bitmap(bitmapData);
    bitmap.pivotX = 0;
    bitmap.pivotY = 0;


    this.addChild(bitmap);


  }

  void select()
  {
    if(_selectionContour == null)
    {
      _selectionContour = new Shape();
      _selectionContour.graphics.rect(0, 0, this.width+5,this.height+5);
      _selectionContour.graphics.strokeColor(Color.Red,5);
      this.addChild(_selectionContour);
    }
  }

  void deselect()
  {

    assert(_selectionContour != null);
    this.removeChild(_selectionContour);
    _selectionContour = null;
  }


  bool get selected => _selectionContour != null;

  void changeColor(int red, int blue, int green)
  {
    bitmapData.colorTransform(new Rectangle(0,0,width,height),new ColorTransform(0.0,0.0,0.0,1,red,green,blue));

  }
}


/**
 * a StageXL Stage that should have helper methods to deal with traders
 */
class TraderStage extends Stage
{

  final HTML.ImageElement sellerImage;
  final BitmapData buyerBitmap;
  final MATH.Random random;


  DrawnTrader _selected;

  List<DrawnTrader> _traders = new List();

  bool _isDragging = false;
  bool _canDrag = false;

  final StreamController<Trader> _selectionStream = new StreamController();

  TraderStage(HTML.CanvasElement canvas,
              HTML.ImageElement this.sellerImage,
              this.buyerBitmap, this.random,
              {int width, int height, StageOptions options}):
  super(canvas,width:width,height:height,options:options)
  {

    var renderLoop = new RenderLoop();
    renderLoop.addStage(this);

  }

  deselectTrader(DrawnTrader sprite) {
    assert(_selected == sprite);
    sprite.deselect();
    _selected = null;
    if(_selectionStream.hasListener)
      _selectionStream.add(null);

  }

  selectTrader(DrawnTrader sprite) {
    if(_selected !=null)
    {
      assert(_selected != sprite);
      deselectTrader(_selected);
    }
    assert(_selected == null);
    sprite.select();
    _selected = sprite;
    if(_selectionStream.hasListener)
      _selectionStream.add(_selected.drawn);
  }

  makeInteractive(DrawnTrader sprite) {
//closures
    void startDrag(Event e) {
      this.addChild(sprite); // bring to foreground
      sprite.scaleX = sprite.scaleY = 1.15;
      sprite.filters.add(new ColorMatrixFilter.adjust(hue: -0.5));
      sprite.startDrag(true);
    }

    void stopDrag(Event e) {
      sprite.scaleX = sprite.scaleY = 1.0;
      sprite.filters.clear();
      sprite.stopDrag();
    }


    sprite.onMouseDown.listen((e) {
      _canDrag = true;
      _isDragging = false;
    });
    sprite.onMouseMove.listen((e)
                              {
                                if (_canDrag && !_isDragging)
                                {
                                  _isDragging = true;
                                  startDrag(e);
                                }
                              });
    sprite.onMouseUp.listen((e)
                            {
                              _canDrag = false;
                              stopDrag(e);
                            });

    //sprite.onTouchEnd.listen(stopDrag);
    //sprite.onTouchBegin.listen(startDrag);
    this.onMouseLeave.listen((e)
                             {
                               _canDrag = false;
                               stopDrag(e);
                             });
    this.onMouseClick.listen((e) => print("click!"));
    sprite.onMouseClick.listen((e) {
      if (!_isDragging)
      {
        if (sprite.selected)
        {
          deselectTrader(sprite);
        }
        else
        {
          selectTrader(sprite);
        }
      }
      _isDragging = false;
      e.stopPropagation();
      // we stop the propagation so that only one is selected!
    });
  }

  addTrader(int x, int y, HasLocation location, Trader trader)
  {

    var sprite = new DrawnTrader(trader,location,new BitmapData.fromImageElement(sellerImage));
    sprite.x =x;
    sprite.y = y;
    sprite.addTo(this);
    makeInteractive(sprite);

    _traders.add(sprite);

  }


  List<DrawnTrader> get traders => _traders;

  Stream<Trader> get selectionStream => _selectionStream.stream;

}



buildStage() async
{

  StageXL.stageOptions.renderEngine = RenderEngine.Canvas2D;
  StageXL.stageOptions.stageScaleMode = StageScaleMode.SHOW_ALL;
  StageXL.stageOptions.stageAlign = StageAlign.NONE;
  StageXL.stageOptions.inputEventMode = InputEventMode.MouseAndTouch;
  //StageXL.stageOptions.backgroundColor = Color.White;




  var resourceManager = new ResourceManager();
  resourceManager.addBitmapData("factory", "factory.png");
  await resourceManager.load();

  HTML.ImageElement image = new HTML.ImageElement(src: "factory.png");
  await image.onLoad.first;


  var random = new MATH.Random();

  var canvas = HTML.querySelector('#stage');
  var stage = new TraderStage(canvas,image,resourceManager.getBitmapData("factory"),
                              random, width: 600, height: 600);

 // var bitmap = new Bitmap();


  stage.addTrader(300,300,null,new DummyTrader());
  stage.addTrader(400,400,null,new DummyTrader());

  stage.traders[1].changeColor(0,255,0);

  stage.selectionStream.listen((e){
    print(e);
  });






}








