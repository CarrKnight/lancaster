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
class PIDAdaptive implements AdaptiveStrategy
{

  /**
   * turn data into a double we use as target for PID
   */
  Extractor targetExtractor;




  /**
   * turn data into an observation of the current observation
   */
  Extractor cvExtractor;

  Controller pid;


  /**
   * constructor
   */
  PIDAdaptive(this.targetExtractor,this.cvExtractor,
             {double p: PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
             double i: PIDController.DEFAULT_INTEGRAL_PARAMETER,
             double d: PIDController.DEFAULT_DERIVATIVE_PARAMETER,
             double offset: 0.0}):
  pid = new PIDController(p,i,d){
    pid.offset = offset;
  }


  PIDAdaptive.DefaultSeller({double initialPrice: 0.0,
                           double p: PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                           double i: PIDController.DEFAULT_INTEGRAL_PARAMETER,
                           double d: PIDController.DEFAULT_DERIVATIVE_PARAMETER
                           }) : //target: -inflows,
  // controlled variable = -outflow the minuses to adapt the right way
  this(new SimpleExtractor("inflow",(x)=>-x),
  new SimpleExtractor("outflow",(x)=>-x),
  offset:initialPrice, p:p,i:i,d:d);


  /**
   * pid seller that counts stockouts
   */
  PIDAdaptive.StockoutSeller({double initialPrice: 0.0,
                            double p: PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                            double i: PIDController.DEFAULT_INTEGRAL_PARAMETER,
                            double d: PIDController.DEFAULT_DERIVATIVE_PARAMETER
                            }) : //target: -inflows,
  // controlled variable = -outflow - stockouts
  this(new SimpleExtractor("inflow",(x)=>-x),
  new SumOfSimpleExtractors(["outflow","stockouts"],(x)=>-x),
  offset:initialPrice, p:p,i:i,d:d);

  /**
   * pid buyer that counts stockouts
   */
  PIDAdaptive.StockoutBuyer({double initialPrice: 0.0,
                             double p: PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                             double i: PIDController.DEFAULT_INTEGRAL_PARAMETER,
                             double d: PIDController.DEFAULT_DERIVATIVE_PARAMETER
                             }) : //target: -outflow,
  // controlled variable = -(inflow+stockouts)
  this(new SimpleExtractor("outflow",(x)=>-x),
  new SumOfSimpleExtractors(["inflow","stockouts"],(x)=>-x),
  offset:initialPrice, p:p,i:i,d:d);

  PIDAdaptive.FixedInflowBuyer({double flowTarget:1.0, double initialPrice: 0.0,
                              double p: PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                              double i: PIDController.DEFAULT_INTEGRAL_PARAMETER,
                              double d: PIDController.DEFAULT_DERIVATIVE_PARAMETER
                              }) :
  // controlled variable = -outflow the minuses to adapt the right way
  this(new FixedExtractor(flowTarget),
  new SimpleExtractor("inflow"),
  offset:initialPrice, p:p,i:i,d:d);

  PIDAdaptive.MaximizerBuyer(SISOPlant plant, Firm firm, Random r,
                            {double initialPrice: 0.0,
                            double p: PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                            double i: PIDController.DEFAULT_INTEGRAL_PARAMETER,
                            double d: PIDController.DEFAULT_DERIVATIVE_PARAMETER
                            }) :
  // controlled variable = -outflow the minuses to adapt the right way
  this(new MarginalMaximizer.forHumanResources(plant,firm,r),
  new SimpleExtractor("inflow"),
  offset:initialPrice, p:p,i:i,d:d);


  PIDAdaptive.PIDMaximizerBuyer(SISOPlant plant, Firm firm, Random r,
                             {double initialPrice: 0.0,
                             double p: PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                             double i: PIDController.DEFAULT_INTEGRAL_PARAMETER,
                             double d: PIDController.DEFAULT_DERIVATIVE_PARAMETER
                             ,int averagePIDPeriod : 20,
                             double piMultiplier : 10.0}) :
  // controlled variable = -outflow the minuses to adapt the right way
  this(new PIDMaximizer.ForHumanResources(plant,firm,r,averagePIDPeriod,piMultiplier),
  new SimpleExtractor("inflow"),
  offset:initialPrice, p:p,i:i,d:d);


  PIDAdaptive.FixedInventoryBuyer({double inventoryTarget:1.0, double initialPrice: 0.0,
                                 double p: PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                                 double i: PIDController.DEFAULT_INTEGRAL_PARAMETER,
                                 double d: PIDController.DEFAULT_DERIVATIVE_PARAMETER
                                 }) :
  // controlled variable = -outflow the minuses to adapt the right way
  this(new FixedExtractor(inventoryTarget),
  new SimpleExtractor("inventory"),
  offset:initialPrice, p:p,i:i,d:d);


  double get value => pid.manipulatedVariable;

  void adapt(Trader t,Data data) {

    double target = targetExtractor.extract(data);
    double controlledVariable = cvExtractor.extract(data);
    //ignore lack of data
    if(target == null || !target.isFinite || !controlledVariable.isFinite)
      return;
    pid.adjust(target, controlledVariable);
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
class BufferInventoryAdaptive implements AdaptiveStrategy
{


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
                         {double optimalInventory:100.0,
                         criticalInventory:10.0}
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


  BufferInventoryAdaptive.simpleSeller({double initialPrice:100.0,
                                      double optimalInventory:100.0,
                                      double criticalInventory:10.0,
                                      double p:
                                      PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                                      double i:
                                      PIDController.DEFAULT_INTEGRAL_PARAMETER,
                                      double d:
                                      PIDController.DEFAULT_DERIVATIVE_PARAMETER}):
  this(
      defaultTargetWhenStockingUp,  new SimpleExtractor("inventory"),
      new PIDAdaptive.DefaultSeller(p:p,i:i,d:d, initialPrice:initialPrice),
      optimalInventory:optimalInventory,
      criticalInventory:criticalInventory);


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


}



