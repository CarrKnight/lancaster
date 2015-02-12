/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
library experiments.shockspeed;

import '2015-02-08 convergenceSpeed.dart';
import 'package:lancaster/model/lancaster_model.dart';
import 'dart:math';
import 'dart:io';
import 'package:unittest/unittest.dart';
import '../yackm.dart';


//run the model, make it reach equilibrium then shock it. Time when it reachest the new equilibrium
main()
{

  /*
  //hide the collection in the data function. Kind of weird, but easy to output to csv later
  Data histogramKM = new Data(["keynesian","marshallian"],
                                  (data)=>(s){
                                data["keynesian"].add(extractApproximateDateOfEquilibrium(
                                    fixedWageMacro(true,testing:false,
                                                   totalSteps:20000,shockday:10000,endshockday:-1,shockSize:-0.2,
                                                   multiplier : 0.5,fixedCost: -1.0)
                                    , correctP : 12.8 , correctQ : 0.6, minPDistance: 0.25, minQDistance:0.025

                                    ));
                                data["marshallian"].add(extractApproximateDateOfEquilibrium(
                                    fixedWageMacro(false,testing:false,
                                                   totalSteps:20000,shockday:10000,endshockday:-1,shockSize:-0.2,
                                                   multiplier : 0.5,fixedCost: -1.0)
                                    , correctP : 12.8 , correctQ : 0.6, minPDistance: 0.25, minQDistance:0.025

                                    ));
                              });


  for(int runs=0;runs<1000;runs++)
  {
    histogramKM.updateStep(null);
    print("run $runs completed");
  }


  writeCSV(histogramKM.backingMap,"shock_converge_speed.csv");

*/
  
  fixedWageMacro(true,testing:false,
                 gasCsvName: "K_drop_gas.csv",
                 laborCsvName: "K_drop_wage.csv",
                 totalSteps:20000,shockday:10000,endshockday:-1,shockSize:-0.2,
                 multiplier : 0.5,fixedCost: -1.0,
                 salesCSV : "K_drop_sales.csv", hrCSV: "K_drop_hr.csv");
  
  fixedWageMacro(false,testing:false,
                 gasCsvName: "M_drop_gas.csv",
                 laborCsvName: "M_drop_wage.csv",
                 totalSteps:20000,shockday:10000,endshockday:-1,shockSize:-0.2,
                 multiplier : 0.5,fixedCost: -1.0,
                 salesCSV : "M_drop_sales.csv", hrCSV: "M_drop_hr.csv");
}