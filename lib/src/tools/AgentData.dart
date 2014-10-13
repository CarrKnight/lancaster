library tools.agentdata;

import 'package:lancaster/src/engine/schedule.dart';

import 'dart:math';


/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

/**
 * This is a port of the DataStorage.java
 * Basically a map String--->double storing end of the day observations + a step to update itself
 */
class AgentData
{

  //for each name a list of observations
  Map<String,List<double>> _dataMap;

  /**
   * the update step
   */
  Step _updateStep;


  AgentData(List<String> columns,Step updateStepBuilder(Map<String,List<double>> dataReferences)) {
    _dataMap = new Map();
    columns.forEach((col)=>_dataMap[col]=new List()); //add column names
    _updateStep = updateStepBuilder(_dataMap);
  }




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
   * makes sure all the variables have the same number of observations
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


}


