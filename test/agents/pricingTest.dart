/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */


import 'package:unittest/unittest.dart';
import 'package:lancaster/src/agents/pricing.dart';
import 'package:lancaster/src/tools/PIDController.dart';
import 'package:lancaster/src/tools/AgentData.dart';


void main(){

  test("stay still",(){


    //if I set the initial price to 100 and target always equal cv, the price should stay at 100
    PIDPricing pricing = new PIDPricing((data)=>1.0,(data)=>1.0,offset:100.0);
    expect(pricing.price,100);
    for(int i=0; i<100; i++) {
      pricing.updatePrice(new AgentData(["a"],(references)=>(s){}));
      expect(pricing.price,100);
    }

  });


  test("increase",(){


    //if I set the initial price to 100 and target>cv, the price should increase
    PIDPricing pricing = new PIDPricing((data)=>1.0,(data)=>0.0,offset:100.0);
    expect(pricing.price,100);
    for(int i=0; i<100; i++) {
      pricing.updatePrice(new AgentData(["a"],(references)=>(s){}));
      expect(pricing.price > 100,true);
    }

  });

  test("decrease",(){


    //if I set the initial price to 100 and target<cv, the price should decrease
    PIDPricing pricing = new PIDPricing((data)=>-10.0,(data)=>0.0,offset:100.0);
    expect(pricing.price,100);
    for(int i=0; i<100; i++) {
      pricing.updatePrice(new AgentData(["a"],(references)=>(s){}));
      expect(pricing.price < 100 && pricing.price >=0,true);
    }

  });

  test("default seller",(){
    //the seller reverses: inflow is target but when inflow > outflow price go up
    PIDPricing pricing = new PIDPricing.DefaultSeller(initialPrice:100.0);
    new AgentData(["inflow","outflow"],
        (references)=>(s){references["inflow"].addLast(1);references["outflow"].addLast(0);});

    //todo finish this test
  });

  //todo test to make sure it doesn't break if I call update when agent data is empty

}
