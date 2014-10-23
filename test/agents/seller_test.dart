/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

import 'package:unittest/unittest.dart';
import 'package:lancaster/model/agents/seller.dart';
import 'package:lancaster/model/market/markets.dart';
import 'package:lancaster/model/engine/schedule.dart';
import 'package:lancaster/model/agents/pricing.dart';

//If I start you at price=100 you should be able to find the correct price

main(){
  //demand 100-q, daily inflow = 40===> price 60
  test("works from above!",(){
    LinearDemandMarket market = new LinearDemandMarket(intercept:100.0,slope:-1.0);
    //initial price 100
    FixedInflowSeller seller = new FixedInflowSeller.bufferInventory(40.0,
    market,initialPrice:100.0);



    Schedule schedule = new Schedule();

    market.start(schedule);
    seller.start(schedule);

    for(int i=0; i<200; i++)
    {
      schedule.simulateDay();
      print("price ${seller.lastOfferedPrice} and quantity ${seller.currentOutflow}");
    }
    //should be correct by now
    expect(40,seller.currentOutflow);
    expect(60,seller.lastOfferedPrice);

  });


  test("works from below!",(){
    LinearDemandMarket market = new LinearDemandMarket(intercept:100.0,slope:-1.0);
    //initial price 0
    FixedInflowSeller seller = new FixedInflowSeller.bufferInventory(40.0,
    market,initialPrice:0.0);



    Schedule schedule = new Schedule();

    market.start(schedule);
    seller.start(schedule);

    for(int i=0; i<200; i++)
    {
      schedule.simulateDay();
      print(
          "price ${seller.lastOfferedPrice} and quantity ${seller.currentOutflow}"
      );
    }
    //should be correct by now
    expect(40,seller.currentOutflow);
    expect(60,seller.lastOfferedPrice);

  });



}