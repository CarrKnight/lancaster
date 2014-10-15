/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */


import 'package:unittest/unittest.dart';
import 'package:lancaster/src/agents/pricing.dart';
import 'package:lancaster/src/tools/PIDController.dart';
import 'package:lancaster/src/tools/AgentData.dart';
import 'package:lancaster/src/engine/schedule.dart';


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

  test("default seller increase",(){

    //the seller: \ when inflow > outflow price go up
    PIDPricing pricing = new PIDPricing.DefaultSeller(initialPrice:100.0);
    //default seller takes "inflow" and "outflow" columns
    var data = new AgentData(["inflow","outflow"],
        (references)=>
            (Schedule s){
              references["inflow"].add(1);
              references["outflow"].add(0);});

    expect(pricing.price,100);
    data.updateStep(new Schedule()); //"update" inflow = 1, outflow = 0 ====> price ↑

    pricing.updatePrice(data);
    expect(pricing.price > 100, true);


    //todo finish this test
  });

  test("default seller decrease",(){

    //the seller:  when inflow < outflow price go down
    PIDPricing pricing = new PIDPricing.DefaultSeller(initialPrice:100.0);
    //default seller takes "inflow" and "outflow" columns
    var data = new AgentData(["inflow","outflow"],
        (references)=>
        (Schedule s){
      references["inflow"].add(0);
      references["outflow"].add(1);});

    expect(pricing.price,100);
    data.updateStep(new Schedule()); //"update" inflow = 0, outflow = 1 ====> price ↓

    pricing.updatePrice(data);
    expect(pricing.price < 100, true);

  });

  test("ignore NAs and lack of data",(){

    PIDPricing pricing = new PIDPricing.DefaultSeller(initialPrice:100.0);
    var data = new AgentData(["inflow","outflow"],
        (references)=>
        (Schedule s){
          //puts garbage in
      references["inflow"].add(double.NAN);
      references["outflow"].add(1);});

    expect(pricing.price,100);
    //if i have no data, it shouldn't break it just shouldn't update
    pricing.updatePrice(data);
    expect(pricing.price,100);


    data.updateStep(new Schedule()); //data is NAN

    pricing.updatePrice(data); //should be ignored
    expect(pricing.price,100);

  });
}
