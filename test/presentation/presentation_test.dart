/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

library presentationtests;

import 'package:test/test.dart';
import 'package:lancaster/model/lancaster_model.dart';
import 'package:lancaster/presentation/lancaster_presentation.dart';
import 'dart:collection';
import 'package:observe/src/change_record.dart';
import 'package:observe/src/observable_map.dart';
import 'dart:io';
import 'dart:async';

main()
{

  test("instantiate a presentation",(){
    //original model
    Model model = new Model(1,new SimpleSellerScenario.buffer());
    //presentation
    ModelPresentation presentation = new ModelPresentation(model);
    //should have a presentation object!
    expect(presentation.gasPresentation!=null,true);
    expect(presentation.gasPresentation.tradeStream!=null,true);
  });

  test("streams fine",(){
    //original model
    Model model = new Model(1,new SimpleSellerScenario.buffer());
    //presentation
    ModelPresentation presentation = new ModelPresentation(model);

    //three days should give me 3 events!
    Function listener = (MarketEvent e){
      print("called now!");
    };
    listener = expectAsync(listener,count:3);
    presentation.gasPresentation.stream.listen(listener);

    model.schedule.simulateDay();
    model.schedule.simulateDay();
    model.schedule.simulateDay();



  });

  test("stores data fine",() async{
    //original model
    var simpleSellerScenario = new SimpleSellerScenario.buffer(intercept:200.0,
                                                               slope:-2.0,
                                                               dailyFlow:10.0);
    Model model = new Model(1, simpleSellerScenario);
    //presentation
    ModelPresentation presentation = new ModelPresentation.SimpleSeller(model,
                                                                        simpleSellerScenario);
//three days should give me 3 events!
    Function listener = (MarketEvent e){
      print("called now!");
    };

    var subscription = presentation.gasPresentation.stream.take(3).listen(listener).asFuture();


    model.schedule.simulateDay();
    model.schedule.simulateDay();
    model.schedule.simulateDay();
    await subscription;
    expect(presentation.gasPresentation.marketEvents.length,3);
    expect(presentation.gasPresentation.dailyObservations["Price"].length,3);




  });



  test("geographical presentation streams location changes",() async{

    GeographicalMarket market = new GeographicalMarket( CartesianDistance);
    GeographicalMarketPresentation presentation = new GeographicalMarketPresentation(market);

    //we should be able to fill this by just copying whatever comes out of the stream
    Map<Trader,Location> filledByStream = new HashMap();


    //this function listens to stream events to fills the map


    //listen to the stream
    var subscription =presentation.movementStream.take(5).listen((MovementEvent e){
      if(e.newLocation == null)
        filledByStream.remove(e.mover);
      else
        filledByStream[e.mover] = e.newLocation;
    }).asFuture();







    Trader t1 = new DummyTrader("alpha");
    Trader t2 = new DummyTrader("beta");
    Trader t3 = new DummyTrader("gamma");
    Location l1 = new Location.TwoD(1,1);
    Location l2 = new Location.TwoD(2,2);
    Location l3 = new Location.TwoD(3,3);
    Locator locator1 = new Locator(t1, l1);
    Locator locator2 = new Locator(t2, l2);
    Locator locator3 = new Locator(t3, l3);

    market.registerLocator(t1, locator1);
    market.registerLocator(t2, locator2);
    market.registerLocator(t3, locator3);
    locator2.location=l3;
    market.deregisterLocator(t3);

    await subscription;

    print("tested $filledByStream");

  //  await presentation.locationStream.first;



    print("testing");
    expect(filledByStream[t1],l1);
    expect(filledByStream[t2],l3);
    expect(filledByStream.length,2,reason: "$filledByStream");





  });


  test("going insane",(){


    Map map = new ObservableMap();
    map["ahahah"] = 1;
    map["ahahahz"] = 2;
    expect(map.length,2);
    map.remove("ahahah");
    expect(map.length,1);


  });

}