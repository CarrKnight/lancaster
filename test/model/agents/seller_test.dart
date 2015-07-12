/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

import 'package:test/test.dart';
import 'package:lancaster/model/lancaster_model.dart';


//If I start you at price=100 you should be able to find the correct price

main(){

  nonGeographical();

  //demand 100 people from 0 to 100 each buying one unit of stuff, all at location 0,0 and a seller
  //at location 0,0 trying to sell 40 units of goods: should discover the price is 60
  test("Geographically challenged",(){
    GeographicalMarket market = new GeographicalMarket(CartesianDistance);
    //initial price 100
    ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader.PIDBufferSellerFixedInflow(40.0,
                                                                                    market,initialPrice:100.0,
                                                                                    location: new Location([0,0]));
    Schedule schedule = new Schedule();
    market.start(schedule,null); //model reference not needed


    for(int i=0; i<100; i++)
    {
      //each buyer buys 1 unit every day at the same price, if possible
      ZeroKnowledgeTrader buyer = new ZeroKnowledgeTrader(market, new FixedValue(i), new FixedValue(1),
                                                          new GeographicalBuyerTrading(new Location([0,0])),
                                                          new Inventory());
      buyer.dawnEvents.add(BurnInventories());
      buyer.start(schedule);
    }


    seller.start(schedule);

    for(int i=0; i<200; i++)
    {
      schedule.simulateDay();
    }
    //should be correct by now
    expect(40,seller.currentOutflow);
    expect(60,seller.lastOfferedPrice);

  });


  //demand 2 people, one willing to pay 100 but distance is 200, the other willing to pay 10 but very close
  //seller has 1 unit of good to sell, will sell to second buyer
  test("Close poor beat rich but far",(){
    GeographicalMarket market = new GeographicalMarket(CartesianDistance);
    //initial price 100
    ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader.PIDBufferSellerFixedInflow(1.0,
                                                                                    market,initialPrice:100.0,
                                                                                    location: new Location([0,0]));
    Schedule schedule = new Schedule();
    market.start(schedule,null); //model reference not needed



    //each buyer buys 1 unit every day at the same price, if possible
    ZeroKnowledgeTrader buyer1 = new ZeroKnowledgeTrader(market, new FixedValue(100), new FixedValue(1),
                                                         new GeographicalBuyerTrading(new Location([100,100])),
                                                         new Inventory());
    buyer1.dawnEvents.add(BurnInventories());
    buyer1.start(schedule);

    ZeroKnowledgeTrader buyer2 = new ZeroKnowledgeTrader(market, new FixedValue(10), new FixedValue(1),
                                                         new GeographicalBuyerTrading(new Location([0,0])),
                                                         new Inventory());
    buyer2.dawnEvents.add(BurnInventories());
    buyer2.start(schedule);


    seller.start(schedule);

    for(int i=0; i<2000; i++)
    {
      schedule.simulateDay();
    }
    //should be correct by now
    expect(1,seller.currentOutflow);
    expect(10,seller.lastOfferedPrice);

  });

}


void nonGeographical(){
  //demand 100-q, daily inflow = 40===> price 60
  test("works from above!",(){
    ExogenousSellerMarket market = new ExogenousSellerMarket.linear(intercept:100.0,slope:-1.0);
    //initial price 100
    ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader.PIDBufferSellerFixedInflow(40.0,
                                                                                    market,initialPrice:100.0);



    Schedule schedule = new Schedule();

    market.start(schedule,null); //model reference not needed
    seller.start(schedule);

    for(int i=0; i<200; i++)
    {
      schedule.simulateDay();
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

    market.start(schedule,null); //model reference not needed
    seller.start(schedule);

    for(int i=0; i<200; i++)
    {
      schedule.simulateDay();
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

    market.start(schedule,null); //model reference not needed
    seller.start(schedule);

    //has fixed inflow of 40
    expect(0,realInventory.inflow("gas"));
    schedule.simulateDay();
    expect(40,realInventory.inflow("gas"));
    schedule.simulateDay();
    expect(80,realInventory.inflow("gas")); //doesn't reset!


  });

}