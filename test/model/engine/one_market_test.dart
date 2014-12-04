/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
library one_market.test;
import 'package:unittest/unittest.dart';
import 'package:lancaster/model/lancaster_model.dart';


main2()
{

  //one agent working as competitive
  for(int i=0;i<5;i++)
    test("Fake competitive", (){

      learnedCompetitorTest(1);


    });

  //five agents, all learned
  for(int i=0;i<5;i++)
    test("Learned competitive", (){

      oneMarketTest(true,5);

    });

  //five agents, learning
  //fails about 3% of the time, unfortunately
  for(int i=0;i<5;i++)
    test("Learning competitive", (){

      oneMarketTest(false,5);

    });

  for(int i=0;i<5;i++)
    test("Learned Monopolist", (){ //knows the price impacts
      oneMarketTest(true);
    });

  for(int i=0;i<5;i++)
    test("Learning Monopolist", (){ //knows the price impacts
      oneMarketTest(false);
    });

}

oneMarketTest(bool learned, [int competitors=1])
{
  Model model = new Model.randomSeed();
  OneMarketCompetition scenario = new OneMarketCompetition();
  scenario.competitors = competitors;

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
    expect(gasMarket.averageClosingPrice, 75);
    expect(laborMarket.averageClosingPrice, 25);
  }
  else
  {
    expect(averageGas, closeTo(50,5));
    expect(averageWage, closeTo(50,5));
  }


}


learnedCompetitorTest(int competitors)
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

  model.scenario = scenario;
  model.start();

  Market gas = model.markets["gas"];
  Market labor = model.markets["labor"];

  for (int i = 0; i < 3000; i++) {
    model.schedule.simulateDay();
  }

  print('''gas price: ${gas.averageClosingPrice} workers' wages: ${labor
  .averageClosingPrice}''');
  expect(gas.averageClosingPrice,closeTo(50.0,1.5));
  expect(gas.quantityTraded,closeTo(50.0,1.5));
  expect(labor.averageClosingPrice,closeTo(50.0,1.5));
  expect(labor.quantityTraded,closeTo(50.0,1.5));
  expect(model.agents.length,competitors);
}


main()
{
  test("Can solve market days by changing L",(){

    Model model = new Model.randomSeed();
    InfiniteElasticLaborKeynesianExperiment experiment = new
    InfiniteElasticLaborKeynesianExperiment()
    ..minInitialPriceSelling=2.5
    ..maxInitialPriceSelling=2.5;
    model.scenario = experiment;

    model.start();

    Market gas = model.markets["gas"];
    Market labor = model.markets["labor"];

    for (int i = 0; i < 3000; i++) {
      model.schedule.simulateDay();

    }
    print('''gas price: ${gas.averageClosingPrice} workers' wages: ${labor
    .averageClosingPrice}''');
    print('''gas quantity: ${gas.quantityTraded} workers : ${labor
    .quantityTraded}''');

    //should have throttled production more
    expect(gas.quantityTraded,.5);
    expect(labor.quantityTraded,.5);


  });


}