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

  //todo at some point we need to stream changes to curves

  //two maps, really a bimap: name <----> curves
  Map<String,ExogenousCurve> _curves = new Map();
  Map<ExogenousCurve,String> _names = new Map();



  void addCurve(ExogenousCurve curve, String name)
  {
    _curves[name]=curve;
    _names[curve]=name;
  }

  /**
   * get all the curves
   */
  Iterable<ExogenousCurve> get curves=> _curves.values;

  /**
   * get the name of a curve
   */
  String getName(ExogenousCurve curve) => _names[curve];


  List<List<double>> curveToPath(ExogenousCurve curve,
                                 double minPrice,
                                 double maxPrice,
                                 double minQuantity,
                                 double maxQuantity) =>
  getCurvePath(curve, minPrice,maxPrice,minQuantity,maxQuantity);








}
