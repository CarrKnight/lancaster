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
  fixedWageMacro("keynesian.json", testing:false,
                 gasCsvName: "K_cycle_gas.csv",
                 laborCsvName: "K_cycle_wage.csv",
                 totalSteps:20000, shockDay:10000, endShockDay:15000, shockSize:-0.2,
                 salesCSV : "K_cycle_sales.csv", hrCSV: "K_cycle_hr.csv",logName:"log.json",
                 outputPath : ["bin","tmp"]);

  fixedWageMacro("marshallian.json", testing:false,
                 gasCsvName: "M_cycle_gas.csv",
                 laborCsvName: "M_cycle_wage.csv",
                 totalSteps:20000, shockDay:10000, endShockDay:15000, shockSize:-0.2,
                 salesCSV : "M_cycle_sales.csv", hrCSV: "M_cycle_hr.csv",logName:"log2.json",
                 outputPath : ["bin","tmp"]);


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
  String sep =Platform.pathSeparator;
  Directory testDirectory = new Directory("${findRootFolder()}${sep}test${sep}model${sep}engine");
  File defaultParameters = new File("${testDirectory.path}${Platform.pathSeparator}default.json");
  File testParameters = new File("${testDirectory.path}${Platform.pathSeparator}KeynesianLearnedCompetitive.json");


  Model model = new Model.fromJSON(defaultParameters.readAsStringSync());
  model.parameters.mergeWithJSON(testParameters.readAsStringSync());


  OneMarketCompetition scenario = model.scenario;




  scenario.hrIntializer = (ZeroKnowledgeTrader sales) {
    sales.predictor = new
    LastPricePredictor();
  };
  scenario.salesInitializer = (ZeroKnowledgeTrader sales) {
    sales.predictor = new
    LastPricePredictor();
  };


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
    outputDataToCSV(gas.data.backingMap,gasName,defaultOutputPath);
  if(wageName!=null)
    outputDataToCSV(labor.data.backingMap,wageName,defaultOutputPath);

}


learnedCompetitorTest(int competitors, [bool unitTest=true, String gasName = null,String
wageName = null, String gasPIDName = null, String wagePIDName = null])
{
  String sep =Platform.pathSeparator;
  Directory testDirectory = new Directory("${findRootFolder()}${sep}test${sep}model${sep}engine");
  File defaultParameters = new File("${testDirectory.path}${Platform.pathSeparator}default.json");

  Model model = new Model.fromJSON(defaultParameters.readAsStringSync());

  OneMarketCompetition scenario = model.scenario;

  model.parameters.setField("competitors","default.scenario.OneMarketCompetition",competitors);
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
    outputDataToCSV(gas.data.backingMap,gasName,defaultOutputPath);
  if(wageName!=null)
    outputDataToCSV(labor.data.backingMap,wageName,defaultOutputPath);
  if(gasPIDName!=null)
    outputDataToCSV(gasPID.backingMap,gasPIDName,defaultOutputPath);
  if(wagePIDName!=null)
    outputDataToCSV(wagePID.backingMap,wagePIDName,defaultOutputPath);

}


/**
 * run fixed wage macro experiments and return the output market data
 */
Model initializeOneMarketModel(List<String> pathToJsonFromProjectRoot, String jsonFileName, List<String> additionalJSonFiles,
                      bool burnInventories, [int seed = null])
{
  String sep = Platform.pathSeparator;
  if (pathToJsonFromProjectRoot == null)
    pathToJsonFromProjectRoot = ["bin"];
  Directory jsonDirectory = new Directory(findRootFolder());

  for (String dir in pathToJsonFromProjectRoot)
    jsonDirectory = new Directory("${jsonDirectory.path}${sep}$dir");


  File defaultParameters = new File("${jsonDirectory.path}${sep}default.json");
  File additionalParameters = new File("${jsonDirectory.path}${sep}${jsonFileName}");


  Model model = new Model.fromJSON(defaultParameters.readAsStringSync(),seed);
  model.parameters.mergeWithJSON(additionalParameters.readAsStringSync());

  //if there are even more files, read them now
  if (additionalJSonFiles != null)
    for (String file in additionalJSonFiles)
    {
      File addOn = new File("${jsonDirectory.path}${sep}${file}");
      model.parameters.mergeWithJSON(addOn.readAsStringSync());

    }

  OneMarketCompetition scenario = model.scenario;
  //doesn't add slopes when predicting prices
  scenario.hrIntializer = (ZeroKnowledgeTrader sales) {
    sales.predictor = new
    LastPricePredictor();
  };


  if (burnInventories)
    scenario.salesInitializer = (ZeroKnowledgeTrader trader) {
      trader.predictor = new LastPricePredictor();
      trader.dawnEvents.add(BurnInventories());
    };
  else
    scenario.salesInitializer = (ZeroKnowledgeTrader sales) {
      sales.predictor = new
      LastPricePredictor();
    };
  return model;
}


/**
 * useful to apply conditions to a running scenario, model
 */
typedef void ScenarioConsumer(OneMarketCompetition scenario, Model model);

