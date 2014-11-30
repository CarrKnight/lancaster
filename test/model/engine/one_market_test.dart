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

  for(int i=0;i<500;i++)
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
    else
      sales.predictor = new KalmanPricePredictor("outflow");
  };
  scenario.hrIntializer = (ZeroKnowledgeTrader hr) {
    if(learned)
      hr.predictor = new FixedSlopePredictor(1.0);
    else
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
