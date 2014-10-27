/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

import 'package:unittest/unittest.dart';
import 'package:mockito/mockito.dart';
import 'package:lancaster/model/lancaster_model.dart';

main(){

  test("events aren't logged before start",()
  {
    StreamsForSellerMarkets streams = new StreamsForSellerMarkets();
    List events = new List();

    //whenever a new trade occurs, put it in the list
    streams.tradeStream.listen((e)=>events.add(e));
    streams.logTrade(null,null,1.0,1.0);
    expect(events.length,0);




  });

  test("listen to stream",()
  {
    StreamsForSellerMarkets streams = new StreamsForSellerMarkets();
    List<TradeEvent> events = new List();

    //whenever a new trade occurs, put it in the list
    Function listener = (TradeEvent e){
      print("called now!");
      events.add(e);
    };
    listener = expectAsync(listener,count:2); //i want this to be called
    // twice!
    streams.tradeStream.listen(listener);
    Schedule s = new Schedule();
    s.simulateDay(); s.simulateDay(); //so we are at day 3
    streams.start(s);

    //log and it will work
    streams.logTrade(null,null,10.0,1.0);
    s.simulateDay(); //day 4
    streams.logTrade(null,null,10.0,1.0);

  });

  test("listen to streams straight from markets",()
  {

    //expect one trade
    Function tradeListener = (TradeEvent e){
      print("trade happened!");
    };
    tradeListener = expectAsync(tradeListener,count:1); //i want this to be called once

    //expect two quotes
    Function quotesListener = (SalesQuoteEvent e){
      print("quotes happened!");
    };
    quotesListener = expectAsync(quotesListener,count:2); //i want this to be called twice


    //setup copy pasted from: "Best Offer wins"
    Schedule schedule = new Schedule();
    LinearDemandMarket market = new LinearDemandMarket(intercept:200.0, slope:-1.0);
    market.start(schedule);
    market.tradeStream.listen(tradeListener);
    market.saleQuotesStream.listen(quotesListener);

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

  });





}