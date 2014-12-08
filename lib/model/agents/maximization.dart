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
                                      double currentLevel,
                                      double deltaLevelUp,
                                      double deltaLevelDown,
                                      [double
                                      defaultReturn =
                                      double.INFINITY]){

  //cost expected now
  double priceNow = trader.predictPrice(0.0);
  double priceUp = trader.predictPrice(deltaLevelUp);
  double priceDown = trader.predictPrice(deltaLevelDown);

  //if you can't predict even no change price then give up
  if(priceNow.isNaN)
    return _EffectEstimate.NO_ESTIMATE;

  //compute totals
  double totalUp = priceUp*(currentLevel+deltaLevelUp);
  double totalNow = priceNow*(currentLevel);
  double totalDown = (-deltaLevelDown)>=currentLevel? 0.0 : priceDown*
  (currentLevel+deltaLevelDown);

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


  MarginalMaximizer();


  /**
   * build a marginal maximizer and set it to start when the firm starts.
   */
  factory MarginalMaximizer.forHumanResources(SISOPlant plant, Firm firm,
                                              Random r)
  {

    MarginalMaximizer toReturn = new MarginalMaximizer();
    firm.startWhenPossible((f,s)=> toReturn.start(s,f,r,plant));
    return toReturn;

  }

  /**
   * Basically try to find the new target
   */
  void updateTarget(Random random, Trader buyer,Trader seller,
                    SISOProductionFunction production, double input)
  {
    if(random.nextDouble()>updateProbability) //only act every now and then
      return;

    /**
        .o88b.  .d88b.  .d8888. d888888b
        d8P  Y8 .8P  Y8. 88'  YP `~~88~~'
        8P      88    88 `8bo.      88
        8b      88    88   `Y8b.    88
        Y8b  d8 `8b  d8' db   8D    88
        `Y88P'  `Y88P'  `8888Y'    YP
     */
    double consumption = production.consumption(currentTarget);
    double deltaConsumptionUp =
    production.consumption(currentTarget+delta) - consumption;
    double deltaConsumptionDown =
    production.consumption(currentTarget-delta) - consumption;

    var costs = computeMarginalEffect(buyer,consumption,deltaConsumptionUp,
    deltaConsumptionDown);
    //if there are no estimates, return
    if(identical(costs, _EffectEstimate.NO_ESTIMATE))
      return;

    /**
        d8888b. d88888b d8b   db d88888b d88888b d888888b d888888b
        88  `8D 88'     888o  88 88'     88'       `88'   `~~88~~'
        88oooY' 88ooooo 88V8o 88 88ooooo 88ooo      88       88
        88~~~b. 88~~~~~ 88 V8o88 88~~~~~ 88~~~      88       88
        88   8D 88.     88  V888 88.     88        .88.      88
        Y8888P' Y88888P VP   V8P Y88888P YP      Y888888P    YP
     */
    double ouput = production.production(currentTarget);
    double deltaOutputUp =
    production.production(currentTarget+delta) - ouput;
    double deltaOutputDown =
    production.production(currentTarget-delta) - ouput;

    var benefits = computeMarginalEffect(seller,ouput,deltaOutputUp ,
    deltaOutputDown,0.0);
    //if there are no estimates, return
    if(identical(benefits, _EffectEstimate.NO_ESTIMATE))
      return;

    /**
        d8888b. d88888b  .o88b. d888888b .d8888. d888888b  .d88b.  d8b   db
        88  `8D 88'     d8P  Y8   `88'   88'  YP   `88'   .8P  Y8. 888o  88
        88   88 88ooooo 8P         88    `8bo.      88    88    88 88V8o 88
        88   88 88~~~~~ 8b         88      `Y8b.    88    88    88 88 V8o88
        88  .8D 88.     Y8b  d8   .88.   db   8D   .88.   `8b  d8' 88  V888
        Y8888D' Y88888P  `Y88P' Y888888P `8888Y' Y888888P  `Y88P'  VP   V8P
     */
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

  void start(Schedule s, Firm firm, Random r, SISOPlant producer)
  {
    Trader seller = firm.salesDepartments[producer.outputType];
    Trader buyer = firm.purchasesDepartments[producer.inputType];

    s.scheduleRepeating(Phase.ADJUST_PRODUCTION,(s)=>updateTarget(r,buyer,
    seller,producer.function,seller.currentOutflow));
  }






  double extract(Data data) {
    return currentTarget;
  }


}


class PIDMaximizer implements Extractor
{

  final StickyPID pid;

  double currentTarget=1.0;

  double delta = 1.0;

  Transformer ratioTransformer = (x)=>x;


  double extract(Data data) {
    return currentTarget;
  }


  factory PIDMaximizer.ForHumanResources(SISOPlant plant, Firm firm,
                                         Random r,[int averagePIDPeriod = 20, double
      PImultiplier = 10.0])
  {

    PIDMaximizer toReturn = new PIDMaximizer(r,averagePIDPeriod,
    PImultiplier);
    firm.startWhenPossible((f,s)=> toReturn.start(s,f,plant));
    return toReturn;

  }


  PIDMaximizer(Random random,[int averagePIDPeriod = 20, double
  PImultiplier = 10.0]):
  pid = new StickyPID.Random(new PIDController.standardPI(),random,
  averagePIDPeriod)
  {
    pid.offset=currentTarget;
    (pid.delegate as PIDController).proportionalParameter *=PImultiplier;
    (pid.delegate as PIDController).integrativeParameter *=PImultiplier;
  }




  updateTarget(Trader buyer,Trader seller,
               SISOProductionFunction production, double input)
  {
    /***
     *       ___               ____ __
     *      / _ )___ ___  ___ / _(_) /____
     *     / _  / -_) _ \/ -_) _/ / __(_-<
     *    /____/\__/_//_/\__/_//_/\__/___/
     *
     */

    //new products at new price - old products at old prices
    var benefits = marginalBenefits(seller, production,input,delta);
    //so this is a little trick from somehwere. Numerical derivatives work
    // better when you have (f(x+h)-f(x-h))/2


    /***
     *      _________  ______________
     *     / ___/ __ \/ __/_  __/ __/
     *    / /__/ /_/ /\ \  / / _\ \
     *    \___/\____/___/ /_/ /___/
     *
     */

    //new inputs at new price - old inputs at old prices
    var costs = marginalCosts(buyer, production,input,delta);


    if(costs==0 || !costs.isFinite || !benefits.isFinite)
      return;

    pid.adjust(ratioTransformer(benefits/costs),1.0);
    currentTarget = pid.manipulatedVariable;
  }

  void start(Schedule s, Firm firm, SISOPlant producer)
  {
    Trader seller = firm.salesDepartments[producer.outputType];
    Trader buyer = firm.purchasesDepartments[producer.inputType];

    s.scheduleRepeating(Phase.ADJUST_PRODUCTION,(s)=>updateTarget(buyer,
    seller,producer.function,currentTarget));
  }




}
//return (float) (1f/(1+Math.exp(-(x- center)))) ;


/**
 * this is a facade/adapter of the PIDMaximizer, but instead of being an
 * extractor it really is a pricing strategy. This is handy for the Keynesian
 * short run model
 */
class PIDMaximizerFacade implements AdaptiveStrategy
{

  final PIDMaximizer delegate;


  final Firm firm;

  final SISOPlant plant;


  Trader seller = null;

  Trader buyer = null;


  PIDMaximizerFacade(this.delegate,this.firm,this.plant,
                     [double initialPrice=1.0])
  {
    delegate.pid.offset = initialPrice;
  }

  factory PIDMaximizerFacade.PricingFacade(SISOPlant plant, Firm firm,
                                           Random r,[double initialPrice=1.0,
      int averagePIDPeriod = 20, double
      PImultiplier = 10.0])
  {

    PIDMaximizer delegate = new PIDMaximizer(r,averagePIDPeriod,
    PImultiplier);
    //we are not going to start it, since we can call it from updatePrice
    delegate.ratioTransformer = (x)=>1/x;
    PIDMaximizerFacade facade = new PIDMaximizerFacade(delegate,
    firm,plant,initialPrice);
    return facade;

  }

  double get value=> delegate.currentTarget;


  //unused because the maximizer steps itself.
  adapt(Trader t, Data data) {
    if(seller == null)
      seller = firm.salesDepartments[plant.outputType];
    if(buyer == null)
      buyer = firm.purchasesDepartments[plant.inputType];

    delegate.updateTarget(buyer,seller,plant.function,(buyer as
    ZeroKnowledgeTrader).quoting.value);

  }


}


double sigmoid(double x, double center)=> (1.0/(1.0+exp(-(x- center)))) ;

double marginalBenefits(Trader seller, SISOProductionFunction production,
                        double input,double delta) {
  double benefits = seller.predictPrice(delta) * production.production
  (input + delta) - seller.predictPrice(-delta) * production
  .production(input - delta);
  benefits /= 2.0;
  return benefits;
}

double marginalCosts(Trader buyer, SISOProductionFunction production,
                     double input, double delta) {
  double costs = buyer.predictPrice(delta) * production.consumption
  (input + delta) - buyer.predictPrice(-delta) * production.consumption
  (input - delta) ;
  costs /= 2.0;
  return costs;
}