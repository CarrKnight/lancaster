part of lancaster.model;


/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

/**
 * This is a port of the DataStorage.java
 * Basically a map String--->double storing end of the day observations + a step to update itself
 */
class Data
{

  //for each name a list of observations
  Map<String,List<double>> _dataMap;

  /**
   * the update step
   */
  Step _updateStep;


  Data(List<String> columns,Step updateStepBuilder(Map<String,List<double>> dataReferences)) {
    _dataMap = new Map();
    columns.forEach((col)=>_dataMap[col]=new List()); //add column names
    _updateStep = updateStepBuilder(_dataMap);
  }





  Data.TraderData(Trader trader):
     this(["outflow","inflow","stockouts","closingPrice","offeredPrice",
     "inventory"],(data)=>(s){
       data["outflow"].add(trader.currentOutflow);
       data["inflow"].add(trader.currentInflow);
       data["stockouts"].add(trader.stockouts);
       data["closingPrice"].add(trader.lastClosingPrice);
       data["offeredPrice"].add(trader.lastOfferedPrice);
       data["inventory"].add(trader.good);
     });



  bool get  empty{
    //there are no columns or there are no rows in the first column
    return _dataMap.isEmpty || _dataMap.values.first.isEmpty;
  }


  bool _started = false;


  /**
   * schedules the update
   */
  void start(Schedule schedule){
    assert(!_started); //should really schedule it only once!
    _started = true;
    schedule.scheduleRepeating(Phase.CLEANUP,_updateStep);
  }


  /**
   * makes sure all the variables have the same doubleber of observations
   */
  bool _consistency(){
    int i =-1;
    for(List<double> observations in _dataMap.values)
    {
      if(i==-1)
        i=observations.length;
      if(i != observations.length)
        return false;
    }

    return true;
  }


  /**
   * returns latest observation or NaN if there is no other observation
   */
  double getLatestObservation(String key){
    assert( _consistency());
    return _dataMap[key].length > 0 ? _dataMap[key].last : double.NAN;
  }

  List<double> getObservations(String key){
    assert( _consistency());
    return _dataMap[key];
  }


  Step get updateStep => _updateStep;




}


/**
 * a function that takes data and returns a single double,
 * usually a target or a controlled variable
 */


abstract class Extractor{
  double extract(Data data);

}
typedef double ExtractFunction(double input);

class FunctionalExtractor implements Extractor
{
  final ExtractFunction function;

  FunctionalExtractor(this.function);

  extract(d)=>function(d);

}

/**
 * Extractor feeds the data of the user, but sometimes you need to act on
 * some other data. In which case use this. It feeds the [delegate] the
 * [trader] data.
 */
class OtherDataExtractor implements Extractor
{

  final Trader trader;

  final Extractor extractor;

  OtherDataExtractor(this.trader, this.extractor);

  double extract(Data data) =>extractor.extract(trader.data);



}



typedef double Transformer(double input);

/**
 * a simple "optimized" extractor. It stores a link to the observation list
 */
class SimpleExtractor implements Extractor
{


  final String columnName;

  List<double> column = null;

  Transformer transformer;



  SimpleExtractor(this.columnName,[this.transformer=null]){
    if(transformer==null)
      transformer= (x)=>x;
  }

  extract(Data data) {
    if(column == null) //if needed grab the column
      column = data.getObservations(columnName);

    //never poll the map once you have a reference to the list
    return column.length > 0 ? transformer(column.last) : double.NAN;
  }

}

/**
 * multiple "optimized" extractor. Sums up all the extractors. Transforms
 * each extractor separately before summing it
 */
class SumOfSimpleExtractors implements Extractor
{

  List<SimpleExtractor> extractors = new List();





  SumOfSimpleExtractors(List<String> columns,[Transformer transformer=null]){
    for(String column in columns)
      extractors.add(new SimpleExtractor(column,transformer));

  }

  extract(Data data) {

    double sum = 0.0;
    for(var extractor in extractors)
      sum+= extractor.extract(data);

    return sum;


  }

}



