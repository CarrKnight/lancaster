/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.presentation;


List<List<double>> convertLinearCurveToPath(LinearCurve curve,
                                            double minPrice,
                                            double maxPrice,
                                            double minQuantity,
                                            double maxQuantity)
{

  //linear is easy, we just need two points
  double quantity1 =   (curve.intercept + curve.slope * minPrice );
  double quantity2 =   (curve.intercept + curve.slope * maxPrice );


  return [[quantity1,minPrice],[quantity2,maxPrice]];

}


List<List<double>> convertInfinitelyElasticToPath(InfinitelyElasticAsk curve,
                                                  double minPrice,
                                                  double maxPrice,
                                                  double minQuantity,
                                                  double maxQuantity)
{

  //horizontal, easy.
  return [[minQuantity,curve.minPrice],[maxQuantity,curve.minPrice]];

}



List<List<double>> convertFixedBudgetToPath(FixedBudget curve,
                                            double minPrice,
                                            double maxPrice,
                                            double minQuantity,
                                            double maxQuantity)
{

  //easy slope
  return [[curve.budget/minPrice,minPrice],[curve.budget/maxPrice,maxPrice]];

}


List<List<double>> convertFixedQuantityToPath(FixedSupply curve,
                                            double minPrice,
                                            double maxPrice,
                                            double minQuantity,
                                            double maxQuantity)
{

  //vertical easy
  return [[curve.dailyQuantity,minPrice],[curve.dailyQuantity,maxPrice]];

}



/**
 * converts curve into path for drawing
 */
List<List<double>> getCurvePath(ExogenousCurve curve,
                                double minPrice,
                                double maxPrice,
                                double minQuantity,
                                double maxQuantity)
{

  //just a big switch.
  //now, it would be nice to keep this somewhere in the curve itself; it
  // wouldn't be hard but I really want to keep this display code out of the
  // simulation itself

  if(curve is FixedBudget)
    return convertFixedBudgetToPath(curve,minPrice,maxPrice,minQuantity,
    maxQuantity);

  if(curve is InfinitelyElasticAsk)
    return convertInfinitelyElasticToPath(curve,minPrice,maxPrice,minQuantity,
    maxQuantity);

  if(curve is LinearCurve)
    return convertLinearCurveToPath(curve,minPrice,maxPrice,minQuantity,
    maxQuantity);

  if(curve is FixedSupply)
    return convertFixedQuantityToPath(curve,minPrice,maxPrice,minQuantity,
    maxQuantity);


  throw new Exception("unrecognized curve type!");


}
