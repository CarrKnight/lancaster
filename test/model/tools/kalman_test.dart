/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

library kalman.test;
import 'package:unittest/unittest.dart';
import 'package:lancaster/model/lancaster_model.dart';
import 'dart:io';
main(){


  test("unweighted regression",() {
    Directory resources = findResourceFolder();

    //first file to read
    File regression = new File("${resources.path}${Platform
    .pathSeparator}regression.csv");
    List<String> data = regression.readAsStringSync().split('\n');

    KalmanFilter filter = new KalmanFilter(2);
    //skip first line (header). Weights are all 1
    for (int i = 1; i < data.length;i++)
    {
      List<String> observation = data[i].trim().split(",");
      if(observation.length < 2) //empty
        continue;
      filter.addObservation(1.0,double.parse(observation[1]),[1.0,double.parse
      (observation[0])]);
    }

    print(filter.beta);
    //check coefficients
    expect(filter.beta[0],closeTo(0,.5));
    expect(filter.beta[1],closeTo(5,.1));

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