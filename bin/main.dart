/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
import 'package:lancaster/model/lancaster_model.dart';
import 'dart:math';
import 'dart:io';
import 'package:lancaster/runs/yackm.dart';



main(){

  //simple macro to show it reaches equilibrium
  List<String> outputPath = ["bin", "paper", "simple_macro"];
  for(int i=0; i<100; i++)
  {
    fixedWageMacro("keynesian.json",
                   pathToJsonFromProjectRoot: ["bin"],
                   additionalJSonFiles : ["shock.experiment.json"], //while there is no shock, I stored there a=0.5 b=1
                   testing:false,
                   gasCsvName: "${i}_K_gas.csv",
                   totalSteps:10000,
                   seed : i,
                   logName:"${i}_Klog.json",
                   outputPath : outputPath,
                   dateDirectory : false);

    fixedWageMacro("marshallian.json", testing:false,
                   pathToJsonFromProjectRoot: ["bin"],
                   additionalJSonFiles : ["shock.experiment.json"],//while there is no shock, I stored there a=0.5 b=1
                   gasCsvName: "${i}_M_gas.csv",
                   totalSteps:10000,
                   seed : i,
                   logName:"${i}_Mlog.json",
                   outputPath : outputPath,
                   dateDirectory : false);
  }


  //reaction to shock
  outputPath = ["bin", "paper", "shock_reaction"];

  for(int i=0; i<100; i++)
  {
    fixedWageMacro("keynesian.json", pathToJsonFromProjectRoot: ["bin"],
                   additionalJSonFiles : ["shock.experiment.json"],
                   testing:false,
                   outputPath: outputPath,
                   gasCsvName: "${i}_K_sales.csv",
                    laborCsvName : "${i}_K_labor.csv",
                   logName:"${i}_Klog.json",
                   seed : i,
                   totalSteps:20000, shockDay:10000, endShockDay:-1, shockSize:-0.2,
                   dateDirectory:false);

    fixedWageMacro("marshallian.json", pathToJsonFromProjectRoot: ["bin"],
                   additionalJSonFiles : ["shock.experiment.json"],
                   testing:false,
                   outputPath: outputPath,
                   gasCsvName: "${i}_M_sales.csv",
                   laborCsvName : "${i}_M_labor.csv",
                   logName:"${i}_Mlog.json",
                   totalSteps:20000, shockDay:10000, endShockDay:-1, shockSize:-0.2,
                   dateDirectory:false);
  }


  //increase in labor flexibility as PI controller
  //increase PI parameters of the keynesian controller when the crash comes
  outputPath = ["bin", "paper", "flexibility_shock"];
  for (int i = 0; i < 100; i++)
  {
    print("$i");
    fixedWageMacro("keynesian.json", pathToJsonFromProjectRoot: ["bin"],
                   additionalJSonFiles : ["shock.experiment.json"],
                   testing:false,
                   outputPath: outputPath,
                   gasCsvName: "${i}_sales_flexible.csv",
                   laborCsvName: "${i}_hr_flexible.csv",
                   totalSteps:20000, shockDay:10000, endShockDay:-1, shockSize:-0.2,
                   logName:"${i}_flexible_log.json",
                   dateDirectory:false, seed : i, //fix the seed!
                   //increase PI parameter in lieu of speed
                   shockEffects : (OneMarketCompetition scenario,model)
                   {
                     PIDAdaptive keynesianQuota = scenario.firms.first.purchasesDepartments["labor"].quoting;
                     PIDController pid = keynesianQuota.pid;
                     //increase PI by .1
                     pid.proportionalParameter = pid.proportionalParameter * 2;
                     pid.integrativeParameter = pid.integrativeParameter * 2;
                   });

    fixedWageMacro("keynesian.json", pathToJsonFromProjectRoot: ["bin"],
                   additionalJSonFiles : ["shock.experiment.json"],
                   testing:false,
                   outputPath: outputPath,
                   gasCsvName: "${i}_sales.csv",
                   laborCsvName: "${i}_hr.csv.csv",
                   logName:"${i}_log.json",
                   totalSteps:20000, shockDay:10000, endShockDay:-1, shockSize:-0.2,
                   dateDirectory:false,seed : i);


  }


  //increase in productivity concurrent with demand shock
  outputPath = ["bin", "paper", "productivity_shock"];
  for (int i = 0; i < 100; i++)
  {
    fixedWageMacro("keynesian.json", pathToJsonFromProjectRoot: ["bin"],
                   additionalJSonFiles : ["shock.experiment.json"],
                   testing:false,
                   outputPath: outputPath,
                   gasCsvName: "${i}_sales_productive.csv",
                   laborCsvName: "${i}_hr_productive.csv",
                   logName:"${i}_productive_log.json",
                   totalSteps:20000, shockDay:10000, endShockDay:-1, shockSize:-0.2,
                   dateDirectory:false, seed : i, //fix the seed!
                   //increase PI parameter in lieu of speed
                   shockEffects : (OneMarketCompetition scenario, model)
                   {
                     (scenario.firms.first.plants.first.function as ExponentialProductionFunction).multiplier =
                     0.6;
                   });

    fixedWageMacro("keynesian.json", pathToJsonFromProjectRoot: ["bin"],
                   additionalJSonFiles : ["shock.experiment.json"],
                   testing:false,
                   outputPath: outputPath,
                   gasCsvName: "${i}_sales.csv",
                   laborCsvName: "${i}_hr.csv.csv",
                   logName:"${i}_log.json",
                   totalSteps:20000, shockDay:10000, endShockDay:-1, shockSize:-0.2,
                   dateDirectory:false, seed : i);
  }


  outputPath = ["bin", "paper", "micro"];

  for( int i=0 ;i< 1000; i++)
  {
    fixedWageMicro("keynesian.micro.json",testing:false,totalSteps:5000,
                   outputPath : outputPath, gasCsvName: "${i}_K_sales.csv",
                   laborCsvName :"${i}_K_hr.csv",
                   logName:"{i}_K_log.json");


    fixedWageMicro("marshallian.micro.json",testing:false,totalSteps:5000,
                   outputPath : outputPath, gasCsvName: "${i}_M_sales.csv",
                   laborCsvName :"${i}_M_hr.csv",
                   logName:"{i}_M_log.json");


  }


}