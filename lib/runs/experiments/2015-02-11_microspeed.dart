library experiments.microspeed;

import '2015-02-08 convergenceSpeed.dart';
import 'package:lancaster/model/lancaster_model.dart';
import 'dart:math';
import 'dart:io';
import 'package:unittest/unittest.dart';
import '../yackm.dart';

/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */


main()
{

  //hide the collection in the data function. Kind of weird, but easy to output to csv later
  Data histogramKM = new Data(["keynesian","marshallian"],
                                  (data)=>(s){
                                data["keynesian"].add(extractApproximateDateOfEquilibrium(
                                    fixedWageMicro(true,testing:false,totalSteps:15000)
                                    , correctP : 50.0, correctQ : 50.0, minPDistance: 0.25, minQDistance:0.25
                                    ));
                                data["marshallian"].add(extractApproximateDateOfEquilibrium(
                                    fixedWageMicro(false,testing:false,totalSteps:15000)
                                    , correctP : 50.0, correctQ : 50.0, minPDistance: 0.25, minQDistance:0.25
                                    ));
                              });


  for(int runs=0;runs<1000;runs++)
  {
    histogramKM.updateStep(null);
    print("run $runs completed");
  }


  writeCSV(histogramKM.backingMap,"micro_converge_speed3.csv");
/*
  fixedWageMicro(true,testing:false,
                 gasCsvName: "K_micro_gas.csv",
                 laborCsvName: "K_micro_wage.csv",
                 salesCSV : "K_micro_sales.csv", hrCSV: "K_micro_hr.csv");


  fixedWageMicro(false,testing:false,
                 gasCsvName: "M_micro_gas.csv",
                 laborCsvName: "M_micro_wage.csv",
                 salesCSV : "M_micro_sales.csv", hrCSV: "M_micro_hr.csv");
*/
}