/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
library one_market.test;
import 'package:unittest/unittest.dart';
import 'package:lancaster/model/lancaster_model.dart';
import 'dart:math';


main()
{

  //one agent working as competitive
  test("Fake competitive", (){

    for(int i=0;i<5;i++)
      learnedCompetitorTest(1);


  });

  //five agents, all learned
  test("Fake competitive", (){

    for(int i=0;i<5;i++)
      learnedCompetitorTest(5);


  });


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

  model.scenario = new OneMarketCompetition();
  model.start();

  Market gas = model.markets["gas"];
  Market labor = model.markets["labor"];

  for (int i = 0; i < 3000; i++) {
    model.schedule.simulateDay();
  }

  print('''gas price: ${gas.averageClosingPrice} workers' wages: ${labor
  .averageClosingPrice}''');
  expect(gas.averageClosingPrice,closeTo(50.0,1));
  expect(gas.quantityTraded,closeTo(50.0,1));
  expect(labor.averageClosingPrice,closeTo(50.0,1));
  expect(labor.quantityTraded,closeTo(50.0,1));
}
