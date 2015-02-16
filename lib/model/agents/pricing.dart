/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.model;

/**
 * a class used by traders to adapt prices or quantities
 */
abstract class AdaptiveStrategy
{

  /**
   * to call by the user, probably every day.
   */
  adapt(Trader t, Data data);

  /**
   * the price per unit to charge for this strategy
   */
  double get value;


}

abstract class ControlStrategy extends AdaptiveStrategy
{
  double get lastTarget;
  double get lastControlledVariable ;

}


/**
 * a simple fixed extractor
 */
class FixedExtractor implements Extractor{

  final double output;

  FixedExtractor(this.output);

  extract(Data data)=>output;
}

abstract class HasExtractor{
  Extractor get extractor;
}




/**
 * A PID pricer that simply tries to put inflow=outflow. In reality unless
 * stockouts are counted it can only work when decreasing prices
 * rather than increasing them, which is why we need inventory buffers
 */
class PIDAdaptive implements ControlStrategy
{

  /**
   * turn data into a double we use as target for PID
   */
  Extractor targetExtractor;




  /**
   * turn data into an observation of the current observation
   */
  Extractor cvExtractor;

  /**
   * the controller itself that does all the adaptation
   */
  Controller pid;

  double lastTarget = double.NAN;
  double lastControlledVariable = double.NAN;

  /**
   * The first time adapt is called this strategy plug in its target and cv
   * in the data of the trader. Once that is done, this flag is set to false.
   */
  bool _columnToSet = true;

  /**
   * the data in the trader will be plugin as [columName]_target and
   * [columnName]_cv
   */
  String columnName;


  static const  String DB_ADDRESS= "default.strategy.PIDAdaptive";
  /**
   * constructor
   */
  PIDAdaptive(this.targetExtractor,this.cvExtractor,
              {double p: PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
              double i: PIDController.DEFAULT_INTEGRAL_PARAMETER,
              double d: PIDController.DEFAULT_DERIVATIVE_PARAMETER,
              double offset: 0.0, this.columnName : "pricer"}):
  pid = new PIDController(p,i,d){
    pid.offset = offset;
  }

  PIDAdaptive.fromDB(Extractor targetExtractor, Extractor cvExtractor,
                     ParameterDatabase db, String containerPath):
  this(targetExtractor,cvExtractor,
       p:db.getAsNumber("$containerPath.p","$DB_ADDRESS.p"),
       i:db.getAsNumber("$containerPath.i","$DB_ADDRESS.i"),
       d:db.getAsNumber("$containerPath.d","$DB_ADDRESS.d"),
       offset:db.getAsNumber("$containerPath.offset","$DB_ADDRESS.offset"),
       columnName:db.getAsString("$containerPath.columnName","$DB_ADDRESS.columnName")
       );





  static  Extractor DEFAULT_SELLER_TARGET_EXTRACTOR()=> new SimpleExtractor("inflow",(x)=>-x);
  static  Extractor DEFAULT_SELLER_CV_EXTRACTOR()=>  new SimpleExtractor("outflow",(x)=>-x);

  PIDAdaptive.DefaultSeller({double offset: 0.0,
                            double p:
                            PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                            double i:
                            PIDController.DEFAULT_INTEGRAL_PARAMETER,
                            double d:
                            PIDController.DEFAULT_DERIVATIVE_PARAMETER,
                            String columnName: "pricer"
                            }) : //target: -inflows,
  // controlled variable = -outflow the minuses to adapt the right way
  this(DEFAULT_SELLER_TARGET_EXTRACTOR(),
       DEFAULT_SELLER_CV_EXTRACTOR(),
       offset:offset, p:p,i:i,d:d,columnName:columnName);

  PIDAdaptive.DefaultSellerFromDB(ParameterDatabase db, String containerPath):
  this.fromDB(DEFAULT_SELLER_TARGET_EXTRACTOR(),
              DEFAULT_SELLER_CV_EXTRACTOR(),
              db,containerPath);

  static Extractor STOCKOUT_SELLER_TARGET_EXTRACTOR()=>  new SimpleExtractor("inflow",(x)=>-x);
  static Extractor STOCKOUT_SELLER_CV_EXTRACTOR()=>  new SumOfSimpleExtractors(["outflow","stockouts"],(x)=>-x);

