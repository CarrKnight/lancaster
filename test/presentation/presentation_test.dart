/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

library presentationtests;

import 'package:unittest/unittest.dart';
import 'package:mockito/mockito.dart';
import 'package:lancaster/model/lancaster_model.dart';
import 'package:lancaster/presentation/lancaster_presentation.dart';

main()
{

  test("instantiate a presentation",(){
    //original model
    Model model = new Model(1,new Scenario.simpleSeller());
    //presentation
    ModelPresentation presentation = new ModelPresentation(model);
    //should have a presentation object!
    expect(presentation.gasPresentation!=null,true);
    expect(presentation.gasPresentation.tradeStream!=null,true);
  });

  test("streams fine",(){
    //original model
    Model model = new Model(1,new Scenario.simpleSeller());
    //presentation
    ModelPresentation presentation = new ModelPresentation(model);

    //three days should give me 3 events!
    Function listener = (MarketEvent e){
      print("called now!");
    };
    listener = expectAsync(listener,count:3);
    presentation.gasPresentation.marketStream.listen(listener);

    model.schedule.simulateDay();
    model.schedule.simulateDay();
    model.schedule.simulateDay();


  });

}