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


/*
  fixedWageMacro(true,testing:false,
                 gasCsvName: "K_macro_gas.csv",
                 laborCsvName: "K_macro_wage.csv",fixedCost:-1.0,
                 salesCSV : "K_sales.csv", hrCSV: "K_hr.csv");


  fixedWageMacro(false,testing:false,
                 gasCsvName: "M_macro_gas.csv",
                 laborCsvName: "M_macro_wage.csv",fixedCost:-1.0,
                 salesCSV : "M_sales.csv", hrCSV: "M_hr.csv");


*/
  //cyclical tests!
  //demand shock at day 10000, recovery at day 15000
  fixedWageMacro(true,testing:false,
                 gasCsvName: "K_cycle_gas.csv",
                 laborCsvName: "K_cycle_wage.csv",
                 totalSteps:20000,shockday:10000,endshockday:15000,shockSize:-0.2,
                 multiplier : 0.5,fixedCost: -1.0,
                 salesCSV : "K_cycle_sales.csv", hrCSV: "K_cycle_hr.csv");

  fixedWageMacro(false,testing:false,
                 gasCsvName: "M_cycle_gas.csv",
                 laborCsvName: "M_cycle_wage.csv",
                 totalSteps:20000,shockday:10000,endshockday:15000,shockSize:-0.2,
                 multiplier : 0.5,fixedCost: -1.0,
                 salesCSV : "M_cycle_sales.csv", hrCSV: "M_cycle_hr.csv");


/*
  //drop
  //demand shock at day 10000, never recovers
  fixedWageMacro(true,testing:false,
                 gasCsvName: "K_drop_gas.csv",
                 laborCsvName: "K_drop_wage.csv",
                 totalSteps:20000,shockday:10000,endshockday:-1,shockSize:-1.0,
                 salesCSV : "K_drop_sales.csv", hrCSV: "K_drop_hr.csv");

  fixedWageMacro(false,testing:false,
                 gasCsvName: "M_drop_gas.csv",
                 laborCsvName: "M_drop_wage.csv",
                 totalSteps:20000,shockday:10000,endshockday:-1,shockSize:-1.0,
                 salesCSV : "M_drop_sales.csv", hrCSV: "M_drop_hr.csv");
 */

}



KeynesianLearnedCompetitive([bool unitTest=true,bool bufferInventory=true,
                            String gasName = null,String
wageName = null])
{
  Model model = new Model.randomSeed();
  OneMarketCompetition scenario = new OneMarketCompetition();
  model.scenario = scenario;



  //this is the default
  // multiplier when using  PROFIT_MAXIMIZER_PRICING
  scenario.salesMinP = 50.0;
  scenario.salesMaxP = 50.0;

  scenario.purchaseMaxP=.2;
  scenario.purchaseMaxI=.2;

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

  if(bufferInventory) {
    scenario.hrQuotaInitializer = OneMarketCompetition.KEYNESIAN_QUOTA;
  }
  else {
    scenario.hrQuotaInitializer = OneMarketCompetition.KEYNESIAN_STOCKOUT_QUOTA;
    scenario.salesInitializer = (ZeroKnowledgeTrader trader) {
      trader.predictor = new LastPricePredictor();
      trader.dawnEvents.add(BurnInventories());
    };
  }

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
    /*   print('''gas price: ${gas.averageClosingPrice} workers' wages: ${labor
    .averageClosingPrice}''');
    print('''gas quantity: ${gas.quantityTraded} workers : ${labor
    .quantityTraded}''');
*/
  }
  /*
  print('''gas price: ${gas.averageClosingPrice} workers' wages: ${labor
  .averageClosingPrice}''');
  print('''gas quantity: ${gas.quantityTraded} workers : ${labor
  .quantityTraded}''');
  print('''gas price: ${gas.averageClosingPrice} workers' wages: ${labor
  .averageClosingPrice}''');
  */
  if(unitTest) {
    expect(gas.averageClosingPrice, closeTo(50.0, 1.5));
    expect(gas.quantityTraded, closeTo(50.0, 1.5));
    expect(labor.averageClosingPrice, closeTo(50.0, 1.5));
    expect(labor.quantityTraded, closeTo(50.0, 1.5));
  }

  if(gasName!=null)
    writeCSV(gas.data.backingMap,gasName);
  if(wageName!=null)
    writeCSV(labor.data.backingMap,wageName);

}