  /**
   * pid seller that counts stockouts
   */
  PIDAdaptive.StockoutSeller({double initialPrice: 0.0,
                             double p:
                             PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                             double i:
                             PIDController.DEFAULT_INTEGRAL_PARAMETER,
                             double d:
                             PIDController.DEFAULT_DERIVATIVE_PARAMETER,
                             String columnName: "pricer"
                             }) : //target: -inflows,
  // controlled variable = -outflow - stockouts
  this(STOCKOUT_SELLER_TARGET_EXTRACTOR(),
       STOCKOUT_SELLER_CV_EXTRACTOR(),
       offset:initialPrice, p:p,i:i,d:d,columnName:columnName);


  PIDAdaptive.StockoutSellerFromDB(ParameterDatabase db, String containerPath):
  this.fromDB(STOCKOUT_SELLER_TARGET_EXTRACTOR(),
              STOCKOUT_SELLER_CV_EXTRACTOR(),
              db,containerPath);



  static Extractor STOCKOUT_BUYER_TARGET_EXTRACTOR()=>  new SimpleExtractor("outflow",(x)=>x);
  static Extractor STOCKOUT_BUYER_CV_EXTRACTOR()=>  new SumOfSimpleExtractors(["inflow","stockouts"],(x)=>x);

  /**
   * pid buyer that counts stockouts
   */
  PIDAdaptive.StockoutBuyer({double initialPrice: 0.0,
                            double p:
                            PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                            double i:
                            PIDController.DEFAULT_INTEGRAL_PARAMETER,
                            double d:
                            PIDController.DEFAULT_DERIVATIVE_PARAMETER,
                            String columnName: "pricer"
                            }) : //target: -outflow,
  // controlled variable = -(inflow+stockouts)
  this(STOCKOUT_BUYER_TARGET_EXTRACTOR(),
       STOCKOUT_BUYER_CV_EXTRACTOR(),
       offset:initialPrice, p:p,i:i,d:d,columnName:columnName);

  PIDAdaptive.StockoutBuyerFromDB(ParameterDatabase db, String containerPath)
  :
  this.fromDB(STOCKOUT_BUYER_TARGET_EXTRACTOR(),STOCKOUT_BUYER_CV_EXTRACTOR(),db,containerPath);



  static Extractor STOCKOUT_QUOTA_BUYER_TARGET_EXTRACTOR()=> new SimpleExtractor("quota",(x)=>x);
  static Extractor STOCKOUT_QUOTA_BUYER_CV_EXTRACTOR()=> new SumOfSimpleExtractors(["inflow","stockouts"],(x)=>x);


  /**
   * pid buyer that counts stockouts and targets quota rather than outflows
   */
  PIDAdaptive.StockoutQuotaBuyer({double initialPrice: 0.0,
                                 double p:
                                 PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                                 double i:
                                 PIDController.DEFAULT_INTEGRAL_PARAMETER,
                                 double d:
                                 PIDController.DEFAULT_DERIVATIVE_PARAMETER,
                                 String columnName: "pricer"
                                 }) : //target: -outflow,
  // controlled variable = -(inflow+stockouts)
  this(STOCKOUT_QUOTA_BUYER_TARGET_EXTRACTOR(),
       STOCKOUT_QUOTA_BUYER_CV_EXTRACTOR(),
       offset:initialPrice, p:p,i:i,d:d,columnName:columnName);


  PIDAdaptive.StockoutQuotaBuyerFromDB(ParameterDatabase db, String containerPath):
  this.fromDB(STOCKOUT_QUOTA_BUYER_TARGET_EXTRACTOR(),
              STOCKOUT_QUOTA_BUYER_CV_EXTRACTOR(),
              db,containerPath);

  PIDAdaptive.FixedInflowBuyer({double flowTarget:1.0, double initialPrice: 0.0,
                               double p:
                               PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                               double i:
                               PIDController.DEFAULT_INTEGRAL_PARAMETER,
                               double d:
                               PIDController.DEFAULT_DERIVATIVE_PARAMETER,
                               String columnName: "pricer"}) :
  // controlled variable = -outflow the minuses to adapt the right way
  this(new FixedExtractor(flowTarget),
       new SimpleExtractor("inflow"),
       offset:initialPrice, p:p,i:i,d:d,columnName:columnName);

  PIDAdaptive.FixedInflowBuyerFromDB(ParameterDatabase db, String containerPath)
  :
  this.fromDB(new FixedExtractor(db.getAsNumber("$containerPath.flowTarget","$DB_ADDRESS.flowTarget")),
              new SimpleExtractor("inflow"),db,containerPath);

