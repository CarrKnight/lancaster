/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.presentation;

/**
 * a simple component holding curves for a market presentation so that its
 * view can draw it
 */
class CurveRepository
{

  //two maps, really a bimap: name <----> curves
  Map<String,CurvePath> _curves = new Map();
  Map<CurvePath,String> _names = new Map();



  void addCurve(ExogenousCurve curve, String name)
  {
    CurvePath path = _getCurvePath(curve);
    _curves[name]=path;
    _names[path]=name;
  }

  void addCurvePath(CurvePath path, String name)
  {
    _curves[name]=path;
    _names[path]=name;
  }


  void addDynamicHLine(DataGatherer yGetter, String name)
  {
    CurvePath path = new DynamicHorizontalPath(yGetter);
    _curves[name]=path;
    _names[path]=name;
  }
  void addDynamicVLine(DataGatherer xGetter, String name)
  {
    CurvePath path = new DynamicVerticalPath(xGetter);
    _curves[name]=path;
    _names[path]=name;
  }

  /**
   * get all the curves
   */
  Iterable<CurvePath> get curves=> _curves.values;

  /**
   * get the name of a curve
   */
  String getName(CurvePath curve) => _names[curve];








  /**
   * basically a factory that instantiates a CurvePath appropriate to the
   * ExogenousCurve given.
   */
  CurvePath _getCurvePath(ExogenousCurve curve)
  {

    //just a big switch.
    //now, it would be nice to keep this somewhere in the curve itself; it
    // wouldn't be hard but I really want to keep this display code out of the
    // simulation itself

    if(curve is FixedBudget)
      return new FixedBudgetPath(curve);

    if(curve is InfinitelyElasticAsk)
      return new InfinitelyElasticPath(curve);

    if(curve is LinearCurve)
      return new LinearCurvePath(curve);


    if(curve is FixedSupply)
      return new FixedSupplyPath(curve);



    throw new Exception("unrecognized curve type!");


  }




}
