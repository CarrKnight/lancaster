/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
library one_market.test;
import 'package:unittest/unittest.dart';
import 'package:lancaster/model/lancaster_model.dart';
import 'package:lancaster/runs/yackm.dart';
import 'dart:math';





KeynesianInfiniteElasticity(bool marketDayOnly) {
  Model model = new Model.randomSeed();
  OneMarketCompetition experiment = new
  OneMarketCompetition()
    ..minInitialPriceSelling = 2.5
    ..maxInitialPriceSelling = 2.5
    ..laborMarket = new ExogenousBuyerMarket.infinitelyElastic(1.0,
  goodType:"labor")
    ..goodMarket = new ExogenousSellerMarket.linear(intercept:3.0,slope:-1.0);
  model.scenario = experiment;

  //small demand, requires small adjustments, this "P" actually is a
  // multiplier when using  PROFIT_MAXIMIZER_PRICING
  experiment.salesMinP = 1.0;
  experiment.salesMaxP = 1.0;


  if(marketDayOnly)
    experiment.salesPricingInitialization =
    OneMarketCompetition.FIXED_PRICE;
  else
    experiment.salesPricingInitialization =
    OneMarketCompetition.PROFIT_MAXIMIZER_PRICING;

  experiment.hrPricingInitialization = (SISOPlant plant,
                                        Firm firm,  Random r,  ZeroKnowledgeTrader seller,
                                        OneMarketCompetition scenario)=> new FixedValue(1.0);
  experiment.hrQuotaInitializer = OneMarketCompetition.KEYNESIAN_QUOTA;


  model.start();

  Market gas = model.markets["gas"];
  Market labor = model.markets["labor"];

  for (int i = 0; i < 5000; i++) {
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
      oneMarketTest(true,false);
    });

  for(int i=0;i<5;i++)
    test("Learning Monopolist", (){ //knows the price impacts
      oneMarketTest(false,false);
    });

  for(int i=0;i<5;i++)
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

}




oneMarketTest(bool learned, bool pidMaximizer, [int competitors=1])
{
  Model model = new Model.randomSeed();
  OneMarketCompetition scenario = new OneMarketCompetition();
  scenario.competitors = competitors;

  if(pidMaximizer)
    scenario.hrPricingInitialization = OneMarketCompetition.PID_MAXIMIZER_HR;

  //doesn't add slopes when predicting prices
  scenario.salesInitializer = (ZeroKnowledgeTrader sales) {
    if(learned)
      sales.predictor = new FixedSlopePredictor(competitors == 1 ? -1.0 : 0.0);
    else {
      KalmanPricePredictor kalman = new KalmanPricePredictor("outflow");
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
      hr.predictor = new KalmanPricePredictor("inflow");
  };

  model.scenario = scenario;
  model.start();



  //run the simulation!
  for (int i = 0; i < 2500; i++) {
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
  print('''gas price: ${gasMarket.averageClosingPrice} workers' wages: ${laborMarket
  .averageClosingPrice}\n''');
  print("sales slope: $salesSlope hr slope: $hrSlope\n");

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





