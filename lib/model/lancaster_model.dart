/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

library lancaster.model;

import 'dart:collection';
import 'dart:math';
import 'dart:async';
import 'dart:mirrors';
import 'package:json_object/json_object.dart';
import 'dart:convert';
import 'package:observe/src/to_observable.dart';
import 'package:observe/src/observable_map.dart';


/***
 *     ____  __ _   ___  __  __ _  ____
 *    (  __)(  ( \ / __)(  )(  ( \(  __)
 *     ) _) /    /( (_ \ )( /    / ) _)
 *    (____)\_)__) \___/(__)\_)__)(____)
 */


part 'engine/schedule.dart';
part 'engine/model.dart';
part 'engine/onemarket_scenario.dart';
part 'engine/parameter_database.dart';
part 'engine/number_generator.dart';

/***
 *      __    ___  ____  __ _  ____  ____
 *     / _\  / __)(  __)(  ( \(_  _)/ ___)
 *    /    \( (_ \ ) _) /    /  )(  \___ \
 *    \_/\_/ \___/(____)\_)__) (__) (____/
 */
part 'agents/pricing.dart';
part 'agents/trader.dart';
part 'agents/production.dart';
part 'agents/prediction.dart';
part 'agents/quotas.dart';
part 'agents/maximization.dart';
part 'agents/firm.dart';
part 'agents/geography';
/***
 *     _  _   __   ____  __ _  ____  ____  ____
 *    ( \/ ) / _\ (  _ \(  / )(  __)(_  _)/ ___)
 *    / \/ \/    \ )   / )  (  ) _)   )(  \___ \
 *    \_)(_/\_/\_/(__\_)(__\_)(____) (__) (____/
 */
part 'market/markets.dart';
part 'market/curves.dart';

/***
 *     ____  __    __   __    ____
 *    (_  _)/  \  /  \ (  )  / ___)
 *      )( (  O )(  O )/ (_/\\___ \
 *     (__) \__/  \__/ \____/(____/
 */
part 'tools/agent_data.dart';
part 'tools/inventory.dart';
part 'tools/kalman.dart';
part 'tools/pid_controller.dart';