part of lancaster.model;


abstract class Controller
{
  set offset(double value);

  double get offset;

  double get manipulatedVariable;

  /**
   * "step" the controller to change the manipulated variable
   */
  void adjust(double target, double controlledVariable);

}

/**
 * A simple PID controller, never lets MV go negative, doesn't allow negative parameters, has windup-stop enabled
 */
class PIDController implements Controller {


  static const  double DEFAULT_PROPORTIONAL_PARAMETER = .1;
  static const  double DEFAULT_INTEGRAL_PARAMETER = .1;
  static const  double DEFAULT_DERIVATIVE_PARAMETER = 0.0;

  /**
   * the a of the discrete PID controller
   */
  double proportionalParameter;

  /**
   * the b of the discrete PID controller
   */
  double integrativeParameter;

  /**
   * the c of the discrete PID controller
   */
  double derivativeParameter;

  /**
   * offset + PID formula
   */
  double _manipulatedVariable = 0.0;

  /**
   * the offset: if the pid formula is 0 the MV is the offset
   */
  double _offset = 0.0;

  /**
   * when this is set to true the residual is -target+controlledVariable
   */
  bool invertSign = false;

  /**
   * the last residual
   */
  double _currentError =double.NAN;

  /**
   * the residual before last
   */
  double _previousError = double.NAN;

  double _sumOfErrors = 0.0;

  PIDController.standardPI():
  this(PIDController.DEFAULT_PROPORTIONAL_PARAMETER,
  PIDController.DEFAULT_INTEGRAL_PARAMETER,
  PIDController.DEFAULT_DERIVATIVE_PARAMETER
  );

  PIDController(this.proportionalParameter, this.integrativeParameter, this.derivativeParameter);

  set offset(double value){_offset=max(0.0,value);
  _manipulatedVariable = _offset;
  }

  get offset=> _offset;

  get manipulatedVariable=>((_manipulatedVariable*100.0).roundToDouble()/100.0); //always round to second decimal.


  /**
   * "step" the PID controller. A new CV is computed
   */
  updateMV() {
//PID FORMULA
    double newMV = offset +
    proportionalParameter * _currentError +
    integrativeParameter * _sumOfErrors;
    if (_previousError.isFinite)
      newMV += derivativeParameter * (_currentError - _previousError);

    //if newMV is <0, windup stop!
    if (newMV < 0) {
      if (integrativeParameter != 0) //if the i is not 0
        _sumOfErrors = _sumOfErrorsNeededForFormulaToBe0();
      newMV = 0.0;
    }

    //done!
    _manipulatedVariable = newMV;
  }

  void adjust(double target, double controlledVariable)
  {
    //compute error
    assert(target.isFinite);
    assert(controlledVariable.isFinite);

    double residual = invertSign ? controlledVariable-target : target-controlledVariable;
    assert(residual.isFinite);
    _previousError = _currentError;
    _currentError = residual;
    _sumOfErrors += _currentError;

    //now use the error to update the manipulated vaiable
    updateMV();

  }



  double _sumOfErrorsNeededForFormulaToBe0(){
    double numerator = 0 - offset - (proportionalParameter * _currentError);
    if(_previousError.isFinite)
      numerator-= derivativeParameter * (_currentError-_previousError);
    return numerator/integrativeParameter;
  }

  void changeSumOfErrorsSoOutputIsX(double x){
    double numerator = x - offset - (proportionalParameter * _currentError);
    if(_previousError.isFinite)
      numerator-= derivativeParameter * (_currentError-_previousError);
    _sumOfErrors =  numerator/integrativeParameter;
    updateMV();

  }

}


/**
 * A PID controller decorator to step the controller only every x days
 * ( possibly randomly) to slow it down a bit
 */
class StickyPID implements Controller
{
  final Controller delegate;

  /**
   * function called every day to decide whether to adjust or not the
   * manipulated variable. By default it always act
   */
  var _adjustToday = ()=>true;

  bool adjustedLast = false;

  StickyPID(this.delegate,bool adjustmentChecker())
  {
    _adjustToday = adjustmentChecker;
  }

  /**
   * pid controller with same fixed probability of acting every day, the
   * probability is 1/(1+[decisionPeriod]).
   */
  factory StickyPID.Random(Controller delegate, Random r, int
  decisionPeriod)
  {
    double probability = 1.0/(1.0 + decisionPeriod.toDouble());
    return new StickyPID(delegate,()=> r.nextDouble() < probability);
  }

  /**
   * The delegate will adjust precisely every [decisionPeriod] days
   */
  factory StickyPID.Fixed(Controller delegate, int decisionPeriod)
  {
    int counter = 0;
    var adjustmentChecker=(){
      counter++;
      if(counter == decisionPeriod)
      {
        counter = 0;
        return true;
      }
      return false;
    };
    return new StickyPID(delegate,adjustmentChecker);
  }


  set adjustToday( bool dailyCheck()) => _adjustToday = dailyCheck;
  Function get adjustToday => _adjustToday;


  set offset(double value)=> delegate.offset=value;
  get offset=>delegate.offset;

  get manipulatedVariable=>delegate.manipulatedVariable;

  void adjust(double target, double controlledVariable) {
    adjustedLast = _adjustToday();
    if (adjustedLast)
      delegate.adjust(target, controlledVariable);
  }


}

/**
 * basically never let the manipulated variable go above
 */
class WindupStopFromAbove implements Controller
{
  final PIDController delegate;

  /**
   * a function of target and controlled variable
   */
  final Function maximumValue;


  WindupStopFromAbove(this.delegate, this.maximumValue);

  set offset(double value)=>delegate.offset=value;

  double get offset => delegate.offset;

  double get manipulatedVariable=>delegate.manipulatedVariable;

  void adjust(double target, double controlledVariable) {

    delegate.adjust(target,controlledVariable);
    double maximum = maximumValue(target,controlledVariable);
    if(delegate.manipulatedVariable > maximum +1 ) {
      delegate.changeSumOfErrorsSoOutputIsX(maximum);
  //    print("${delegate.manipulatedVariable} <----> $maximum");
      assert((delegate.manipulatedVariable - maximum).abs()<.01);
    }



  }


}