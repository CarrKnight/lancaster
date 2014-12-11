/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

//a bunch of runs that I need to output to csvs

library runs.yackm;

import 'package:lancaster/model/lancaster_model.dart';
import 'dart:math';
import 'dart:io';
import 'package:unittest/unittest.dart';


main()
{


  KeynesianLearnedCompetitive(false,getOutputPathForFile("KGas.csv"),
  getOutputPathForFile("KWage.csv"));

  learnedCompetitorTest(1,false,getOutputPathForFile("MGas.csv"),
  getOutputPathForFile("MWage.csv"));


}



KeynesianLearnedCompetitive([bool unitTest=true, String gasName = null,String
wageName = null])
{
  Model model = new Model.randomSeed();
  OneMarketCompetition scenario = new OneMarketCompetition();
  model.scenario = scenario;

  //this is the default
  // multiplier when using  PROFIT_MAXIMIZER_PRICING
  scenario.salesMinP = 100.0;
  scenario.salesMaxP = 100.0;

  scenario.hrIntializer = (ZeroKnowledgeTrader sales) {
    sales.predictor = new
    LastPricePredictor();
  };
  scenario.salesInitializer = (ZeroKnowledgeTrader sales) {
    sales.predictor = new
    LastPricePredictor();
  };

  scenario.salesPricingInitialization =
  OneMarketCompetition.PROFIT_MAXIMIZER_PRICING;

  scenario.hrPricingInitialization = (SISOPlant plant,
                                      Firm firm,  Random r,  ZeroKnowledgeTrader seller,
                                      OneMarketCompetition scenario)
  {
    double p = r.nextDouble()*(scenario.purchaseMaxP-scenario.purchaseMinP) +
    scenario.purchaseMinP;
    double i = r.nextDouble()*(scenario.purchaseMaxI-scenario.purchaseMinI) +
    scenario.purchaseMinI;
    double price = r.nextDouble()*(scenario.maxInitialPriceBuying-scenario
    .minInitialPriceBuying) + scenario.minInitialPriceBuying;



    scenario.hrQuotaInitializer = OneMarketCompetition.KEYNESIAN_QUOTA;

    PIDAdaptive pricing = new PIDAdaptive.StockoutQuotaBuyer
    (initialPrice:price,p:p,i:i);
    pricing.pid = new StickyPID.Random(pricing.pid,r,20);
    return pricing;
  };

  model.start();

  Market gas = model.markets["gas"];
  Market labor = model.markets["labor"];

  for (int i = 0; i < 3000; i++) {
    model.schedule.simulateDay();
    print('''gas price: ${gas.averageClosingPrice} workers' wages: ${labor
    .averageClosingPrice}''');
    print('''gas quantity: ${gas.quantityTraded} workers : ${labor
    .quantityTraded}''');

  }
  print('''gas price: ${gas.averageClosingPrice} workers' wages: ${labor
  .averageClosingPrice}''');
  print('''gas quantity: ${gas.quantityTraded} workers : ${labor
  .quantityTraded}''');
  print('''gas price: ${gas.averageClosingPrice} workers' wages: ${labor
  .averageClosingPrice}''');
  if(unitTest) {
    expect(gas.averageClosingPrice, closeTo(50.0, 1.5));
    expect(gas.quantityTraded, closeTo(50.0, 1.5));
    expect(labor.averageClosingPrice, closeTo(50.0, 1.5));
    expect(labor.quantityTraded, closeTo(50.0, 1.5));
  }

  if(gasName!=null)
    gas.data.writeCSV(gasName);
  if(wageName!=null)
    labor.data.writeCSV(wageName);

}


learnedCompetitorTest(int competitors, [bool unitTest=true, String gasName = null,String
wageName = null])
{
  Model model = new Model.randomSeed();
  OneMarketCompetition scenario = new OneMarketCompetition();
  scenario.competitors = competitors;
  //doesn't add slopes when predicting prices
  scenario.hrIntializer = (ZeroKnowledgeTrader sales) {
    sales.predictor = new
    LastPricePredictor();
  };
  scenario.salesInitializer = (ZeroKnowledgeTrader sales) {
    sales.predictor = new
    LastPricePredictor();
  };

  scenario.hrPricingInitialization = OneMarketCompetition.PID_MAXIMIZER_HR;


  model.scenario = scenario;
  model.start();

  Market gas = model.markets["gas"];
  Market labor = model.markets["labor"];

  for (int i = 0; i < 3000; i++) {
    model.schedule.simulateDay();
  }

  print('''gas price: ${gas.averageClosingPrice} workers' wages: ${labor
  .averageClosingPrice}''');
  if(unitTest != false) {
    expect(gas.averageClosingPrice, closeTo(50.0, 1.5));
    expect(gas.quantityTraded, closeTo(50.0, 1.5));
    expect(labor.averageClosingPrice, closeTo(50.0, 1.5));
    expect(labor.quantityTraded, closeTo(50.0, 1.5));
    expect(model.agents.length, competitors);
  }

  if(gasName!=null)
    gas.data.writeCSV(gasName);
  if(wageName!=null)
    labor.data.writeCSV(wageName);
}


String findRootFolder()
{
/*  Directory.current.list().listen((entity){
    print(entity);});
    */
  var current = Directory.current;

  // List directory contents, recursing into sub-directories,
  // but not following symbolic links.
  bool containPub = false;
  while(!containPub)
  {
    //search for pubspec.yaml
    List<FileSystemEntity> elements = current.listSync();
    for(FileSystemEntity e in elements)
      if(e.path == "${current.path}${Platform.pathSeparator}pubspec.yaml") {
        containPub = true;
        break;
      }
    if(!containPub)
      current = current.parent;
  }

  return current.path;
}

String getOutputPathForFile(String file){

  return "${findRootFolder()}${Platform.pathSeparator}docs${Platform
  .pathSeparator}yackm${Platform.pathSeparator}rawdata${Platform
  .pathSeparator}$file";
}