  //todo create DB version after the maximizer
  PIDAdaptive.MaximizerBuyer(SISOPlant plant, Firm firm, Random r,
                             {double initialPrice: 0.0,
                             double p:
                             PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                             double i:
                             PIDController.DEFAULT_INTEGRAL_PARAMETER,
                             double d:
                             PIDController.DEFAULT_DERIVATIVE_PARAMETER,
                             String columnName: "pricer"}) :
  // controlled variable = -outflow the minuses to adapt the right way
  this(new MarginalMaximizer.forHumanResources(plant,firm,r,1.0,1.0,1.0/21.0),
       new SimpleExtractor("inflow"),
       offset:initialPrice, p:p,i:i,d:d,columnName: columnName);

  //todo create DB version after the maximizer
  PIDAdaptive.PIDMaximizerBuyer(SISOPlant plant, Firm firm, Random r,
                                {double initialPrice: 0.0,
                                double p: PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                                double i: PIDController.DEFAULT_INTEGRAL_PARAMETER,
                                double d: PIDController.DEFAULT_DERIVATIVE_PARAMETER
                                ,int averagePIDPeriod : 20,
                                double piMultiplier : 100.0,
                                String columnName: "pricer"}) :
  // controlled variable = -outflow the minuses to adapt the right way
  this(new PIDMaximizer.ForHumanResources(plant,firm,r,averagePIDPeriod,piMultiplier,1.0),
       new SimpleExtractor("inflow"),
       offset:initialPrice, p:p,i:i,d:d,columnName:columnName);


  PIDAdaptive.FixedInventoryBuyer({double inventoryTarget:1.0,
                                  double initialPrice: 0.0,
                                  double p:
                                  PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                                  double i:
                                  PIDController.DEFAULT_INTEGRAL_PARAMETER,
                                  double d:
                                  PIDController.DEFAULT_DERIVATIVE_PARAMETER,
                                  String columnName: "pricer"
                                  }) :
  // controlled variable = -outflow the minuses to adapt the right way
  this(new FixedExtractor(inventoryTarget),
       new SimpleExtractor("inventory"),
       offset:initialPrice, p:p,i:i,d:d,columnName:columnName);

  PIDAdaptive.FixedInventoryBuyerFromDB(ParameterDatabase db, String containerPath)
  :
  this.fromDB(new FixedExtractor(db.getAsNumber("$containerPath.inventoryTarget","$DB_ADDRESS.inventoryTarget")),
              new SimpleExtractor("inventory"),db,containerPath);



  double get value => pid.manipulatedVariable;

  void adapt(Trader t,Data data) {

    if(_columnToSet)
    {
      data.addColumn("${columnName}_target",()=>this.lastTarget);
      data.addColumn("${columnName}_cv",()=>this.lastControlledVariable);
      _columnToSet = false;
    }


    lastTarget = targetExtractor.extract(data);
    lastControlledVariable = cvExtractor.extract(data);
    //ignore lack of data
    if(lastTarget == null || !lastTarget.isFinite
       || !lastControlledVariable.isFinite)
      return;
    pid.adjust(lastTarget, lastControlledVariable);


  }


}




/**
 * The behavior depends on the [_stockingUp] flag.
 * When [stockingUp] is true, then [_stockingUpExtractor] is used to get the
 * target.
 * Otherwise [targetExtractor] from the delegate is used.
 * It starts stockingUp and switch to normal only when inventory above
 * [optimalInventory]. It switches back from normal to stockingup
 * if inventory goes below [criticalInventory].
 */
class BufferInventoryAdaptive implements ControlStrategy
{

  static const  String DB_ADDRESS= "default.strategy.BufferInventoryAdaptive";


  /**
   * by default just target 0
   */
  static final Extractor defaultTargetWhenStockingUp = new FixedExtractor(0.0);



  Extractor targetExtractingStockingUp;

  Extractor originalTargetExtractor;

  /**
   * tells me how to check inventory levels
   */
  Extractor inventoryExtractor;



  final PIDAdaptive delegate;

  bool _stockingUp = true;

  double _optimalInventory;

  double _criticalInventory;

