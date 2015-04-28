/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.presentation;

/**
 * an adaptor, basically. Takes exogenous curves (most times at least) and
 * turn them into a series of x-y observations we can interpolate to draw
 */
abstract class CurvePath
{

  List<List<double>> toPath(num minY,num maxY, num minX, num maxX);

}




class LinearCurvePath implements CurvePath
{

  final LinearCurve curve;

  LinearCurvePath(this.curve);

  List<List<double>> toPath(num minY, num maxY, num minX,
                            num maxX) {

    //linear is easy, we just need two points
    num quantity1 =   (curve.intercept + curve.slope * minY );
    num quantity2 =   (curve.intercept + curve.slope * maxY );


    print("$quantity1 + $quantity2  ----- ${curve.intercept}, ${curve.slope}");
    return [[quantity1,minY],[quantity2,maxY]];
  }


}

class InfinitelyElasticPath implements CurvePath
{

  final InfinitelyElasticAsk curve;

  InfinitelyElasticPath(this.curve);

  List<List<double>> toPath(num minY, num maxY, num minX,
                            num maxX) {

    //horizontal, easy.
    return [[minX,curve.minPrice],[maxX,curve.minPrice]];
  }


}


class FixedBudgetPath implements CurvePath
{

  final FixedBudget curve;

  FixedBudgetPath(this.curve);

  //store here results so that i don't need to recompute this a million times
  num lastBudget = double.NAN;
  List<List<double>> lastData = [];

  List<List<double>> toPath(num minY, num maxY, num minX,
                            num maxX) {

    if(curve.initialBudget == lastBudget)
      return lastData;

    lastBudget = curve.initialBudget;
    lastData = [];
    //small increments of y
    for(num i =0.00; i<= 1; i+=.01)
    {
      num y = minY*(i)+maxY*(1.0-i);
      if(y != 0)
        lastData.add([lastBudget/y,y]);

    }



    print("fixedBudget: ${curve.budget} Lastdata: $lastData");

    return lastData;
  }


}



class FixedSupplyPath implements CurvePath
{

  final FixedSupply curve;

  FixedSupplyPath(this.curve);

  List<List<double>> toPath(num minY, num maxY, num minX,
                            num maxX) {

    //vertical easy
    return [[curve.dailyQuantity,minY],[curve.dailyQuantity,maxY]];
  }


}




class DynamicHorizontalPath implements CurvePath
{

  final DataGatherer yGetter;

  DynamicHorizontalPath(this.yGetter);

  List<List<double>> toPath(num minY, num maxY, num minX,
                            num maxX) {
    num y = yGetter();
    return [[minX,y],[maxX,y]];

  }

}


class DynamicVerticalPath implements CurvePath
{

  final DataGatherer xGetter;

  DynamicVerticalPath(this.xGetter);

  List<List<double>> toPath(num minY, num maxY, num minX,
                            num maxX) {
    num x = xGetter();
    return [[x, minY],[x,maxY]];

  }

}



typedef double DoubleGetter();
/**
 * basically this production function:
 *          b
    a  *  L  - c
 * into MC curve/supply chain
 */
class ExponentialMarginalCostPath implements CurvePath
{
  num a = double.NAN;
  num b = double.NAN;
  num c = double.NAN;
  num wage = double.NAN;

  final DoubleGetter wageGetter;
  final ExponentialProductionFunction production;


  ExponentialMarginalCostPath(this.wageGetter,this.production);

  List<List<double>> oldPath;

  List<List<double>> toPath(num minY, num maxY, num minX,
                            num maxX)
  {
    if(oldPath != null)
    {
      assert(a.isFinite); assert(b.isFinite); assert(c.isFinite); assert(wage.isFinite);
      //if anything has changed
      if(wage!=wageGetter() || a != production.multiplier || b !=production.exponent || c != -production.freebie )
      {
        oldPath = null;
        return toPath(minY,maxY,minX,maxX); //start over
      }
      else
      {
        return oldPath; //nothing has changed return the old stuff
      }
    }
    /* the MC is just:
        /c + q\1 / b
        |-----|
        \  a  /
        -------------
          b c + b q
     */
    //there is no old path
    a= production.multiplier; b=production.exponent; c = -production.freebie; wage = wageGetter();
    assert(oldPath == null);
    //now draw
    oldPath = [];
    for(double quantity = minX; quantity<maxX; quantity+=(maxX-minX)/100)
    {
      oldPath.add([quantity,_marginal(quantity) ]);
    }

    return oldPath;

  }


  double _marginal(double quantity)
  {
    return pow((c+quantity)/a,1.0/b) / (b * c + b * quantity);
  }

}