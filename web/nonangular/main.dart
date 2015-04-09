/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

import 'package:lancaster/view/lancaster_view_angularless.dart';
import 'dart:html';

void main() {


  //need to read the scenario json
  var path = 'default.json';
  HttpRequest.getString(path)
  .then((String fileContents) {
    print(fileContents);
    new ProductionDemoGUI.DoubleBeveridge(fileContents,"#sliderdemo");
    //only changes JSON when it comes to fixed production. Pretty cool!
  })
  .catchError((Error error) {
    print(error.toString());
  });



}