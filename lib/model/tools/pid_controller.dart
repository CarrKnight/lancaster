part of lancaster.model;

/**
 * A simple PID controller, never lets MV go negative, doesn't allow negative parameters, has windup-stop enabled
 */
class PIDController {


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
  void adjust(double target, double controlledVariable)
  {
    assert(target.isFinite);
    assert(controlledVariable.isFinite);

    double residual = invertSign ? controlledVariable-target : target-controlledVariable;
    assert(residual.isFinite);
    _previousError = _currentError;
    _currentError = residual;
    _sumOfErrors += _currentError;

    //PID FORMULA
    double newMV = offset +
          proportionalParameter * _currentError +
          integrativeParameter * _sumOfErrors;
    if(_previousError.isFinite)
      newMV += derivativeParameter * (_currentError - _previousError);

    //if newMV is <0, windup stop!
    if(newMV < 0) {
      if (integrativeParameter != 0) //if the i is not 0
        _sumOfErrors = _sumOfErrorsNeededForFormulaToBe0();
      newMV = 0.0;
    }

    //done!
    _manipulatedVariable = newMV;

  }



  double _sumOfErrorsNeededForFormulaToBe0(){
    double numerator = 0 - offset - (proportionalParameter * _currentError);
    if(_previousError.isFinite)
      numerator-= derivativeParameter * (_currentError-_previousError);
    return numerator/integrativeParameter;
  }

}
