/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

library firm.test;

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'dart:math';
import 'package:lancaster/model/lancaster_model.dart';


class MockTrader extends Mock implements ZeroKnowledgeTrader{

  String get goodType=>"mock";

}

main()
{

  //make sure whatever we need gets started correctly
  test("start correctly",(){
    Firm f = new Firm();
    int i=0;
    toStart todo = (f,s){i=1;}; //function changes i to 1, that's how we know
    // it is called
    f.startWhenPossible(todo);
    expect(i,0);
    f.start(new Schedule());
    expect(i,1);



  });

  //make sure whatever we need gets started correctly
  test("start asap",(){
    Firm f = new Firm();
    int i=0;
    //already started
    f.start(new Schedule());
    expect(i,0);
    toStart todo = (f,s){i=1;}; //function changes i to 1, that's how we know
    // it is called
    f.startWhenPossible(todo);
    expect(i,1);
  });


  //registers correctly
  test("Test registers",(){
    Firm f = new Firm();
    ZeroKnowledgeTrader t = new MockTrader();
    f.addSalesDepartment(t);
    expect(f.salesDepartments["mock"],t); //"mock" is defined at the top of
    // this file
    verifyNever(t.start(any));

    f.start(new Schedule());
    verify(t.start(any));

  });


  //buy,sell,produce at a fixed target of 10 workers
  test("Hires, Produces and Sells",(){

    for(int i=0; i<5;i++) {
      var seed = (new Random()).nextInt((1 << 32) - 1);

      Model model = new Model(seed, new SimpleFirmScenario());

      model.start();
      Market gas = model.markets["gas"];
      Market labor = model.markets["labor"];
      Firm firm = model.agents[0] as Firm;
      for (int i = 0; i < 1000; i++) {
        model.schedule.simulateDay();
        /*    print('''gas price: ${gas.averageClosingPrice} workers' wages: ${labor
      .averageClosingPrice}''');
      print('''gas inv: ${firm.hasHowMuch("gas")} workers hired: ${firm
      .hasHowMuch("labor")}''');
      */
      }

      expect(gas.averageClosingPrice, 90.0);
      expect(labor.averageClosingPrice, 10.0);
    }
  });


}