library marketTest;

import 'package:unittest/unittest.dart';
import 'package:mockito/mockito.dart';
import 'package:lancaster/model/lancaster_model.dart';


/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */


class MockDummySeller extends Mock implements DummySeller{}


void main() {

  test("Clears one quote", () {
    Schedule schedule = new Schedule(); //the scheduler

    //create a q=101-p demand market
    LinearDemandMarket market = new LinearDemandMarket(intercept:100, slope:-1.0);
    market.start(schedule);

    DummySeller seller = new DummySeller();
    market.registerSeller(seller);
    seller.receive(10.0); //seller has 10 units of gas it can sell
    //try to sell 10 units for 90$ (that's exactly on the slope)
    schedule.schedule(Phase.PLACE_QUOTES, (s) => market.placeSaleQuote(seller, 10.0, 90.0));

    //execute day
    schedule.simulateDay();

    expect(seller.gas, 0);
    expect(seller.money, 900);

    expect(market.quantitySold,10.0);
    expect(market.averageClosingPrice,90.0);
  });

  test("Clears partial quote", () {
    Schedule schedule = new Schedule(); //the scheduler

    //create a q=101-p demand market
    LinearDemandMarket market = new LinearDemandMarket(intercept:100.0, slope:-1.0);
    market.start(schedule);

    DummySeller seller = new DummySeller();
    market.registerSeller(seller);

    seller.receive(20.0); //seller has 20 units of gas it can sell
    //try to sell 20 units for 90$ (only 10 will clear)
    schedule.schedule(Phase.PLACE_QUOTES, (s) => market.placeSaleQuote(seller, 20.0, 90.0));

    //execute day
    schedule.simulateDay();

    expect(seller.gas, 10);
    expect(seller.money, 900);
    expect(market.quantitySold,10.0);
    expect(market.averageClosingPrice,90.0);
  });

  test("Best Offer wins", () {
    Schedule schedule = new Schedule(); //the scheduler

    //create a q=200-p demand market
    LinearDemandMarket market = new LinearDemandMarket(intercept:200.0, slope:-1.0);
    market.start(schedule);

    DummySeller seller1 = new DummySeller();
    DummySeller seller2 = new DummySeller();
    market.registerSeller(seller1);
    market.registerSeller(seller2);

    seller1.receive(10.0); //both sellers has 10 units of gas it can sell
    seller2.receive(10.0);
    //seller 2 sells at 190$, seller 1 at 191$
    schedule.schedule(Phase.PLACE_QUOTES, (s) => market.placeSaleQuote(seller2, 10.0, 190.0));
    schedule.schedule(Phase.PLACE_QUOTES, (s) => market.placeSaleQuote(seller1, 10.0, 191.0));

    //execute day
    schedule.simulateDay();

    //seller 1 sold nothing
    expect(seller1.gas, 10);
    expect(seller1.money, 0);
    //seller 2 sold everything
    expect(seller2.gas, 0);
    expect(seller2.money, 1900);
    //market results
    expect(market.quantitySold,10.0);
    expect(market.averageClosingPrice,190.0);
  });


  test("Two sellers share", () {
    Schedule schedule = new Schedule(); //the scheduler

    //create a q=200-p demand market
    LinearDemandMarket market = new LinearDemandMarket(intercept:200.0, slope:-1.0);
    market.start(schedule);

    DummySeller seller1 = new DummySeller();
    DummySeller seller2 = new DummySeller();
    market.registerSeller(seller1);
    market.registerSeller(seller2);

    seller1.receive(5.0); //they both have 5 units
    seller2.receive(5.0);
    //they should both sell
    schedule.schedule(Phase.PLACE_QUOTES, (s) => market.placeSaleQuote(seller2, 5.0, 190.0));
    schedule.schedule(Phase.PLACE_QUOTES, (s) => market.placeSaleQuote(seller1, 5.0, 190.0));

    //execute day
    schedule.simulateDay();

    //seller 1 sold everthing
    expect(seller1.gas, 0);
    expect(seller1.money, 190 * 5.0);
    //seller 2 sold everything
    expect(seller2.gas, 0);
    expect(seller2.money, 190 * 5.0);

    //market results
    expect(market.quantitySold,10.0);
    expect(market.averageClosingPrice,190.0);
  });


  test("Seller gets notified", () {
    bool called = false;


    Schedule schedule = new Schedule(); //the scheduler

    //create a q=101-p demand market
    LinearDemandMarket market = new LinearDemandMarket(intercept:100, slope:-1.0);
    market.start(schedule);
    var seller = new MockDummySeller();
    market.registerSeller(seller);



    seller.receive(10.0); //seller has 10 units of gas it can sell
    //try to sell 10 units for 90$ (that's exactly on the slope)
    schedule.schedule(Phase.PLACE_QUOTES, (s) => market.placeSaleQuote(seller, 10.0, 90.0));
    //execute day
    schedule.simulateDay();

    //make sure you were notified
    verify(seller.notifyOfTrade(any,any));
  });

}