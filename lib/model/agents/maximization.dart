/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.model;

class _EffectEstimate{

  final double marginalEffectUp;

  final double marginalEffectDown;

  final double totalUp;

  final double totalDown;

  final double totalNow;

  _EffectEstimate(this.marginalEffectUp, this.marginalEffectDown, this.totalUp,
                  this.totalDown, this.totalNow);

  static final NO_ESTIMATE = new
  _EffectEstimate(double.NAN,double.NAN,double.NAN,double.NAN,double.NAN);

}

/**
 * compute marginal benefits and costs.
 */
_EffectEstimate computeMarginalEffect(Trader trader,
                                  double currentInputLevel,
                                  double deltaInput, [double defaultReturn =
    double.INFINITY]){

  //cost expected now
  double priceNow = trader.predictPrice(0.0);
  double priceUp = trader.predictPrice(deltaInput);
  double priceDown = trader.predictPrice(-deltaInput);

  //if you can't predict even no change price then give up
  if(priceNow.isNaN)
    return _EffectEstimate.NO_ESTIMATE;

  //compute totals
  double totalUp = priceUp*(currentInputLevel+deltaInput);
  double totalNow = priceNow*(currentInputLevel);
  double totalDown = deltaInput>=currentInputLevel? 0 : priceDown*
  (currentInputLevel-deltaInput);

  //compute marginals, use infinity if the total  is not finite
  assert(totalNow.isFinite); //we wouldn't be here otherwise
  double marginalUp = totalUp.isFinite ? totalUp - totalNow :  defaultReturn;
  double marginalDown = totalDown.isFinite ? totalDown - totalNow :
  defaultReturn;


  return new _EffectEstimate(marginalUp,marginalDown,totalUp,totalDown,
  totalNow);
}

/**
 * this is a target extractor for purchase departments that buy inputs. It
 * periodically schedules itself to check current marginal benefits and costs
 * of increasing production. Because production is exclusively a function of
 * inputs consumed (as of now) this drives production.
 */
class MarginalMaximizer implements Extractor
{



  double currentTarget=1.0;

  double delta = 1.0;


  double updateProbability = 1.0/21.0; //a poor man's way of stepping every
  // now and then. This has average 20 (negative binomial)


  /**
   * Basically try to find the new target
   */
  void updateTarget(Random random, Trader buyer,Trader seller,
  SISOProductionFunction production, double currentValue)
  {
   if(random.nextDouble()>updateProbability) //only act every now and then
     return;

    var costs = computeMarginalEffect(buyer,currentTarget,delta);
    var benefits = computeMarginalEffect(seller,production.production
    (currentTarget), production.multiplier*delta,0.0);


    double marginalProfitUp = benefits.marginalEffectUp-costs.marginalEffectUp;
    double marginalProfitDown = benefits.marginalEffectDown-costs
    .marginalEffectDown;

    //if going either way lowers our profits, don't do it
    if(marginalProfitUp<= 0 && marginalProfitDown <= 0)
      return;
    if(marginalProfitUp>=marginalProfitDown)
      currentTarget += delta;
    else
      currentTarget -=delta;

    assert(currentTarget>=0);

  }

//todo this requires a firm or something
  void start(Schedule s, Trader buyer, Trader seller, Random r,
             SISOProductionFunction production){
    s.scheduleRepeating(Phase.ADJUST_PRODUCTION,(s)=>updateTarget(r,buyer,
    seller,production,seller.currentOutflow));
  }

  double extract(Data data) {
    return currentTarget;
  }


}