Data fixedWageMacro(
    String jsonFileName,
    {
    List<String> pathToJsonFromProjectRoot : null, //if null, the default is to use root/bin folder
    List<String> additionalJSonFiles : null,
    int seed : null,
    bool testing : true,
    bool burnInventories : true,
    String gasCsvName: null,
    String laborCsvName: null,
    int totalSteps : 10000,
    String salesCSV : null,
    String hrCSV: null,
    //shocks
    int shockDay : -1,
    int endShockDay: -1,
    //negative if the shock lowers demand
    num shockSize : 0.0,
    bool dateDirectory : true, //put csvs in a directory with time stamp
    List<String> outputPath : null, //if null it outputs to docs
    String logName : null,
    ScenarioConsumer shockEffects : null
    })
{

  var model = initializeOneMarketModel(pathToJsonFromProjectRoot, jsonFileName, additionalJSonFiles, burnInventories,seed);

  //demand = total wages yesterday, that's what makes it macro
  ExogenousSellerMarket goodMarket = new ExogenousSellerMarket.linkedToWagesFromModel ("labor");
  OneMarketCompetition scenario = model.scenario;
  scenario.goodMarket = goodMarket;
  model.start();

  Market gas = model.markets["gas"];
  Market labor = model.markets["labor"];


  for (int i = 0; i < totalSteps; i++) {
    model.schedule.simulateDay();
    if(i==shockDay)
    {
      goodMarket.demand = ExogenousSellerMarket.linkedToWageDemand(model,
                                                                   "labor",
                                                                   shockSize);
      if(shockEffects != null)
        shockEffects(scenario,model);
    }
    if(i==endShockDay)
      goodMarket.demand = ExogenousSellerMarket.linkedToWageDemand (model,
                                                                    "labor", 0.0);
  }




  if(testing)
  {
    int i = model.schedule.day;
    if((shockDay> 0 && i>=shockDay) && (endShockDay < 0 || i < endShockDay))
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

  if(outputPath == null)
  {
    outputPath = new List.from(defaultOutputPath);
  }
  if(dateDirectory)
    outputPath.add(new DateTime.now().toString());

  print(outputPath);

  if(gasCsvName!=null)
    outputDataToCSV(gas.data.backingMap,gasCsvName,outputPath);
  if(laborCsvName!=null)
    outputDataToCSV(labor.data.backingMap,laborCsvName,outputPath);
  if(salesCSV != null)
    //look at this long series of dot operations! Stay in school, kids!
    outputDataToCSV(scenario.firms.first.salesDepartments["gas"].data.backingMap,salesCSV,outputPath);
  if(hrCSV != null)
    outputDataToCSV(scenario.firms.first.purchasesDepartments["labor"].data.backingMap,hrCSV,outputPath);

  if(logName != null)
  {
    File file = new File(getOutputPathForFile(logName,outputPath));
    file.createSync();
    file.writeAsStringSync(model.parameters.log,flush:true);

  }



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

final List<String> defaultOutputPath = ["docs","yackm","rawdata"];

String getOutputPathForFile(String file, List<String> outputSubdirectory){

  String sep = Platform.pathSeparator;
  Directory outputDirectory = new Directory(findRootFolder());

  for (String dir in outputSubdirectory)
    outputDirectory = new Directory("${outputDirectory.path}${sep}${dir}");

  return "${outputDirectory.path}${sep}${file}";
}



void outputDataToCSV(Map<String,List<double>> _dataMap, String fileName,List<String> outputSubDirectory)
{
  fileName = getOutputPathForFile(fileName,outputSubDirectory);
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
Data fixedWageMicro(String jsonFileName,
                    {
                    List<String> pathToJsonFromProjectRoot : null, //if null, the default is to use root/bin folder
                    List<String> additionalJSonFiles : null,
                    bool testing : true,
                    bool burnInventories : true,
                    String gasCsvName: null,
                    String laborCsvName: null,
                    int totalSteps : 10000,
                    int seed : null,
                    String salesCSV : null,
                    String hrCSV: null,
                    //negative if the shock lowers demand
                    num shockSize : 0.0,
                    List<String> outputPath : null, //if null it outputs to docs
                    String logName : null
                    })
{
  Model model = initializeOneMarketModel(pathToJsonFromProjectRoot,
                                         jsonFileName, additionalJSonFiles,
                                         burnInventories,seed);
  OneMarketCompetition scenario = model.scenario;


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



  if(outputPath == null)
  {
    outputPath = defaultOutputPath;
    outputPath.add(new DateTime.now().toString());
  }

  if(gasCsvName!=null)
    outputDataToCSV(gas.data.backingMap,gasCsvName,outputPath);
  if(laborCsvName!=null)
    outputDataToCSV(labor.data.backingMap,laborCsvName,outputPath);
  if(salesCSV != null)
    //look at this long series of dot operations! Stay in school, kids!
    outputDataToCSV(scenario.firms.first.salesDepartments["gas"].data.backingMap,salesCSV,outputPath);
  if(hrCSV != null)
    outputDataToCSV(scenario.firms.first.purchasesDepartments["labor"].data.backingMap,hrCSV,outputPath);

  if(logName != null)
  {
    File file = new File(getOutputPathForFile(logName,outputPath));
    file.createSync();
    file.writeAsStringSync(model.parameters.log,flush:true);
  }


  return gas.data;
}
