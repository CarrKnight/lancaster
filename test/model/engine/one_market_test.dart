/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
library one_market.test;
import 'package:test/test.dart';
import 'package:lancaster/model/lancaster_model.dart';
import 'package:lancaster/runs/yackm.dart';
import 'dart:math';
import 'dart:io';





KeynesianInfiniteElasticity(bool marketDayOnly) {



  //gain access to DB files
  Directory testDirectory = new Directory("${findRootFolder()}${Platform.pathSeparator}test${Platform.pathSeparator}model${Platform.pathSeparator}engine");
  File defaultParameters = new File("${testDirectory.path}${Platform.pathSeparator}default.json");
  File testParameters = new File("${testDirectory.path}${Platform.pathSeparator}KeynesianInfiniteElasticity.json");

  Model model = new Model.fromJSON(defaultParameters.readAsStringSync());
  model.parameters.mergeWithJSON(testParameters.readAsStringSync());

  OneMarketCompetition experiment = new
  OneMarketCompetition();
  model.scenario = experiment;

  if(marketDayOnly)
    experiment.salesPricingInitialization =
    OneMarketCompetition.FIXED_PRICE;
  else
    experiment.salesPricingInitialization =
    OneMarketCompetition.PROFIT_MAXIMIZER_PRICING;


  model.start();

  Market gas = model.markets["gas"];
  Market labor = model.markets["labor"];

  for (int i = 0; i < 8000; i++) {
    model.schedule.simulateDay();


  }


  //should have throttled production more
  if(marketDayOnly) {
    expect(gas.quantityTraded, closeTo(.5,.011));
    expect(labor.quantityTraded, closeTo(.5,.011));
  }
  else
  {
    //equilibrium is price = 1, L= 2
    expect(gas.quantityTraded, closeTo(2,.011));
    expect(gas.averageClosingPrice, closeTo(1,.011));
    expect(labor.quantityTraded, closeTo(2,.011));
  }
}


main()
{

  for(int i=0; i<5;i++) {
    test("Marshallian Micro, ",
             ()=>fixedWageMicro("marshallian.micro.json",totalSteps:5000));

  }

  for(int i=0; i<5;i++) {
    test("Keynesian Micro, ",
             ()=>fixedWageMicro("keynesian.micro.json",totalSteps:5000));

  }



  for(int i=0; i<5;i++) {
    test("Marshallian Macro",
        ()=>fixedWageMacro("marshallian.json"));

  }

  for(int i=0; i<5;i++) {
    test("Keynesian Macro",
        ()=>fixedWageMacro("keynesian.json"));

  }

  for(int i=0; i<5;i++) {
    test("Marshallian Macro with shock",
             ()=>fixedWageMacro("marshallian.json",totalSteps:20000,shockDay:10000,shockSize:-1.0));

  }

  for(int i=0; i<5;i++) {
    test("Keynesian Macro with shock ",
             ()=>fixedWageMacro("keynesian.json",totalSteps:20000,shockDay:10000,shockSize:-1.0));

  }
  for(int i=0; i<5;i++) {
    test("Marshallian Recover from shock ",
             ()=>fixedWageMacro("marshallian.json",totalSteps:20000,shockDay:10000,endShockDay:15000,shockSize:-1.0));

  }

  for(int i=0; i<5;i++) {
    test("Keynesian Recover with shock ",
             ()=>fixedWageMacro("keynesian.json",totalSteps:20000,shockDay:10000,endShockDay:15000,shockSize:-1.0));

  }
  //one agent working as competitive
  for(int i=0;i<5;i++)
    test("Fake competitive", (){

      learnedCompetitorTest(1);


    });

  //five agents, all learned
  for(int i=0;i<5;i++)
    test("Learned competitive", (){

      oneMarketTest(true,false,5);

    });

  //five agents, all learned, pid
  for(int i=0;i<5;i++)
    test("Learned competitive PID", (){

      oneMarketTest(true,true,5);

    });

  //five agents, learning
  //fails about 3% of the time, unfortunately
  for(int i=0;i<5;i++)
    test("Learning competitive", (){

      oneMarketTest(false,false,5);

    });

  for(int i=0;i<5;i++)
    test("Learning competitive PID", (){

      oneMarketTest(false,true,5);

    });

  for(int i=0;i<5;i++)
    test("Learned Monopolist", (){ //knows the price impacts
      oneMarketTest(true,false);
    });
  //same, but with pid
  for(int i=0;i<5;i++)
    test("Learned Monopolist PID", (){ //knows the price impacts
      oneMarketTest(true,true);
    });

  for(int i=0;i<5;i++)
    test("Learning Monopolist", (){ //knows the price impacts
      oneMarketTest(false,false);
    });

  for(int i=0;i<100;i++)
    test("Learning Monopolist PID", (){ //knows the price impacts
      oneMarketTest(false,true);
    });

  for(int i=0;i<5;i++)
    test("Can solve market days by changing L",(){

      KeynesianInfiniteElasticity(true);


    });

  for(int i=0;i<5;i++)

    test("Short run Keynes, inelastic w",(){
      KeynesianInfiniteElasticity(false);
    });

  for(int i=0;i<5;i++)

    test("Learned Keynesian competitive",(){
      KeynesianLearnedCompetitive();
    });


  //todo fails about 1% of the time. Need better PID parameters for the
  // maximizer
  for(int i=0; i<5;i++) {
    test("Decreasing Productivity, fixed wage, Marshallian",
    ()=>squareRootProductionFixedWage(false));

  }


  for(int i=0; i<5;i++) {
    test("Keynesian Decreasing Productivity, fixed wage",
        ()=>squareRootProductionFixedWage(true));

  }





}




