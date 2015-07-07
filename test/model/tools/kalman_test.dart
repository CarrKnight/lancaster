/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

library kalman.test;
import 'package:test/test.dart';
import 'package:lancaster/model/lancaster_model.dart';
import 'dart:io';

feedRegressionToFilter(String fileName, KalmanFilter filter) {
  Directory resources = findResourceFolder();
  //first file to read
  File regression = new File("${resources.path}${Platform
  .pathSeparator}$fileName");
  List<String> data = regression.readAsStringSync().split('\n');

  //skip first line (header). Weights are all 1
  for (int i = 1; i < data.length;i++) {
    List<String> observation = data[i].trim().split(",");
    if (observation.length < 2) //empty
      continue;
    filter.addObservation(1.0, double.parse(observation[1]), [1.0, double.parse
    (observation[0])]);
  }
}

main(){


  test("unweighted regression",() {

    KalmanFilter filter = new KalmanFilter(2);
    filter.forgettingFactor=1.0; //no forgetting
    //y = 5x
    feedRegressionToFilter( "regression.csv", filter);

    print(filter.beta);
    //check coefficients
    expect(filter.beta[0],closeTo(0,.5));
    expect(filter.beta[1],closeTo(5,.1));

  });


  //todo tracks the slope okay, but not the intercept
  test("forgetting regression",() {
    //feed it two regressions, should forget one and get the other, eventually
    KalmanFilter filter = new KalmanFilter(2);
    filter.forgettingFactor=.99;
    filter.maxTraceToStopForgetting=10.0;

    //y=5x
    feedRegressionToFilter( "regression.csv", filter);

    print(filter.beta);
    //check coefficients
    expect(filter.beta[1],closeTo(5,.1));

    //second regression
    feedRegressionToFilter("regression2.csv", filter);

    print(filter.beta);
    //check coefficients
    expect(filter.beta[1],closeTo(1.5,.1));
  });

}


Directory findResourceFolder()
{
/*  Directory.current.list().listen((entity){
    print(entity);});
    */
  var current = Directory.current;

  // List directory contents, recursing into sub-directories,
  // but not following symbolic links.
  bool containPub = false;
  while(!containPub)
  {
    //search for pubspec.yaml
    List<FileSystemEntity> elements = current.listSync();
    for(FileSystemEntity e in elements)
      if(e.path == "${current.path}${Platform.pathSeparator}pubspec.yaml") {
        containPub = true;
        break;
      }
    if(!containPub)
      current = current.parent;
  }

  return new Directory("${current.path}${Platform.pathSeparator}test${Platform
  .pathSeparator}testresources");
}