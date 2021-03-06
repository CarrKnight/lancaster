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

  BitmapData _bitmapData;

  Bitmap _image;

  final Trader drawn;


  final RgbColor defaultColor;

  RgbColor _color;


  TextField _priceLabel;
  TextFormat _format;


  DrawnTrader(this.drawn,this._bitmapData,this.defaultColor)
  {
    var bitmap = new Bitmap(_bitmapData);
    bitmap.pivotX = 0;
    bitmap.pivotY = 0;

    this.addChild(bitmap);

    //add text label
    _format = new TextFormat('Helvetica,Arial', 30, int.parse(defaultColor.toHexColor().toString(),radix:16))
      ..align = "center";
    _priceLabel = new TextField(" --- ",_format);
    _priceLabel..x = 0
      ..y = this.height+10
      ..width = this.width;
    //   ..height = 15
    ;
    changeColor(defaultColor);
    this.addChild(_priceLabel);





  }

  void select()
  {
    if(_selectionContour == null)
    {
      _selectionContour = new Shape();
      _selectionContour.graphics.rect(0, 0, this.width+5,this.height+5);
      _selectionContour.graphics.strokeColor(0xFFFF0000,5);
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

  void changeColor(RgbColor color)
  {
    _color = color;
    _bitmapData.colorTransform(new Rectangle(0,0,width,height),new ColorTransform(0.0,0.0,0.0,1,color.r,color.g,color.b));

    _priceLabel.textColor = int.parse(color.toHexColor().toString(),radix:16);
  }

  void resetColor()
  {
    changeColor(defaultColor);
    _priceLabel.text = " --- ";
  }


  void updatePriceLabel( num price)
  {
    _priceLabel.text = "${price.toStringAsFixed(2)}";
  }


  RgbColor get color => _color;
  void set color(RgbColor color) => changeColor(color);

}


/**
 * a StageXL Stage that should have helper methods to deal with traders
 */
class TraderStage extends Stage
{

  /**
   * the picture representing the seller
   */
  final HTML.ImageElement sellerImage;

  /**
   * the picture representing the buyer
   */
  final HTML.ImageElement buyerImage;

  /**
   * randomizer
   */
  final MATH.Random random;

  /**
   * default buyer color when having no supplier
   */
  static final  RgbColor defaultColor = new HexColor("#000000").toRgbColor();

  /**
   * model link
   */
  final GeographicalMarketPresentation _presentation;

  /**
   * sprite selected
   */
  DrawnTrader _selected;

  /**
   * map of trader--->sprite
   */
  Map<Trader,DrawnTrader> _traders = new HashMap();

  /**
   * here we store the colors for each seller. Sellers have each their own unique color
   * while buyer all come in defaultColor and then change them to represent whatever buyer they buy from.
   */
  Map<Trader,RgbColor> sellerColor = new HashMap();

  /**
   * an element is being dragged
   */
  bool _isDragging = false;

  /**
   * elements can be currently dragged
   */
  bool _canDrag = false;

  /**
   * streaming whatever trader is currently selected
   */
  final StreamController<Trader> _selectionStream = new StreamController();

  /**
   * converts between model location and gui location
   */
  final LocationConverter converter = new IdentityLocationConverter();

  TraderStage(HTML.CanvasElement canvas,
              HTML.ImageElement this.sellerImage,
              HTML.ImageElement this.buyerImage,
              this.random,
              this._presentation,
              {int width, int height, StageOptions options}):
  super(canvas,width:width,height:height,options:options)
  {

    var renderLoop = new RenderLoop();
    renderLoop.addStage(this);
    //add pre-existing agents
    Map<Trader,Locator> locators = _presentation.traders;
    locators.forEach( (k,v){
      Location location = v.location;
      addTrader(converter.LocationToX(location),
                converter.LocationToY(location),
                k);
    });


    //listen to movements
    _presentation.movementStream.listen(reactToMovement);

    //whenever a new day occurs, reset all colors
    _presentation.dawnStream.listen((e){
      resetAllTradersColors();
    });

    //set the price labels of the buyers and sellers as they interact with the order book
    _presentation.askStream.listen((e)
                                   {
                                     traders[e.trader].updatePriceLabel(e.unitPrice);
                                   });

    _presentation.bidStream.listen((e)
                                   {
                                     traders[e.trader].updatePriceLabel(e.unitPrice);
                                   });

    //set the buyer color to be equal to the seller color when they buy from it
    _presentation.tradeStream.listen((e)
                                     {
                                       DrawnTrader seller = traders[e.seller];
                                       DrawnTrader buyer = traders[e.buyer];
                                       buyer.changeColor(seller.color);
                                     });



    this.doubleClickEnabled = true;


    this.onMouseClick.listen((e){
      if(_selected!=null)
        deselectTrader(_selected);

    });

    this.onMouseDoubleClick.listen((e)  {
      _presentation.createNewBuyer(
          converter.ViewToLocation(e.localX, e.localY)
          );

    }
                                   );
  }

  /**
   * tell all buyers to reset their sprite color to black
   */
  void resetAllTradersColors()
  {
  //  print("resetting all colors now!");
    for(DrawnTrader t in traders.values)
      t.resetColor();


  }

  /**
   * what gets called whenever there is a movement event in the presentation stream
   */
  void reactToMovement(MovementEvent e)
  {
    //if the previous location is null, then it's a new trader!
    if(e.previousLocation == null)
      addTrader(converter.LocationToX(e.newLocation),
                converter.LocationToY(e.newLocation),e.mover
                );
    //if the new location is null, then remove it
    if(e.newLocation==null)
      removeTrader(e.mover);

    //otherwise move it!
    DrawnTrader drawing = traders[e.mover];
    drawing.x = converter.LocationToX(e.newLocation);
    drawing.y = converter.LocationToY(e.newLocation);


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
      if(!_canDrag)
      {
        _canDrag = true;
        _isDragging = false;
      }
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
                              if(_isDragging)
                              {
                                stopDrag(e);
                                var trader = sprite.drawn;
                                _presentation.move(trader,converter.ViewToLocation(sprite.x,sprite.y));
                              }
                            });

    //sprite.onTouchEnd.listen(stopDrag);
    //sprite.onTouchBegin.listen(startDrag);

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

  addTrader(num x, num y,  Trader trader)
  {



    var isSeller = _presentation.isSeller(trader);
    var traderBitmap = isSeller ?
                       new BitmapData.fromImageElement(sellerImage) :
                       new BitmapData.fromImageElement(buyerImage);

    Random random = _presentation.random;


    RgbColor color = isSeller ?  new RgbColor(random.nextInt(255),
                                              random.nextInt(255),
                                              random.nextInt(255)) :
                     defaultColor;
    if(isSeller)
      sellerColor[trader] = color;

    var sprite = new DrawnTrader(trader, traderBitmap, color);
    sprite.x =x;
    sprite.y = y;
    sprite.addTo(this);
    makeInteractive(sprite);

    assert(!_traders.containsKey(trader));
    _traders[trader] = sprite;

  }

  removeTrader(Trader trader)
  {
    //remove it from the screen!
    this.removeChild(_traders.remove(trader));
  }


  Map<Trader,DrawnTrader> get traders => _traders;

  Stream<Trader> get selectionStream => _selectionStream.stream;
  
}


