library marketTest;

import 'package:unittest/unittest.dart';
import 'package:mockito/mockito.dart';
import 'package:lancaster/model/lancaster_model.dart';


/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */


class MockDummyTrader extends Mock implements DummyTrader {
}


buyerTests(){

  test("Clears one quote", () {
    Schedule schedule = new Schedule(); //the scheduler

    //create a q=p supply market
    ExogenousBuyerMarket market = new ExogenousBuyerMarket.linear
    (intercept:0.0, slope:1.0);
    market.start(schedule);

    DummyTrader buyer = new DummyTrader();
    market.buyers.add(buyer);

    //try to buy 10 units for 10$ (that's exactly on the slope)
    schedule.schedule(Phase.PLACE_QUOTES, (s) => market.placeBuyerQuote(buyer, 10.0,
    10.0));

    //execute day
    schedule.simulateDay();

    expect(buyer.good, 10.0);
    expect(buyer.money, -100);

    expect(market.quantityTraded, 10.0);
    expect(market.averageClosingPrice, 10.0);
  });


  test("Clears partial quote", () {
    Schedule schedule = new Schedule(); //the scheduler

    //create a q=p supply market
    ExogenousBuyerMarket market = new ExogenousBuyerMarket.linear
    (intercept:0.0, slope:1.0);
    market.start(schedule);

    DummyTrader buyer = new DummyTrader();
    market.buyers.add(buyer);

    //try to buy 20 units for 10$ (only 10 will clear)
    schedule.schedule(Phase.PLACE_QUOTES, (s) => market.placeBuyerQuote(buyer,
                                                                    20.0,10.0));

    //execute day
    schedule.simulateDay();

    expect(buyer.good, 10.0);
    expect(buyer.money, -100);

    expect(market.quantityTraded, 10.0);
    expect(market.averageClosingPrice, 10.0);
  });

  test("best quote wins", () {
    Schedule schedule = new Schedule(); //the scheduler

    //create a q=p supply market
    ExogenousBuyerMarket market = new ExogenousBuyerMarket.linear
    (intercept:0.0, slope:1.0);
    market.start(schedule);

    DummyTrader buyer1 = new DummyTrader();
    DummyTrader buyer2 = new DummyTrader();
    market.buyers.add(buyer1);
    market.buyers.add(buyer2);

    //both want 10, first guy pays 90$ second guy pays 10$. Only the first
    // one gets something
    schedule.schedule(Phase.PLACE_QUOTES, (s) => market.placeBuyerQuote
    (buyer1,10.0,90.0));
    schedule.schedule(Phase.PLACE_QUOTES, (s) => market.placeBuyerQuote
    (buyer2,10.0,10.0));

    //execute day
    schedule.simulateDay();

    expect(buyer1.good, 10.0);
    expect(buyer2.good, 0.0);
    expect(buyer1.money, -900);
    expect(buyer2.money, 0);

    expect(market.quantityTraded, 10.0);
    expect(market.averageClosingPrice, 90.0);
  });


  test("two buyers share", () {
    Schedule schedule = new Schedule(); //the scheduler

    //create a q=p supply market
    ExogenousBuyerMarket market = new ExogenousBuyerMarket.linear
    (intercept:0.0, slope:1.0);
    market.start(schedule);

    DummyTrader buyer1 = new DummyTrader();
    DummyTrader buyer2 = new DummyTrader();
    market.buyers.add(buyer1);
    market.buyers.add(buyer2);

    //both want 5, both get it. Second buyer gets it for less
    schedule.schedule(Phase.PLACE_QUOTES, (s) => market.placeBuyerQuote
    (buyer1,5.0,15.0));
    schedule.schedule(Phase.PLACE_QUOTES, (s) => market.placeBuyerQuote
    (buyer2,5.0,10.0));

    //execute day
    schedule.simulateDay();

    expect(buyer1.good, 5.0);
    expect(buyer2.good, 5.0);
    expect(buyer1.money, -75.0);
    expect(buyer2.money, -50.0);

    expect(market.quantityTraded, 10.0);
    expect(market.averageClosingPrice, 12.5);
  });


  test("Buyer gets notified", () {
    bool called = false;


    Schedule schedule = new Schedule(); //the scheduler

    //create a q=101-p demand market
    ExogenousBuyerMarket market = new ExogenousBuyerMarket.linear(intercept:100.0,
    slope:-1.0);
    market.start(schedule);
    var buyer = new MockDummyTrader();
    market.buyers.add(buyer);


    //try to buy 10 units for 10$
    schedule.schedule(Phase.PLACE_QUOTES, (s) => market.placeBuyerQuote(buyer, 10.0,
    10.0));
    //execute day
    schedule.simulateDay();

    //make sure you were notified
    verify(buyer.notifyOfTrade(any, any));
  });

}


