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

  //increase PI parameters of the keynesian controller when the crash comes
  for (int i = 0; i < 100; i++)
  {
    print("$i");
    fixedWageMacro("keynesian.json", pathToJsonFromProjectRoot: ["bin"],
                   additionalJSonFiles : ["shock.experiment.json"],
                   testing:false,
                   outputPath: ["docs", "yackm", "rawdata", "pi speed shock${timeStamp}"],
                   gasCsvName: "${i}_sales_flexible.csv",
                   laborCsvName: "${i}_hr_flexible.csv",
                   totalSteps:20000, shockDay:10000, endShockDay:-1, shockSize:-0.2,
                   dateDirectory:false, seed : i, //fix the seed!
                   //increase PI parameter in lieu of speed
                   shockEffects : (OneMarketCompetition scenario,model)
                   {
                     PIDAdaptive keynesianQuota = scenario.firms.first.purchasesDepartments["labor"].quoting;
                     PIDController pid = keynesianQuota.pid;
                     //increase PI by .1
                     pid.proportionalParameter = pid.proportionalParameter + .2;
                     pid.integrativeParameter = pid.integrativeParameter + .2;
                   });

    fixedWageMacro("keynesian.json", pathToJsonFromProjectRoot: ["bin"],
                   additionalJSonFiles : ["shock.experiment.json"],
                   testing:false,
                   outputPath: ["docs", "yackm", "rawdata", "pi speed shock${timeStamp}"],
                   gasCsvName: "${i}_sales.csv",
                   laborCsvName: "${i}_hr.csv.csv",
                   totalSteps:20000, shockDay:10000, endShockDay:-1, shockSize:-0.2,
                   dateDirectory:false,seed : i);


  }

}