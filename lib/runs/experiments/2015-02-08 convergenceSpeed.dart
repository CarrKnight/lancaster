/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

library runs.yackm;

import 'package:lancaster/model/lancaster_model.dart';
import 'dart:math';
import 'dart:io';
import 'package:unittest/unittest.dart';
import '../yackm.dart';


main()
{

  //hide the collection in the data function. Kind of weird, but easy to output to csv later
  Data histogramKM = new Data(["keynesian","marshallian"],
                                  (data)=>(s){
                                data["keynesian"].add(extractApproximateDateOfEquilibrium(
                                    fixedWageMacro(true,testing:false,totalSteps:15000)
                                    ));
                                data["marshallian"].add(extractApproximateDateOfEquilibrium(
                                    fixedWageMacro(false,testing:false,totalSteps:15000)
                                    ));
                              });


  for(int runs=0;runs<1000;runs++)
  {
    histogramKM.updateStep(null);
    print("run $runs completed");
  }


  writeCSV(histogramKM.backingMap,"convergeSpeed2.csv");

}


/**
 * try to get the day when equilibrium was reached by reading the data
 */
int extractApproximateDateOfEquilibrium(Data gasMarketData)
{

  Matcher qCloseEnough =  closeTo(5.0, 0.75);
  Matcher pCloseEnough =  closeTo(20.0, 0.25);

  int earlierQDate = null;
  int earlierPDate = null;

  List<double> quantities = gasMarketData.getObservations("quantity");
  List<double> prices = gasMarketData.getObservations("price");

  for(int day =0; day<quantities.length; day++)
  {

    //check if the q is good enough
    if(earlierQDate == null && qCloseEnough.matches(quantities[day],null))
    {
      earlierQDate = day;
    }
    //also check if it was good enough but it isn't anymore
    else if(!qCloseEnough.matches(quantities[day],null))
      earlierQDate = null;


    //same thing for price
    if(earlierPDate == null && pCloseEnough.matches(prices[day],null))
      earlierPDate = day;
    else if(!pCloseEnough.matches(prices[day],null))
      earlierPDate = null;

  }


  if(earlierQDate == null || earlierPDate== null)
    return null;
  else
    return max(earlierQDate,earlierPDate);


}