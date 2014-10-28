/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

import 'package:lancaster/view/lancaster_view.dart';
import 'package:angular/angular.dart';
import 'package:angular/application_factory.dart';

class LancasterModule extends Module{
  LancasterModule() {
    bind(ModelGUI);
    bind(ControlBar);
  }
}

void main(){
  applicationFactory().addModule(new LancasterModule()).run();

}