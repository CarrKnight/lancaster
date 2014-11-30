/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
library model.test;
import 'package:unittest/unittest.dart';
import 'package:lancaster/model/lancaster_model.dart';
import 'dart:math';


main(){

  test("simple seller scenario",(){

    Model model = new Model(0,new SimpleScenario.simpleSeller());
    model.start();


    Trader seller = model.agents.first as Trader;

    for(int i=0; i<200; i++)
    {
      model.schedule.simulateDay();

    }
    print(
        "price ${seller.lastOfferedPrice} and quantity ${seller.currentOutflow}"
    );
    Market gasMarket = model.markets["gas"];

    //should be correct by now
    expect(40,seller.currentOutflow);
    expect(60,seller.lastOfferedPrice);
    expect(gasMarket.quantityTraded,40);
    expect(gasMarket.averageClosingPrice,60);
  });



  for(int j=0; j<5; j++)
    test("4 competitors seller",(){

      var seed = (new Random()).nextInt((1 << 32) - 1);
      Model model = new Model(0,new SimpleScenario.simpleSeller(minInitialPrice: 0.0,
      maxInitialPrice : 100.0,competitors:4,dailyFlow:10.0,
      seed: seed));
      model.start();



      print("seed: $seed");
      for(int i=0; i<200; i++)
      {
        model.schedule.simulateDay();
        List<double> offers = [];
        for(Object a in model.agents)
          offers.add((a as Trader).lastOfferedPrice);
        print(offers);

      }
      Market gasMarket = model.markets["gas"];

      print(
          "price ${gasMarket.averageClosingPrice} and quantity ${gasMarket.quantityTraded}"
      );

      //should be correct by now
      expect(gasMarket.quantityTraded,closeTo(40,1.5));
      expect(gasMarket.averageClosingPrice,closeTo(60,1.5));
    });



  test("simple buyer scenario",(){

    Model model = new Model(0,new SimpleScenario.simpleBuyer());
    model.start();


    Trader buyer = model.agents.first as Trader;

    for(int i=0; i<200; i++)
    {
      model.schedule.simulateDay();

    }
    print(
        "price ${buyer.lastOfferedPrice} and quantity ${buyer.currentOutflow}"
    );
    //should be correct by now
    expect(40,buyer.currentInflow);
    expect(40,buyer.lastOfferedPrice);
    Market gasMarket = model.markets["gas"];
    expect(gasMarket.quantityTraded,40);
    expect(gasMarket.averageClosingPrice,40);
  });

  for(int j=0; j<5; j++)

    test("4 competitors buyers",(){
      var seed = (new Random()).nextInt((1 << 32) - 1);

      Model model = new Model(0,new SimpleScenario.simpleBuyer(minInitialPrice: 0.0,
      maxInitialPrice : 100.0,competitors:4,dailyTarget:10.0,
      seed: seed));
      model.start();


      for(int i=0; i<200; i++)
      {
        model.schedule.simulateDay();
        List<double> offers = [];
        for(Object a in model.agents)
          offers.add((a as Trader).lastOfferedPrice);
        print(offers);

      }
      Market gasMarket = model.markets["gas"];

      print(
          "price ${gasMarket.averageClosingPrice} and quantity ${gasMarket.quantityTraded}"
      );
      //should be correct by now
      expect(gasMarket.quantityTraded,closeTo(40,1));
      expect(gasMarket.averageClosingPrice,closeTo(40,1));
    });

}