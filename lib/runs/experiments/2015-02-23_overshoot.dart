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


/**
 * Just run the macro model 1000 times with keynesian and 1000 times with marshallian setups
 */

main()
{


  for (int i = 0; i < 100; i++)
  {
    print("$i");
    fixedWageMacro("keynesian.json", pathToJsonFromProjectRoot: ["bin"],
                   additionalJSonFiles : ["shock.experiment.json"],
                   testing:false,
                   outputPath: ["docs","yackm","rawdata","1000macro","keynesian"],
                   gasCsvName: "${i}_sales.csv",
                   laborCsvName: "${i}_hr.csv",
                   totalSteps:20000, shockDay:10000, endShockDay:-1, shockSize:-0.2,
                   dateDirectory:false);

    fixedWageMacro("marshallian.json", pathToJsonFromProjectRoot: ["bin"],
                   additionalJSonFiles : ["shock.experiment.json"],
                   testing:false,
                   outputPath: ["docs","yackm","rawdata","1000macro","marshallian"],
                   gasCsvName: "${i}_sales.csv",
                   laborCsvName: "${i}_hr.csv",
                   totalSteps:20000, shockDay:10000, endShockDay:-1, shockSize:-0.2,
                   dateDirectory:false);
  }


}