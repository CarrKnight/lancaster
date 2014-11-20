/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

import 'package:unittest/unittest.dart';
import 'package:lancaster/model/lancaster_model.dart';


//If I start you at price=100 you should be able to find the correct price

main(){
  //demand 100-q, daily inflow = 40===> price 60
  test("works from above!",(){
    ExogenousSellerMarket market = new ExogenousSellerMarket.linear(intercept:100.0,slope:-1.0);
    //initial price 100
    ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader.PIDBufferSellerFixedInflow(40.0,
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
    ExogenousSellerMarket market = new ExogenousSellerMarket.linear(intercept:100.0,slope:-1.0);
    //initial price 0
    ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader.PIDBufferSellerFixedInflow(40.0,
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

  test("zk department doesn't reset counters",(){
    ExogenousSellerMarket market = new ExogenousSellerMarket.linear(intercept:100.0,slope:-1.0);
    //initial price 100
    var realInventory = new Inventory();
    ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader.PIDBufferSellerFixedInflow(40.0,
    market,initialPrice:100.0,givenInventory:realInventory);



    Schedule schedule = new Schedule();

    market.start(schedule);
    seller.start(schedule);

    //has fixed inflow of 40
    expect(0,realInventory.inflow("gas"));
    schedule.simulateDay();
    expect(40,realInventory.inflow("gas"));
    schedule.simulateDay();
    expect(80,realInventory.inflow("gas")); //doesn't reset!


  });

}