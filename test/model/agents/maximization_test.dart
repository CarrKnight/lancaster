/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

library maximization.test;
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:lancaster/model/lancaster_model.dart';
import 'dart:math';

class MockTrader extends Mock implements Trader{}



main(){

  test("climb mount fuji",(){

    Random random = new Random();
    MarginalMaximizer maximizer = new MarginalMaximizer(1.0,1.0,1.0/21.0);
    double currentX = maximizer.extract(null);
    expect(currentX,1.0);
    maximizer.delta=.5; //increase by .5 steps
    maximizer.updateProbability=1.0;

    //prices are: 100-x
    var seller = new MockTrader();
    //make sure only deltas get called
    when(seller.predictPrice(.5)).thenReturn( 100-currentX-.5);
    when(seller.predictPrice(0.0)).thenReturn( 100-currentX );
    when(seller.predictPrice(-.5)).thenReturn( 100-currentX+.5);

    //fixed costs: x
    var buyer = new MockTrader();
    when(buyer.predictPrice(.5)).thenReturn(currentX+.5);
    when(buyer.predictPrice(0.0)).thenReturn(currentX);
    when(buyer.predictPrice(-.5)).thenReturn(currentX-.5);

    //production: 1 input ==> 1 output
    LinearProductionFunction func = new LinearProductionFunction(true,1.0);

    //step it 100 times
    for(int i=0; i<100;i++)
    {
      maximizer.updateTarget(random,buyer,seller,func,currentX);
      currentX = maximizer.extract(null);

      //reset mocks
      when(seller.predictPrice(.5)).thenReturn( 100-currentX-.5);
      when(seller.predictPrice(0.0)).thenReturn( 100-currentX );
      when(seller.predictPrice(-.5)).thenReturn( 100-currentX+.5);
      when(buyer.predictPrice(.5)).thenReturn(currentX+.5);
      when(buyer.predictPrice(0.0)).thenReturn(currentX);
      when(buyer.predictPrice(-.5)).thenReturn(currentX-.5);
    }
    print("current $currentX");
    //maximum is at 25
    expect(currentX,25.0);

  });

  test("climb mount fuji in reverse",(){

    Random random = new Random();
    MarginalMaximizer maximizer = new MarginalMaximizer(1.0,1.0,1.0/21.0);
    maximizer.currentTarget = 50.0;
    double currentX = maximizer.extract(null);
    expect(currentX,50.0);
    maximizer.delta=.5; //increase by .5 steps
    maximizer.updateProbability=1.0;

    //prices are: 100-x
    var seller = new MockTrader();
    //make sure only deltas get called
    when(seller.predictPrice(.5)).thenReturn( 100-currentX-.5);
    when(seller.predictPrice(0.0)).thenReturn( 100-currentX );
    when(seller.predictPrice(-.5)).thenReturn( 100-currentX+.5);

    //fixed costs: x
    var buyer = new MockTrader();
    when(buyer.predictPrice(.5)).thenReturn(currentX+.5);
    when(buyer.predictPrice(0.0)).thenReturn(currentX);
    when(buyer.predictPrice(-.5)).thenReturn(currentX-.5);

    //production: 1 input ==> 1 output
    LinearProductionFunction func = new LinearProductionFunction(true,1.0);

    //step it 100 times
    for(int i=0; i<100;i++)
    {
      maximizer.updateTarget(random,buyer,seller,func,currentX);
      currentX = maximizer.extract(null);

      //reset mocks
      when(seller.predictPrice(.5)).thenReturn( 100-currentX-.5);
      when(seller.predictPrice(0.0)).thenReturn( 100-currentX );
      when(seller.predictPrice(-.5)).thenReturn( 100-currentX+.5);
      when(buyer.predictPrice(.5)).thenReturn(currentX+.5);
      when(buyer.predictPrice(0.0)).thenReturn(currentX);
      when(buyer.predictPrice(-.5)).thenReturn(currentX-.5);
    }
    print("current $currentX");

    //maximum is at 25
    expect(currentX,25.0);

  });


  test("climb mount fuji PID",(){

    Random random = new Random();
    PIDMaximizer maximizer = new PIDMaximizer(random,1,1.0,1.0);
    double currentX = maximizer.extract(null);
    expect(currentX,1.0);
    maximizer.delta=1.0; //increase by 1.0 steps

    //prices are: 100-x
    var seller = new MockTrader();
    //make sure only deltas get called
    when(seller.predictPrice(1.0)).thenReturn( 100-currentX-1.0);
    when(seller.predictPrice(0.0)).thenReturn( 100-currentX );
    when(seller.predictPrice(-1.0)).thenReturn( 100-currentX+1.0);

    //fixed costs: x
    var buyer = new MockTrader();
    when(buyer.predictPrice(1.0)).thenReturn(currentX+1.0);
    when(buyer.predictPrice(0.0)).thenReturn(currentX);
    when(buyer.predictPrice(-1.0)).thenReturn(currentX-1.0);

    //production: 1 input ==> 1 output
    LinearProductionFunction func = new LinearProductionFunction(true,1.0);

    //step it 100 times
    for(int i=0; i<10000;i++)
    {
      maximizer.updateTarget(buyer,seller,func,currentX);
      currentX = maximizer.extract(null);

      //reset mocks
      when(seller.predictPrice(1.0)).thenReturn( 100-currentX-1.0);
      when(seller.predictPrice(0.0)).thenReturn( 100-currentX );
      when(seller.predictPrice(-1.0)).thenReturn( 100-currentX+1.0);
      when(buyer.predictPrice(1.0)).thenReturn(currentX+1.0);
      when(buyer.predictPrice(0.0)).thenReturn(currentX);
      when(buyer.predictPrice(-1.0)).thenReturn(currentX-1.0);
      print("current $currentX");

    }
    print("current $currentX");
    //maximum is at 25
    expect(currentX,25.0);

  });



}