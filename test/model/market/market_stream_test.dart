/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

import 'package:unittest/unittest.dart';
import 'package:mockito/mockito.dart';
import 'package:lancaster/model/lancaster_model.dart';

main(){

  test("events aren't logged before start 1",()
  {
    TradeStream tradeStream = new TradeStream();
    List events = new List();

    //whenever a new trade occurs, put it in the list
    tradeStream.stream.listen((e)=>events.add(e));
    tradeStream.log(null,null,1.0,1.0);
    expect(events.length,0);




  });

  test("events aren't logged before start 2",()
  {
    QuoteStream tradeStream = new QuoteStream();
    List events = new List();

    //whenever a new trade occurs, put it in the list
    tradeStream.stream.listen((e)=>events.add(e));
    tradeStream.log(null,1.0,1.0);
    expect(events.length,0);




  });

  test("listen to stream",()
  {
    TradeStream tradeStream = new TradeStream();
    List<TradeEvent> events = new List();

    //whenever a new trade occurs, put it in the list
    Function listener = (TradeEvent e){
      print("called now!");
      events.add(e);
    };
    listener = expectAsync(listener,count:2); //i want this to be called
    // twice!
    tradeStream.stream.listen(listener);
    Schedule s = new Schedule();
    s.simulateDay(); s.simulateDay(); //so we are at day 3
    tradeStream.start(s);

    //log and it will work
    tradeStream.log(null,null,10.0,1.0);
    s.simulateDay(); //day 4
    tradeStream.log(null,null,10.0,1.0);

  });

  test("listen to streams straight from markets",()
  {

    //expect one trade
    Function tradeListener = (TradeEvent e){
      print("trade happened!");
    };
    tradeListener = expectAsync(tradeListener,count:1); //i want this to be called once

    //expect two quotes
    Function quotesListener = (QuoteEvent e){
      print("quotes happened!");
    };
    quotesListener = expectAsync(quotesListener,count:2); //i want this to be called twice


    //setup copy pasted from: "Best Offer wins"
    Schedule schedule = new Schedule();
    ExogenousSellerMarket market = new ExogenousSellerMarket.linear(intercept:200.0, slope:-1.0);
    market.start(schedule);
    market.tradeStream.listen(tradeListener);
    market.asksStream.listen(quotesListener);

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

  });





}