sellerTests() {
  test("Clears one quote", () {
    Schedule schedule = new Schedule(); //the scheduler

    //create a q=101-p demand market
    ExogenousSellerMarket market = new ExogenousSellerMarket.linear(intercept:100.0,
    slope:-1.0);
    market.start(schedule);

    DummyTrader seller = new DummyTrader();
    market.sellers.add(seller);
    seller.receive(10.0); //seller has 10 units of gas it can sell
    //try to sell 10 units for 90$ (that's exactly on the slope)
    schedule.schedule(Phase.PLACE_QUOTES, (s) => market.placeSaleQuote(seller, 10.0, 90.0));

    //execute day
    schedule.simulateDay();

    expect(seller.good, 0);
    expect(seller.money, 900);

    expect(market.quantityTraded, 10.0);
    expect(market.averageClosingPrice, 90.0);
  });

  test("Clears partial quote", () {
    Schedule schedule = new Schedule(); //the scheduler

    //create a q=101-p demand market
    ExogenousSellerMarket market = new ExogenousSellerMarket.linear(intercept:100.0, slope:-1.0);
    market.start(schedule);

    DummyTrader seller = new DummyTrader();
    market.sellers.add(seller);

    seller.receive(20.0); //seller has 20 units of gas it can sell
    //try to sell 20 units for 90$ (only 10 will clear)
    schedule.schedule(Phase.PLACE_QUOTES, (s) => market.placeSaleQuote(seller, 20.0, 90.0));

    //execute day
    schedule.simulateDay();

    expect(seller.good, 10);
    expect(seller.money, 900);
    expect(market.quantityTraded, 10.0);
    expect(market.averageClosingPrice, 90.0);
  });

  test("Best Offer wins", () {
    Schedule schedule = new Schedule(); //the scheduler

    //create a q=200-p demand market
    ExogenousSellerMarket market = new ExogenousSellerMarket.linear(intercept:200.0, slope:-1.0);
    market.start(schedule);

    DummyTrader seller1 = new DummyTrader();
    DummyTrader seller2 = new DummyTrader();
    market.sellers.add(seller1);
    market.sellers.add(seller2);

    seller1.receive(10.0); //both sellers has 10 units of gas it can sell
    seller2.receive(10.0);
    //seller 2 sells at 190$, seller 1 at 191$
    schedule.schedule(Phase.PLACE_QUOTES, (s) => market.placeSaleQuote(seller2, 10.0, 190.0));
    schedule.schedule(Phase.PLACE_QUOTES, (s) => market.placeSaleQuote(seller1, 10.0, 191.0));

    //execute day
    schedule.simulateDay();

    //seller 1 sold nothing
    expect(seller1.good, 10);
    expect(seller1.money, 0);
    //seller 2 sold everything
    expect(seller2.good, 0);
    expect(seller2.money, 1900);
    //market results
    expect(market.quantityTraded, 10.0);
    expect(market.averageClosingPrice, 190.0);
  });


  test("Two sellers share", () {
    Schedule schedule = new Schedule(); //the scheduler

    //create a q=200-p demand market
    ExogenousSellerMarket market = new ExogenousSellerMarket.linear(intercept:200.0, slope:-1.0);
    market.start(schedule);

    DummyTrader seller1 = new DummyTrader();
    DummyTrader seller2 = new DummyTrader();
    market.sellers.add(seller1);
    market.sellers.add(seller2);

    seller1.receive(5.0); //they both have 5 units
    seller2.receive(5.0);
    //they should both sell
    schedule.schedule(Phase.PLACE_QUOTES, (s) => market.placeSaleQuote(seller2, 5.0, 190.0));
    schedule.schedule(Phase.PLACE_QUOTES, (s) => market.placeSaleQuote(seller1, 5.0, 190.0));

    //execute day
    schedule.simulateDay();

    //seller 1 sold everthing
    expect(seller1.good, 0);
    expect(seller1.money, 190 * 5.0);
    //seller 2 sold everything
    expect(seller2.good, 0);
    expect(seller2.money, 190 * 5.0);

    //market results
    expect(market.quantityTraded, 10.0);
    expect(market.averageClosingPrice, 190.0);
  });


  test("Seller gets notified", () {
    bool called = false;


    Schedule schedule = new Schedule(); //the scheduler

    //create a q=101-p demand market
    ExogenousSellerMarket market = new ExogenousSellerMarket.linear(intercept:100.0,
    slope:-1.0);
    market.start(schedule);
    var seller = new MockDummyTrader();
    market.sellers.add(seller);


    seller.receive(10.0); //seller has 10 units of gas it can sell
    //try to sell 10 units for 90$ (that's exactly on the slope)
    schedule.schedule(Phase.PLACE_QUOTES, (s) => market.placeSaleQuote(seller, 10.0, 90.0));
    //execute day
    schedule.simulateDay();

    //make sure you were notified
    verify(seller.notifyOfTrade(any, any));
  });
}

void main() {
  buyerTests();
  sellerTests();

}