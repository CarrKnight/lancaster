/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
library one_market.test;
import 'package:unittest/unittest.dart';
import 'package:lancaster/model/lancaster_model.dart';


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

      learnedCompetitorTest(5);

    });

  for(int i=0;i<5;i++)
    test("Learned Monopolist", (){ //knows the price impacts
      monopolistTest(true);
    });

  for(int i=0;i<5;i++)
    test("Learnin Monopolist", (){ //knows the price impacts
      monopolistTest(false);
    });

}

monopolistTest(bool learned)
{
  Model model = new Model.randomSeed();
  OneMarketCompetition scenario = new OneMarketCompetition();
  //doesn't add slopes when predicting prices
  scenario.salesInitializer = (ZeroKnowledgeTrader sales) {
    if(learned)
      sales.predictor = new FixedSlopePredictor(-1.0);
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
        if ((sales.pricing as BufferInventoryPricing).stockingUp || sales
        .data.getLatestObservation("inventory") == 0) return false;
        else return true;
      };


    }
  };
  scenario.hrIntializer = (ZeroKnowledgeTrader hr) {
    if(learned)
      hr.predictor = new FixedSlopePredictor(1.0);
    else
    //no inventory no problem.
      hr.predictor = new KalmanPricePredictor("inflow");
  };

  model.scenario = scenario;
  model.start();

  Market gas = model.markets["gas"];
  Market labor = model.markets["labor"];

  for (int i = 0; i < 3000; i++) {
    model.schedule.simulateDay();
  }

  print('''gas price: ${gas.averageClosingPrice} workers' wages: ${labor
  .averageClosingPrice}\n''');
  double salesSlope = scenario.firms[0].salesDepartments["gas"].predictedSlope;
  double hrSlope = scenario.firms[0].purchasesDepartments["labor"]
  .predictedSlope;
  print("sales slope: $salesSlope hr slope: $hrSlope\n");

  //expect monopolist making money
  expect(gas.averageClosingPrice,75);
  expect(labor.averageClosingPrice,25);
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
