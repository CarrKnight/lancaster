/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

import 'package:lancaster/src/tools/AgentData.dart';
import 'package:lancaster/src/tools/PIDController.dart';

/**
 * a class used by traders to adapt prices
 */
abstract class PricingStrategy
{

  /**
   * to call by the user, probably every day.
   */
  updatePrice(AgentData data);

  /**
   * the price per unit to charge for this strategy
   */
  double get price;


}

typedef double Extractor(AgentData data);


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


  PIDPricing.DefaultSeller({double initialPrice: 0.0}) : //target: -inflows, controlled variable = -outflow the minuses to adapt the right way
  this((AgentData data)=> data.getLatestObservation("inflow"),
    (AgentData data)=> data.getLatestObservation("outflow"),offset:initialPrice);

  double get price => pid.manipulatedVariable;

  updatePrice(AgentData data) {

    pid.adjust(targetExtractor(data),cvExtractor(data));
  }


}