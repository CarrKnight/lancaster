/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.model;


/**
 * the price predictor's job is to predict what might be the future price,
 * taking into consideration possible production changes
 */
abstract class PricePredictor{

  /**
   * some predictors need to be started/scheduled when the trader is started.
   * Others
   * simply ignore this call.
   */
  void start(Trader trader, Schedule s, Data data);


  /**
   * predict the price this trader will set for buying/selling after a
   * specific change in input. [quantityChange] is the  expected change in
   * input needed or output produced.
   */
  num predictPrice(Trader trader,num quantityChange);

}


/**
 * always predicts last CLOSING price. Also is a singleton
 */
class LastPricePredictor implements PricePredictor
{


  static const String DB_ADDRESS = "default.strategy.LastPricePredictor";

  static final  LastPricePredictor _singleton = new LastPricePredictor
  ._internal();

  LastPricePredictor._internal();

  /**
   *  always predicts last CLOSING price
   */
  factory LastPricePredictor(){
    return _singleton;
  }



  /**
   *  always predicts last CLOSING price
   */
  factory LastPricePredictor.FromDB(ParameterDatabase db, String containerPath){
    return _singleton;
  }

  /**
   * just return the last price
   */
  num predictPrice(Trader trader, num changeInInput) =>
  trader.lastClosingPrice;

  /**
   * nothing happens during start
   */
  void start(Trader trader, Schedule s, Data data) { }

}


/**
 * it assumes there is a fixed slope
 */
class FixedSlopePredictor implements PricePredictor
{


  static const String DB_ADDRESS = "default.strategy.PricePredictor";


  /**
   * the slope of the predictor
   */
  num slope;

  /**
   * create the slope predictor
   */
  FixedSlopePredictor([this.slope=0.0]);


  /**
   * create the slope predictor
   */
  FixedSlopePredictor.FromDB(ParameterDatabase db, String containerPath)
  :
  this(db.getAsNumber("$containerPath.slope","$DB_ADDRESS.slope"));

  /**
   * unused
   */
  void start(Trader trader, Schedule s, Data data) {}

  /**
   * [trader] last price + [currentQuantity] * slope
   */
  num predictPrice(Trader trader, num quantityChange)
  => trader.lastClosingPrice + quantityChange * slope;


}

typedef bool DataValidator(num x,num y);

/**
 * runs a kalman linear regression price~a+b*quantity and then predicts:
 * newPrice = lastClosingPrice + b* quantityChange.
 *
 */
class KalmanPricePredictor implements PricePredictor
{

  static const String DB_ADDRESS = "default.strategy.KalmanPricePredictor";


  /**
   * how many observations before we start using the kalman slope
   */
  int burnoutRate = 100;

  int _observations = 0;

  /**
   * data column representing the quantity
   */
  final String xColumnName;

  /**
   * data column representing the y
   */
  final String yColumnName;

  final KalmanFilter filter;

  final FixedSlopePredictor delegate;

  /**
   * useful function if you need some observations removed. By default
   * accepts all
   */
  DataValidator dataValidator = (num x, num y)  =>true;

  Data data;



  KalmanPricePredictor(this.xColumnName,this.burnoutRate, double
  initialSlope, this.yColumnName, num forgettingRate,
  num maxTrace):
  delegate = new FixedSlopePredictor(initialSlope),
  filter = new KalmanFilter(2)
  {
    filter.forgettingFactor = forgettingRate;
    filter.maxTraceToStopForgetting = maxTrace;
  }


  KalmanPricePredictor.FromDB(ParameterDatabase db, String containerPath):

  this(
    db.getAsString("$containerPath.xColumnName","$DB_ADDRESS.xColumnName"),
    db.getAsNumber("$containerPath.burnoutRate","$DB_ADDRESS.burnoutRate"),
    db.getAsNumber("$containerPath.initialSlope","$DB_ADDRESS.initialSlope"),
    db.getAsString("$containerPath.yColumnName","$DB_ADDRESS.yColumnName"),
    db.getAsNumber("$containerPath.forgettingRate","$DB_ADDRESS.forgettingRate"),
    db.getAsNumber("$containerPath.maxTrace","$DB_ADDRESS.maxTrace")
  );


  num predictPrice(Trader trader, num quantityChange)
  =>delegate.predictPrice(trader,quantityChange);




  /**
   * schedule itself to learn every day
   */
  void start(Trader trader, Schedule s, Data data) {
    //because it is called by adjust_production you need to learn before then.
    //when exactly doesn't matter since it is reading from data which gets
    // updated at the end of the day anyway.
    List<double> xColumn = data.getObservations(xColumnName);
    List<double> yColumn = data.getObservations(yColumnName);

    s.scheduleRepeating(Phase.ADJUST_PRICES,(s)=>learn(xColumn,yColumn));


  }

  learn(List<double> xColumn, List<double> yColumn)
  {
    //checks for data validity
    if(xColumn.isEmpty)
      return;
    assert(yColumn.isNotEmpty);

    num x = xColumn.last;
    num y = yColumn.last;

    if(!x.isFinite || !y.isFinite || !dataValidator(x,y))
      //can't really use this observation!
      return;

    //okay we can learn
    filter.addObservation(1.0,y,[1.0,x]);
    _observations++;
    //if possible, use it as slope
    if(burnoutRate<=observations)
      delegate.slope = filter.beta[1];
  }


  int get observations=> _observations;

}