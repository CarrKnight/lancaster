/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

library firm.test;

import 'package:mockito/mockito.dart';
import 'package:unittest/unittest.dart';
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
}