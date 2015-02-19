/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

import 'dart:io';

main(){

  Directory testDirectory =Directory.current;
  File defaultParameters = new File("${testDirectory.path}${Platform.pathSeparator}default.json");

  print(defaultParameters.readAsStringSync());
}