  BufferInventoryAdaptive(this.targetExtractingStockingUp,
                          this.inventoryExtractor,
                          this.delegate,
                          double optimalInventory,
                          double criticalInventory
                          )
  {
    assert(targetExtractingStockingUp != null);
    assert(inventoryExtractor != null);
    _optimalInventory = optimalInventory;
    _criticalInventory = criticalInventory;
    originalTargetExtractor = delegate.targetExtractor;
    assert(originalTargetExtractor != null);
    if( optimalInventory < 0 ||
        criticalInventory < 0 ||
        criticalInventory >=optimalInventory )
      throw new ArgumentError(
          "'inventory targets must >0 and critical<optimal");
  }


  BufferInventoryAdaptive.FromDB(Extractor targetExtractingStockingUp,
                                 Extractor inventoryExtractor,
                                 PIDAdaptive delegate,
                                 ParameterDatabase db, String containerPath)
  :this(targetExtractingStockingUp,inventoryExtractor,delegate,
        db.getAsNumber("$containerPath.optimalInventory","$DB_ADDRESS.optimalInventory"),
        db.getAsNumber("$containerPath.criticalInventory","$DB_ADDRESS.criticalInventory")
        );



  BufferInventoryAdaptive.simpleSeller({double offset:100.0,
                                       double optimalInventory:100.0,
                                       double criticalInventory:10.0,
                                       double p:
                                       PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                                       double i:
                                       PIDController.DEFAULT_INTEGRAL_PARAMETER,
                                       double d:
                                       PIDController.DEFAULT_DERIVATIVE_PARAMETER,
                                       String columnName: "pricer"}):
  this(
      defaultTargetWhenStockingUp,  new SimpleExtractor("inventory"),
      new PIDAdaptive.DefaultSeller(p:p,i:i,d:d, offset:offset,
                                    columnName:columnName),
      optimalInventory,
      criticalInventory);

  BufferInventoryAdaptive.SimpleSellerFromDB(
      ParameterDatabase db, String containerPath)
  :this.FromDB(defaultTargetWhenStockingUp,
               new SimpleExtractor("inventory"),
               new PIDAdaptive.DefaultSeller(p: db.getAsNumber("$containerPath.p","$DB_ADDRESS.p"),
                                             i:db.getAsNumber("$containerPath.i","$DB_ADDRESS.i"),
                                             d:db.getAsNumber("$containerPath.d","$DB_ADDRESS.d"),
                                             offset:db.getAsNumber("$containerPath.offset","$DB_ADDRESS.offset"),
                                             columnName:db.getAsString("$containerPath.columName","$DB_ADDRESS.columName"))
               ,db,containerPath);


  void _updateStockingFlag(Data data)
  {
    var inventory = inventoryExtractor.extract(data);

    //ignore lack of data
    if(inventory == null || !inventory.isFinite)
      return;

    if(_stockingUp) {
      if (inventory >= _optimalInventory)
      {
        _stockingUp = false;
      }
    }
    else
    {
      if (inventory < _criticalInventory)
      {
        _stockingUp = true;
      }
    }

  }


  adapt(Trader t,Data data)
  {
    _updateStockingFlag(data);
    if(_stockingUp)
      delegate.targetExtractor = targetExtractingStockingUp;
    else
      delegate.targetExtractor = originalTargetExtractor;

    if(delegate._columnToSet)
      data.addColumn("${delegate.columnName}_stockingup",
                         ()=>this._stockingUp ? 1.0 : 0.0);

    delegate.adapt(t,data);
  }









  /**
   * set the target extractor in case we aren't stocking up
   */
  set targetExtractor(Extractor e){
    delegate.targetExtractor = e;
    originalTargetExtractor = e;
  }

  Extractor get targetExtractor => originalTargetExtractor;
  Extractor get cvExtractor => delegate.cvExtractor;


  bool get stockingUp => _stockingUp;

  double get value=> delegate.value;

  double get optimalInventory => _optimalInventory;
  double get criticalInventory => _criticalInventory;

  set criticalInventory(double value)
  {
    _criticalInventory= value;
    if(_criticalInventory < 0 || _criticalInventory >= _optimalInventory)
      throw new ArgumentError(
          "'inventory targets must >0 and critical<optimal");
  }



  set optimalInventory(double value)
  {
    _optimalInventory = value;
    if(_criticalInventory >= _optimalInventory)
      throw new ArgumentError(
          "'inventory targets must >0 and critical<optimal");
  }

  double get lastTarget => delegate.lastTarget;

  double get lastControlledVariable=> delegate.lastControlledVariable;


}



