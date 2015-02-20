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

  /**
   * where the observation is actually stored
   */
  Map<String,List<double>> _dataMap;

  /**
   * basically you might want to add columns over time, when you do add one
   * supply a gather that gets called at the end of the day to record it for
   * posterity
   */
  Map<String,DataGatherer> pluginGatherers = new HashMap();

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
  this(["outflow","inflow","stockouts","quota","closingPrice","offeredPrice",
  "inventory"],(data)=>(s){
    data["outflow"].add(trader.currentOutflow);
    data["inflow"].add(trader.currentInflow);
    data["stockouts"].add(trader.stockouts);
    data["quota"].add(trader.quota);
    data["closingPrice"].add(trader.lastClosingPrice);
    data["offeredPrice"].add(trader.lastOfferedPrice);
    data["inventory"].add(trader.good);
  });


  Data.MarketData(Market market):
  this(["price","quantity","seller_inflow","buyer_outflow"],(data)=>(s){
    data["price"].add(market.averageClosingPrice);
    data["quantity"].add(market.quantityTraded);
    data["seller_inflow"].add(market.sellersInflow);
    data["buyer_outflow"].add(market.buyersOutflow);
  });


  Data.AdaptiveStrategyData(ControlStrategy strategy):
  this(["target","cv","mv"],(data)=>(s){
    data["target"].add(strategy.lastTarget);
    data["cv"].add(strategy.lastControlledVariable);
    data["mv"].add(strategy.value);
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
    schedule.scheduleRepeating(Phase.CLEANUP,(s){
      _updateStep(s);
      //also plugin gatherers
      pluginGatherers.forEach((name,gatherer)=>_dataMap[name].add(gatherer()));
    });
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
  num getLatestObservation(String key){
    assert( _consistency());
    var column = _dataMap[key];
    if(column == null)
      return double.NAN;
    return column.length > 0 ? column.last : double.NAN;
  }

  List<double> getObservations(String key){
    assert( _consistency());
    return _dataMap[key];
  }


  Step get updateStep => _updateStep;



  Map<String,List<double>> get backingMap => _dataMap;


  /**
   * add an additional column on the spot. The column [name] must be unique
   * and not already used by something else. [dg] is called at data-gathering
   * time together with the other variables collected. If this is called
   * after some days have passed, the column gets filled with enough [filler]
   * to have equal length as the other columns
   */
  void addColumn(String name, DataGatherer dg, [num filler=double.NAN])
  {
    int rows = _dataMap.length == 0 ? 0 : _dataMap.values.first.length;

    if(_dataMap[name]!= null)
      throw new Exception("$name column already exists, use subsitute!");
    //create new column
    List<double> column = new List.generate(rows,(i)=>filler,growable:true);
    //plug it in
    _dataMap[name] = column;
    //register data gatherer
    pluginGatherers[name]=dg;
  }




}


/**
 * a function that takes data and returns a single double,
 * usually a target or a controlled variable
 */


abstract class Extractor{
  num extract(Data data);

}
typedef num ExtractFunction(num input);

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

  num extract(Data data) =>extractor.extract(trader.data);



}



typedef num Transformer(num input);

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
 * very easy function with no argument returning gatherer
 */
typedef  num DataGatherer();


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

    num sum = 0.0;
    for(var extractor in extractors)
      sum+= extractor.extract(data);

    return sum;


  }

}