squareRootProductionFixedWage(bool keynesian)
{

  //gain access to DB files
  Directory testDirectory = new Directory("${findRootFolder()}${Platform.pathSeparator}test${Platform.pathSeparator}model${Platform.pathSeparator}engine");
  File defaultParameters = new File("${testDirectory.path}${Platform.pathSeparator}default.json");
  File testParameters = new File("${testDirectory.path}${Platform.pathSeparator}SquareRootProductionFixedWage.json");


  Model model = new Model.fromJSON(defaultParameters.readAsStringSync());
  model.parameters.mergeWithJSON(testParameters.readAsStringSync());
  OneMarketCompetition scenario = model.scenario;
  //doesn't add slopes when predicting prices
  scenario.hrIntializer = (ZeroKnowledgeTrader sales) {
    sales.predictor = new
    LastPricePredictor();
  };
  scenario.salesInitializer = (ZeroKnowledgeTrader sales) {
    sales.predictor = new
    LastPricePredictor();
  };


  if(keynesian)
  {
    scenario.hrQuotaInitializer = OneMarketCompetition.KEYNESIAN_STOCKOUT_QUOTA;
    scenario.salesInitializer = (ZeroKnowledgeTrader trader) {
      trader.predictor = new LastPricePredictor();
      trader.dawnEvents.add(BurnInventories());
    };
    //this is the default
    // multiplier when using  PROFIT_MAXIMIZER_PRICING
    scenario.salesPricingInitialization = OneMarketCompetition.PROFIT_MAXIMIZER_PRICING;
  }
  else {
    scenario.hrQuotaInitializer = OneMarketCompetition.MARSHALLIAN_QUOTA;
    scenario.salesPricingInitialization = OneMarketCompetition.BUFFER_PID;
  }

  model.scenario = scenario;
  model.start();

  Market gas = model.markets["gas"];
  Market labor = model.markets["labor"];


  for (int i = 0; i < 10000; i++) {
    model.schedule.simulateDay();

  }


  expect(gas.averageClosingPrice, closeTo(18.0, 1.5));
  expect(gas.quantityTraded, closeTo(9.0, 1.5));
  expect(labor.averageClosingPrice, closeTo(1.0, 0.0));
  expect(labor.quantityTraded, closeTo(81.0, 2.5));



}


oneMarketTest(bool learned, bool pidMaximizer, [int competitors=1])
{
  Directory testDirectory = new Directory("${findRootFolder()}${Platform.pathSeparator}test${Platform.pathSeparator}model${Platform.pathSeparator}engine");
  File defaultParameters = new File("${testDirectory.path}${Platform.pathSeparator}default.json");
  Model model = new Model.fromJSON(defaultParameters.readAsStringSync());

  OneMarketCompetition scenario = model.scenario;
  model.parameters.setField("competitors","default.scenario.OneMarketCompetition",competitors);

  if(pidMaximizer)
    scenario.hrPricingInitialization = OneMarketCompetition.PID_MAXIMIZER_HR;
  else
    scenario.hrPricingInitialization = OneMarketCompetition.MARGINAL_MAXIMIZER_HR;


  //doesn't add slopes when predicting prices
  scenario.salesInitializer = (ZeroKnowledgeTrader sales) {
    if(learned)
      sales.predictor = new FixedSlopePredictor(competitors == 1 ? -1.0 : 0.0);
    else {
      KalmanPricePredictor kalman = new KalmanPricePredictor("outflow",100,0.0,"offeredPrice",.99,10.0);
      //in the original model I used to regress on inflow. I might have to do
      // it here too, but the imperfection resulting out of that is bigger
      // here, so I get about 480/500 right by regressing on inflow and all
      // correct regressing on outflow
      sales.predictor =kalman;
      //because you have inventory buffer, ignore observations that happen
      // during stockouts and  stockups
      kalman.dataValidator = (x,y) {
        if ((sales.pricing as BufferInventoryAdaptive).stockingUp || sales
        .data.getLatestObservation("inventory") == 0) return false;
        else return true;
      };


    }
  };
  scenario.hrIntializer = (ZeroKnowledgeTrader hr) {
    if(learned)
      hr.predictor = new FixedSlopePredictor(competitors == 1 ? 1.0 : 0.0);
    else
      //no inventory no problem.
      hr.predictor = new KalmanPricePredictor("inflow",100,0.0,"offeredPrice",.99,10.0);
  };

  model.scenario = scenario;
  model.start();



  //run the simulation!
  for (int i = 0; i < 10000; i++) {
    model.schedule.simulateDay();
  }
  Market gasMarket = model.markets["gas"];
  Market laborMarket = model.markets["labor"];
  //take average over last 500 days
  List<double> gasPrice = new List(500);
  List<double> wage = new List(500);
  for (int i = 0; i < 500; i++)
  {
    model.schedule.simulateDay();
    gasPrice[i]=gasMarket.averageClosingPrice;
    wage[i]=laborMarket.averageClosingPrice;
  }


  double averageGas= 0.0; gasPrice.forEach((e)=>averageGas+=e);averageGas/=500;
  double averageWage= 0.0; wage.forEach((e)=>averageWage+=e);averageWage/=500;
  double salesSlope = scenario.firms[0].salesDepartments["gas"].predictedSlope;
  double hrSlope = scenario.firms[0].purchasesDepartments["labor"].predictedSlope;


  //expect monopolist making money
  if(competitors==1) {
    expect(gasMarket.averageClosingPrice, closeTo(75,.1));
    expect(laborMarket.averageClosingPrice, closeTo(25,.1));
  }
  else
  {
    expect(averageGas, closeTo(50,6));
    expect(averageWage, closeTo(50,6));
  }


}