/**
 * the model works on "Location", the view works by x-y simple coordinates. There needs to be a way to convert
 * between one and the other so that if something moves in the model, it shows in the gui and viceversa.
 */
abstract class LocationConverter
{
  Location ViewToLocation(num x, num y);

  num LocationToX(Location location);

  num LocationToY(Location location);
  
}

/**
 * screen and actual locations are the same
 */
class IdentityLocationConverter extends LocationConverter
{


  Location ViewToLocation(num x, num y) {
    return new Location([x,y]);
  }

  num LocationToX(Location location) {
    return location.coordinates[0];
  }

  num LocationToY(Location location) {
    return location.coordinates[1];

  }
  
  
}

Future<TraderStage> buildDefaultStage(GeographicalMarketPresentation presentation,
                              HTML.CanvasElement canvas,
                              int width, int height) async
{

  StageXL.stageOptions.renderEngine = RenderEngine.Canvas2D;
  StageXL.stageOptions.stageScaleMode = StageScaleMode.SHOW_ALL;
  StageXL.stageOptions.stageAlign = StageAlign.NONE;
  StageXL.stageOptions.inputEventMode = InputEventMode.MouseAndTouch;
  StageXL.stageOptions.backgroundColor = 0xFFE0FFFF;

  HTML.ImageElement image = new HTML.ImageElement(src: "factory.png");
  HTML.ImageElement buyerImage = new HTML.ImageElement(src: "user.png");
  await image.onLoad.first;
  await buyerImage.onLoad.first;

  var random = new MATH.Random();

  var stage = new TraderStage(canvas,image,buyerImage,
                              random,presentation,
                              width: width, height: height);
  return stage;
}

BuildTestStage() async
{

  StageXL.stageOptions.renderEngine = RenderEngine.Canvas2D;
  StageXL.stageOptions.stageScaleMode = StageScaleMode.SHOW_ALL;
  StageXL.stageOptions.stageAlign = StageAlign.NONE;
  StageXL.stageOptions.inputEventMode = InputEventMode.MouseAndTouch;
  StageXL.stageOptions.backgroundColor = 0xFFE0FFFF;



  //model
  Model model = new Model(0);
  GeographicalMarket market = new GeographicalMarket(CartesianDistance);
  market.start(model.schedule,model);
  GeographicalMarketPresentation presentation = new GeographicalMarketPresentation(market,model,
                                                                                   new GeoBuyerFixedPriceGenerator());


  var resourceManager = new ResourceManager();
  resourceManager.addBitmapData("factory", "factory.png");
  await resourceManager.load();

  HTML.ImageElement image = new HTML.ImageElement(src: "factory.png");
  HTML.ImageElement buyerImage = new HTML.ImageElement(src: "user.png");
  await image.onLoad.first;
  await buyerImage.onLoad.first;

  var random = new MATH.Random();

  var canvas = HTML.querySelector('#stage');
  var stage = new TraderStage(canvas,image,buyerImage,
                              random,presentation,
                              width: 1024, height: 800);

  // var bitmap = new Bitmap();

  Trader t1 = new DummyTrader();
  Locator l1 = new Locator(t1,new Location([300,300]));
  Trader t2 = new DummyTrader();
  Locator l2 = new Locator(t2,new Location([400,400]));

  market.sellers.add(t1);
  market.sellers.add(t2);
  market.registerLocator(t1,l1);
  market.registerLocator(t2,l2);

  /*
  stage.addTrader(300,300,new DummyTrader(),TraderStage.defaultColor);
  var trader2 = new DummyTrader();
  stage.addTrader(400,400, trader2,new RgbColor(0,0,255));

  stage.traders[trader2].changeColor(new RgbColor(0,255,0));
  stage.traders[trader2].changeColor(new RgbColor(255,0,0));

*/
  stage.selectionStream.listen((e){
    print(e);
  });


  new Timer(new Duration(seconds:2),(){
    l2.location = new Location([0,0]);
  });
  
  
  
  
  
}