learnedCompetitorTest(int competitors, [bool unitTest=true, String gasName = null,String
wageName = null, String gasPIDName = null, String wagePIDName = null])
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

  //this is old and might need to be replaced
  Data gasPID = new Data.AdaptiveStrategyData(
      (((gas as SellerMarket).sellers.first as ZeroKnowledgeTrader).pricing as
      ControlStrategy));
  gasPID.start(model.schedule);
  Data wagePID = new Data.AdaptiveStrategyData(
      (((labor as BuyerMarket).buyers.first as ZeroKnowledgeTrader).pricing as
      ControlStrategy));
  wagePID.start(model.schedule);

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
    writeCSV(gas.data.backingMap,gasName);
  if(wageName!=null)
    writeCSV(labor.data.backingMap,wageName);
  if(gasPIDName!=null)
    writeCSV(gasPID.backingMap,gasPIDName);
  if(wagePIDName!=null)
    writeCSV(wagePID.backingMap,wagePIDName);

}


/**
 * run fixed wage macro experiments and return the output market data
 */
Data fixedWageMacro(bool keynesian,
                    {
                    bool testing : true,
                    String gasCsvName: null,
                    String laborCsvName: null,
                    int totalSteps : 10000,
                    productionExponent : 0.5,
                    //negative!
                    fixedCost : -5.0,
                    multiplier: 1.0,
                    String salesCSV : null,
                    String hrCSV: null,
                    //shocks
                    int shockday : -1,
                    int endshockday: -1,
                    //negative if the shock lowers demand
                    double shockSize : 0.0
                    })
{
  Model model = new Model.randomSeed();
  OneMarketCompetition scenario = new OneMarketCompetition();
  scenario.competitors = 1;
  //doesn't add slopes when predicting prices
  scenario.hrIntializer = (ZeroKnowledgeTrader sales) {
    sales.predictor = new
    LastPricePredictor();
  };
  scenario.salesInitializer = (ZeroKnowledgeTrader sales) {
    sales.predictor = new
    LastPricePredictor();
  };
  //F = Sqrt(L)-5
  scenario.productionFunction = new ExponentialProductionFunction(exponent:productionExponent)
    ..multiplier = multiplier
    ..freebie = fixedCost;
  scenario.laborMarket = new ExogenousBuyerMarket.infinitelyElastic(1.0,
                                                                    goodType:"labor");
  //demand = total wages yesterday
  var goodMarket = new ExogenousSellerMarket.linkedToWagesFromModel (model, "labor");
  scenario.goodMarket = goodMarket;

  //fixed wages = 1
  scenario.hrPricingInitialization = (SISOPlant plant,
                                      Firm firm,  Random r,  ZeroKnowledgeTrader seller,
                                      OneMarketCompetition scenario)=> new FixedValue(1.0);

//todo make explicit all the choices of initializers
  if(keynesian){
    scenario.hrQuotaInitializer = OneMarketCompetition
    .KEYNESIAN_STOCKOUT_QUOTAS(50.0);
    scenario.salesInitializer = (ZeroKnowledgeTrader trader) {
      trader.predictor = new LastPricePredictor();
      trader.dawnEvents.add(BurnInventories());
    };
    //this is the default
    // multiplier when using  PROFIT_MAXIMIZER_PRICING
    scenario.salesMinP = 100.0;
    scenario.salesMaxP = 100.0;
    scenario.salesPricingInitialization = OneMarketCompetition.PROFIT_MAXIMIZER_PRICING;
  }
  else {
    //marshallian
    scenario.hrQuotaInitializer = OneMarketCompetition.MARSHALLIAN_QUOTAS(50.0);
    scenario.salesPricingInitialization = OneMarketCompetition.STOCKOUT_SALES;
    scenario.salesInitializer = (ZeroKnowledgeTrader trader) {
      trader.predictor = new LastPricePredictor();
      trader.dawnEvents.add(BurnInventories());
    };

  }
  model.scenario = scenario;
  model.start();

  Market gas = model.markets["gas"];
  Market labor = model.markets["labor"];


  for (int i = 0; i < totalSteps; i++) {
    model.schedule.simulateDay();
    if(i==shockday)
      goodMarket.demand = ExogenousSellerMarket.linkedToWageDemand (model,
                                                                    "labor",
                                                                    shockSize);
    if(i==endshockday)
      goodMarket.demand = ExogenousSellerMarket.linkedToWageDemand (model,
                                                                    "labor", 0.0);
  }




  if(testing)
  {
    int i = model.schedule.day;
    if((shockday> 0 && i>=shockday) && (endshockday < 0 || i < endshockday))
    {

      //shock!
      expect(gas.averageClosingPrice, closeTo(16.0, 1.5));
      expect(gas.quantityTraded, closeTo(3.0, 0.5));
      expect(labor.averageClosingPrice, closeTo(1.0, 0.0));
      expect(labor.quantityTraded, closeTo(64.0, 2.5));
    }
    else {
      expect(gas.averageClosingPrice, closeTo(20.0, 1.5));
      expect(gas.quantityTraded, closeTo(5.0, 0.5));
      expect(labor.averageClosingPrice, closeTo(1.0, 0.0));
      expect(labor.quantityTraded, closeTo(100.0, 2.5));
    }
  }
  if(gasCsvName!=null)
    writeCSV(gas.data.backingMap,gasCsvName);
  if(laborCsvName!=null)
    writeCSV(labor.data.backingMap,laborCsvName);
  if(salesCSV != null)
    //look at this long series of dot operations! Stay in school, kids!
    writeCSV(scenario.firms.first.salesDepartments["gas"].data.backingMap,salesCSV);
  if(hrCSV != null)
    writeCSV(scenario.firms.first.purchasesDepartments["labor"].data.backingMap,hrCSV);

  return gas.data;
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

  var root = findRootFolder();
  return "${root}${Platform.pathSeparator}docs${Platform
  .pathSeparator}yackm${Platform.pathSeparator}rawdata${Platform
  .pathSeparator}$file";
}



