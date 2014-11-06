/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.model;

/**
 * a class used by traders to adapt prices
 */
abstract class PricingStrategy
{

  /**
   * to call by the user, probably every day.
   */
  updatePrice(Data data);

  /**
   * the price per unit to charge for this strategy
   */
  double get price;


}

/**
 * a function that takes data and returns a single double,
 * usually a target or a controlled variable
 */
typedef double Extractor(Data data);

/**
 * a simple fixed extractor
 */
Extractor FixedExtractor(double i){
  return (data)=>i;
}

abstract class HasExtractor{
  Extractor get extractor;
}

/**
 * like an extractor, but settable from outside.
 */
class VariableExtractor implements HasExtractor{
  double out;

  VariableExtractor(this.out);

  Extractor get extractor=>(data)=>out;
}


/**
 * A PID pricer that simply tries to put inflow=outflow. In reality unless
 * stockouts are counted it can only work when decreasing prices
 * rather than increasing them, which is why we need inventory buffers
 */
class PIDPricing implements PricingStrategy
{

  /**
   * turn data into a double we use as target for PID
   */
  Extractor targetExtractor;




  /**
   * turn data into an observation of the current observation
   */
  Extractor cvExtractor;

  final PIDController pid;


  /**
   * constructor
   */
  PIDPricing(this.targetExtractor,this.cvExtractor,
             {double p: PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
             double i: PIDController.DEFAULT_INTEGRAL_PARAMETER,
             double d: PIDController.DEFAULT_DERIVATIVE_PARAMETER,
             double offset: 0.0}):
  pid = new PIDController(p,i,d){
    pid.offset = offset;
  }


  PIDPricing.DefaultSeller({double initialPrice: 0.0,
                           double p: PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                           double i: PIDController.DEFAULT_INTEGRAL_PARAMETER,
                           double d: PIDController.DEFAULT_DERIVATIVE_PARAMETER
                           }) : //target: -inflows,
  // controlled variable = -outflow the minuses to adapt the right way
  this((Data data)=> -data.getLatestObservation("inflow"),
      (Data data)=> -data.getLatestObservation("outflow"),
  offset:initialPrice, p:p,i:i,d:d);

  PIDPricing.FixedInflowBuyer({double flowTarget:1.0, double initialPrice: 0.0,
                           double p: PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                           double i: PIDController.DEFAULT_INTEGRAL_PARAMETER,
                           double d: PIDController.DEFAULT_DERIVATIVE_PARAMETER
                           }) :
  // controlled variable = -outflow the minuses to adapt the right way
  this(FixedExtractor(flowTarget),
      (Data data)=> data.getLatestObservation("inflow"),
  offset:initialPrice, p:p,i:i,d:d);

  PIDPricing.FixedInventoryBuyer({double inventoryTarget:1.0, double initialPrice: 0.0,
                              double p: PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                              double i: PIDController.DEFAULT_INTEGRAL_PARAMETER,
                              double d: PIDController.DEFAULT_DERIVATIVE_PARAMETER
                              }) :
  // controlled variable = -outflow the minuses to adapt the right way
  this(FixedExtractor(inventoryTarget),
      (Data data)=> data.getLatestObservation("inventory"),
  offset:initialPrice, p:p,i:i,d:d);


  double get price => pid.manipulatedVariable;

  void updatePrice(Data data) {

    double target = targetExtractor(data);
    double controlledVariable = cvExtractor(data);
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
class BufferInventoryPricing implements PricingStrategy
{


  /**
   * by default just target 0
   */
  static final Extractor defaultTargetWhenStockingUp = FixedExtractor(0.0);

  static final Extractor defaultInventoryExtractor = (Data data)=>
  data.getLatestObservation("inventory");

  Extractor targetExtractingStockingUp;

  Extractor _originalTargetExtractor;

  /**
   * tells me how to check inventory levels
   */
  Extractor inventoryExtractor;



  final PIDPricing delegate;

  bool _stockingUp = true;

  double _optimalInventory;

  double _criticalInventory;

  BufferInventoryPricing(this.targetExtractingStockingUp,
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
    _originalTargetExtractor = delegate.targetExtractor;
    assert(_originalTargetExtractor != null);
    if( optimalInventory < 0 ||
        criticalInventory < 0 ||
        criticalInventory >=optimalInventory )
      throw new ArgumentError(
          "'inventory targets must >0 and critical<optimal");
  }


  BufferInventoryPricing.simpleSeller({double initialPrice:100.0,
                                      double optimalInventory:100.0,
                                      double criticalInventory:10.0,
                                      double p:
                                      PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
                                      double i:
                                      PIDController.DEFAULT_INTEGRAL_PARAMETER,
                                      double d:
                                      PIDController.DEFAULT_DERIVATIVE_PARAMETER}):
  this(
      defaultTargetWhenStockingUp,defaultInventoryExtractor,
      new PIDPricing.DefaultSeller(p:p,i:i,d:d, initialPrice:initialPrice),
      optimalInventory:optimalInventory,
      criticalInventory:criticalInventory);


  void _updateStockingFlag(Data data)
  {
    var inventory = inventoryExtractor(data);

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


  updatePrice(Data data)
  {
    _updateStockingFlag(data);
    if(_stockingUp)
      delegate.targetExtractor = targetExtractingStockingUp;
    else
      delegate.targetExtractor = _originalTargetExtractor;

    delegate.updatePrice(data);
  }







  /**
   * set the target extractor in case we aren't stocking up
   */
  set targetExtractor(Extractor e){
    delegate.targetExtractor = e;
    _originalTargetExtractor = e;
  }

  Extractor get targetExtractor => _originalTargetExtractor;
  Extractor get cvExtractor => delegate.cvExtractor;


  bool get stockingUp => _stockingUp;

  double get price=> delegate.price;

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



