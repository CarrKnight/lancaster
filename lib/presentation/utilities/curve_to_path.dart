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

  List<List<double>> toPath(double minY,double maxY, double minX, double maxX);

}


class LinearCurvePath implements CurvePath
{

  final LinearCurve curve;

  LinearCurvePath(this.curve);

  List<List<double>> toPath(double minY, double maxY, double minX,
                            double maxX) {

    //linear is easy, we just need two points
    double quantity1 =   (curve.intercept + curve.slope * minY );
    double quantity2 =   (curve.intercept + curve.slope * maxY );


    return [[quantity1,minY],[quantity2,maxY]];
  }


}

class InfinitelyElasticPath implements CurvePath
{

  final InfinitelyElasticAsk curve;

  InfinitelyElasticPath(this.curve);

  List<List<double>> toPath(double minY, double maxY, double minX,
                            double maxX) {

    //horizontal, easy.
    return [[minX,curve.minPrice],[maxX,curve.minPrice]];
  }


}


class FixedBudgetPath implements CurvePath
{

  final FixedBudget curve;

  FixedBudgetPath(this.curve);

  //store here results so that i don't need to recompute this a million times
  double lastBudget = double.NAN;
  List<List<double>> lastData = [];

  List<List<double>> toPath(double minY, double maxY, double minX,
                            double maxX) {

    if(curve.budget == lastBudget)
      return lastData;

    lastBudget = curve.budget;
    lastData = [];
    for(double i =0.0; i<= 1.0; i+=.05)
    {
      double y = minY*(i)+maxY*(1.0-i);
      if(y != 0)
        lastData.add([lastBudget/y,y]);

    }

    //easy slope
    return lastData;
  }


}



class FixedSupplyPath implements CurvePath
{

  final FixedSupply curve;

  FixedSupplyPath(this.curve);

  List<List<double>> toPath(double minY, double maxY, double minX,
                            double maxX) {

    //vertical easy
    return [[curve.dailyQuantity,minY],[curve.dailyQuantity,maxY]];
  }


}




class DynamicHorizontalPath implements CurvePath
{

  final DataGatherer yGetter;

  DynamicHorizontalPath(this.yGetter);

  List<List<double>> toPath(double minY, double maxY, double minX,
                            double maxX) {
    double y = yGetter();
    return [[minX,y],[maxX,y]];

  }

}


class DynamicVerticalPath implements CurvePath
{

  final DataGatherer xGetter;

  DynamicVerticalPath(this.xGetter);

  List<List<double>> toPath(double minY, double maxY, double minX,
                            double maxX) {
    double x = xGetter();
    return [[x, minY],[x,maxY]];

  }

}
