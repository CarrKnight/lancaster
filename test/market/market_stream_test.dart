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


}