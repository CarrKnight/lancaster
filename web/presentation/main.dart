/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

import 'package:lancaster/view/lancaster_view_angularless.dart';
import 'dart:html';

main(){

  print("This is a test message. To remain tranquil in the face of almost certaint death, smooth jazz will be deployed in 3,2,1");

  //manualslider
  new SliderDemoGUI("#manualslider");

  //pislider
  new SliderDemoGUI.PID("#pislider");

  //slider_charts
  new ChartsDemoGUI.WithCharts("#slider_charts");

  //changeInDemand
  new ChartsDemoGUI.ChangeInDemand("#changeInDemand",resizeScale:0.8);

  //changeInEndowment
  new ChartsDemoGUI.ChangeInEndowment("#changeInEndowment",resizeScale:0.8);

  //fixed_target
  //profitslider
  var path = 'fixed_target.json';
  HttpRequest.getString(path)
  .then((String fileContents) {
    print(fileContents);
    new ProductionDemoGUI.DoubleBeveridge(fileContents,"#fixed_target");
    new ProductionDemoGUI.ExogenousProduction(fileContents,"#profitslider");

  })
  .catchError((Error error) {
    print(error.toString());
  });


  //profit_target
  path = 'profit_target.json';
  HttpRequest.getString(path)
  .then((String fileContents) {
    print(fileContents);
    new ProductionDemoGUI.DoubleBeveridge(fileContents,"#profit_target");
  })
  .catchError((Error error) {
    print(error.toString());
  });





  //keynesianExample

  //keynesianMacro

  //marshallianMacro

  path = 'marsh_macro.json';
  HttpRequest.getString(path)
  .then((String fileContents) {
    print(fileContents);
    new SupplyAndDemandGUI(fileContents,"#marshallianMacro");
  });


}