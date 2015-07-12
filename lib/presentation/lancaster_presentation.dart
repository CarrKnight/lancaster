/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */


/**
 * the presentation basically holds all the GUI routines but no visual/html
 * object
 */
library lancaster.presentation;


import 'dart:async';
import 'package:lancaster/model/lancaster_model.dart';
import 'dart:collection';
import 'dart:math';
import 'package:observe/src/to_observable.dart';
import 'package:observe/src/change_record.dart';

part 'market_presentation.dart';
part 'model_presentation.dart';
part 'zk_presentation.dart';
part 'presentations.dart';
part 'utilities/curve_to_path.dart';
part 'utilities/curves_repository.dart';