void writeCSV(Map<String,List<double>> _dataMap, String fileName)
{
  fileName = getOutputPathForFile(fileName);
  print("writing to $fileName");
  //create string
  StringBuffer toWrite = new StringBuffer();
  var rows = _dataMap.values;
  int rowN = rows.first.length;

  Iterable<String> columns = _dataMap.keys;
  int columnN = columns.length;
  //header
  int j=0;
  for (String column in columns) {
    if(j>0)
      toWrite.write(",");
    toWrite.write(column); j++;
  }
  toWrite.writeln();


  for(int i=0; i<rowN; i++) {
    int j=0;
    for (String column in columns) {
      if(j>0)
        toWrite.write(",");
      toWrite.write(_dataMap[column][i]);
      j++;
    }
    toWrite.writeln();
  }

  if(toWrite.length == 0)
    return;

  //create the file
  File file = new File(fileName);
  if(file.existsSync())
    file.deleteSync();
  file.createSync(recursive:true);
  //write the file
  file.writeAsStringSync(toWrite.toString());

}



/**
 * run fixed wage micro experiments and return the output market data
 */
Data fixedWageMicro(bool keynesian,
                    {
                    bool testing : true,
                    String gasCsvName: null,
                    String laborCsvName: null,
                    int totalSteps : 10000,
                    //negative!
                    double intercept : 100.0,
                    double slope: -1.0,
                    //wages
                    double wage : 50.0,
                    String salesCSV : null,
                    String hrCSV: null,
                    //negative if the shock lowers demand
                    double shockSize : 0.0
                    })
{
  Model model = new Model.randomSeed();
  OneMarketCompetition scenario = new OneMarketCompetition();
  scenario.competitors = 1;
  //doesn't add slopes when predicting prices
  scenario.hrIntializer = (ZeroKnowledgeTrader sales) {
    sales.predictor = new
    LastPricePredictor();
  };
  scenario.salesInitializer = (ZeroKnowledgeTrader sales) {
    sales.predictor = new
    LastPricePredictor();
  };
  //1 worker, 1 good
  scenario.productionFunction = new LinearProductionFunction();

  scenario.laborMarket = new ExogenousBuyerMarket.infinitelyElastic(wage,
                                                                    goodType:"labor");
  //demand = total wages yesterday
  scenario.goodMarket = new ExogenousSellerMarket.linear(intercept:intercept, slope:slope);

  //fixed wages
  scenario.hrPricingInitialization = (SISOPlant plant,
                                      Firm firm,  Random r,  ZeroKnowledgeTrader seller,
                                      OneMarketCompetition scenario)=> new FixedValue(wage);


  if(keynesian){
    //start at 1 instead of 50 since there is no fixed cost
    double initialL = model.random.nextDouble() * (scenario.maxInitialPriceSelling  - scenario.minInitialPriceSelling) +
                      scenario.minInitialPriceBuying;
    scenario.hrQuotaInitializer = OneMarketCompetition
    .KEYNESIAN_STOCKOUT_QUOTAS(1.0);
    scenario.salesInitializer = (ZeroKnowledgeTrader trader) {
      trader.predictor = new LastPricePredictor();
      trader.dawnEvents.add(BurnInventories());
    };
    //this is the default
    // multiplier when using  PROFIT_MAXIMIZER_PRICING
    scenario.salesMinP = 100.0;
    scenario.salesMaxP = 100.0;
    scenario.salesPricingInitialization = OneMarketCompetition.PROFIT_MAXIMIZER_PRICING;
  }
  else {
    //marshallian
    double initialL = model.random.nextDouble() * (scenario.maxInitialPriceSelling  - scenario.minInitialPriceSelling) +
                      scenario.minInitialPriceSelling;
    scenario.hrQuotaInitializer = OneMarketCompetition.MARSHALLIAN_QUOTAS(initialL);
    scenario.salesPricingInitialization = OneMarketCompetition.STOCKOUT_SALES;
    scenario.salesInitializer = (ZeroKnowledgeTrader trader) {
      trader.predictor = new LastPricePredictor();
      trader.dawnEvents.add(BurnInventories());
    };

  }
  model.scenario = scenario;
  model.start();

  Market gas = model.markets["gas"];
  Market labor = model.markets["labor"];


  for (int i = 0; i < totalSteps; i++) {
    model.schedule.simulateDay();

  }




  if(testing)
  {
    int i = model.schedule.day;
    expect(gas.averageClosingPrice, closeTo(50.0, 1.5));
    expect(gas.quantityTraded, closeTo(50.0, 1.5));
    expect(labor.averageClosingPrice, closeTo(50.0, 0.5));
    expect(labor.quantityTraded, closeTo(50.0, 0.5));
  }

  if(gasCsvName!=null)
    writeCSV(gas.data.backingMap,gasCsvName);
  if(laborCsvName!=null)
    writeCSV(labor.data.backingMap,laborCsvName);
  if(salesCSV != null)
    //look at this long series of dot operations! Stay in school, kids!
    writeCSV(scenario.firms.first.salesDepartments["gas"].data.backingMap,salesCSV);
  if(hrCSV != null)
    writeCSV(scenario.firms.first.purchasesDepartments["labor"].data.backingMap,hrCSV);

  return gas.data;
}
