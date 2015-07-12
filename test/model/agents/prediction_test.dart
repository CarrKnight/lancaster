/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

library prediction.test;

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:lancaster/model/lancaster_model.dart';



main(){

  test("Slope changes correctly",(){

    DummyTrader trader = new DummyTrader();
    trader.notifyOfTrade(0.0,100.0,0.0); //set the last closing price

    FixedSlopePredictor sloper = new FixedSlopePredictor(1.0);
    expect(sloper.predictPrice(trader,50.0),150.0);
    expect(sloper.predictPrice(trader,-50.0),50.0);
    sloper.slope=-2.0;
    expect(sloper.predictPrice(trader,50.0),0.0);
    expect(sloper.predictPrice(trader,-50.0),200.0);
  });

  test("horizontal slope kalman",(){

    KalmanPricePredictor learner = new KalmanPricePredictor("testX",
                                                            50,1.0,"testY",.99,10.0);

    int day=0;
    List<double> x = new List();
    List<double> y= new List();

    learner.learn(x,y); //empty should be ignored
    expect(learner.observations,0);
    //x is invalid
    x.add(double.NAN);
    y.add(1.0);
    learner.learn(x,y);
    expect(learner.observations,0);
    //y is invalid
    x.add(-1.0);
    y.add(double.NAN);
    learner.learn(x,y);
    expect(learner.observations,0);
    //add 49 observations
    for(int i=0; i<49;i++)
    {
      expect(learner.observations,i);
      x.add(i.toDouble());
      y.add(0.0);
      learner.learn(x,y);
    }
    expect(learner.observations,49);
    expect(learner.delegate.slope,1.0); //should still be using initial slope
    // because below burnout

    x.add(50.0);
    y.add(0.0);
    learner.learn(x,y);
    expect(learner.delegate.slope,closeTo(0,.1));


  });

  test("embedded y=2*x",(){

    KalmanPricePredictor learner = new KalmanPricePredictor("testX",
    50,1.0,"testY",.99,10.0);

    //create fake trader
    Trader t = new DummyTrader();
    t.notifyOfTrade(0.0,100.0,0.0);

    Schedule schedule = new Schedule();

    Data data = new Data(["testX","testY"],(Map<String,List<double>>ref)=>(s){
      ref["testX"].add(schedule.day.toDouble());
      ref["testY"].add(2.0*schedule.day);
    });

    data.start(schedule);
    learner.start(t,schedule,data);

    for(int i=0; i<100;i++)
      schedule.simulateDay();



    expect(learner.delegate.slope,closeTo(2,.1));
    expect(learner.predictPrice(t,5.0),closeTo(110,.1));


  });
}

