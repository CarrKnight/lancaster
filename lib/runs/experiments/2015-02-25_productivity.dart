/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

library experiments.overshoot;

import '2015-02-08 convergenceSpeed.dart';
import 'package:lancaster/model/lancaster_model.dart';
import 'dart:math';
import 'dart:io';
import 'package:test/test.dart';
import '../yackm.dart';


main()
{

  String timeStamp = new DateTime.now().toString();

  //increase productivity of the labor force
  for (int i = 0; i < 100; i++)
  {
    print("$i");
    var directory = ["docs", "yackm", "rawdata", "pi productivity shock${timeStamp}"];
    fixedWageMacro("keynesian.json", pathToJsonFromProjectRoot: ["bin"],
                   additionalJSonFiles : ["shock.experiment.json"],
                   testing:false,
                   outputPath: directory,
                   gasCsvName: "${i}_sales_productive.csv",
                   laborCsvName: "${i}_hr_productive.csv",
                   totalSteps:20000, shockDay:10000, endShockDay:-1, shockSize:-0.2,
                   dateDirectory:false, seed : i, //fix the seed!
                   //increase PI parameter in lieu of speed
                   shockEffects : (OneMarketCompetition scenario,model)
                   {
                     (scenario.firms.first.plants.first.function as ExponentialProductionFunction).multiplier =
                     0.6;
                   });

    fixedWageMacro("keynesian.json", pathToJsonFromProjectRoot: ["bin"],
                   additionalJSonFiles : ["shock.experiment.json"],
                   testing:false,
                   outputPath: directory,
                   gasCsvName: "${i}_sales.csv",
                   laborCsvName: "${i}_hr.csv.csv",
                   totalSteps:20000, shockDay:10000, endShockDay:-1, shockSize:-0.2,
                   dateDirectory:false,seed : i);


  }


}