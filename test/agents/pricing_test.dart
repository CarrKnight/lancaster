/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

import 'package:mockito/mockito.dart';
import 'package:unittest/unittest.dart';
import 'package:lancaster/model/agents/pricing.dart';
import 'package:lancaster/model/tools/agent_data.dart';
import 'package:lancaster/model/engine/schedule.dart';



void main(){

  bufferTests();
  PIDFlows();


}


class MockAgentData extends Mock implements AgentData{}


void bufferTests(){
  //stocks up when it should
  test("correct flag setting", () {


    //should switch gracefully between flags
    //setup:
    var data = new MockAgentData();
    when(data.getLatestObservation(any)).thenReturn(0.0);
    double inventory = 0.0;
    Extractor inventoryExtractor = (data) => inventory;



    BufferInventoryPricing pricing = new BufferInventoryPricing(
            (data)=>0.0,inventoryExtractor,
            new PIDPricing.DefaultSeller(),optimalInventory:10.0,
            criticalInventory:5.0);


    expect(pricing.stockingUp,true);

    //if inventory is 0 it is still stocking up
    inventory = 0.0;
    pricing.updatePrice(data);
    expect(pricing.stockingUp,true);

    //if inventory is above critical but below optimal, it is still stocking up
    inventory = 6.0;
    pricing.updatePrice(data);
    expect(pricing.stockingUp,true);

    //if inventory is at least optimal, it stops stocking up
    inventory = 10.0;
    pricing.updatePrice(data);
    expect(pricing.stockingUp,false);

    //if it drops below optimal but above critical, it still doesn't stock up
    inventory = 6.0;
    pricing.updatePrice(data);
    expect(pricing.stockingUp,false);

    //if it drops below critical it starts stocking up again!
    inventory = 4.0;
    pricing.updatePrice(data);
    expect(pricing.stockingUp,true);


  });

  //when stocking up even if the outflow is less than inflow,
  // it still raises prices
  test("raise price to stock up", (){

    //setup:
    var data = new MockAgentData();
    when(data.getLatestObservation("inflow")).thenReturn(100.0);
    //the outflow is very low, but if we are stocking up it doesn't matter
    when(data.getLatestObservation("outflow")).thenReturn(1.0);
    when(data.getLatestObservation("inventory")).thenReturn(0.0);

    BufferInventoryPricing pricing = new BufferInventoryPricing.simpleSeller
      (
      optimalInventory: 1000.0, //pointless sets, just for verbosity sake
      criticalInventory: 500.0,
      initialPrice:10.0
      );
    //making sure the initial price is initialized correctly
    expect(pricing.price,10.0);


    pricing.updatePrice(data);
    expect(pricing.price>10.0,true); //price should have gone up even though
    // inflow>outflow!
  });


  //when not stocking up higher outflows than inflows means lower prices
  //when stocking up even if the outflow is a gazillion, it still raises prices
  test("lower price when not stocking up and it makes sense", (){

    //setup:
    var data = new MockAgentData();
    when(data.getLatestObservation("inflow")).thenReturn(100.0);
    //not selling enough, need to lower prices!
    when(data.getLatestObservation("outflow")).thenReturn(1.0);
    //enough inventory
    when(data.getLatestObservation("inventory")).thenReturn(50000.0);

    BufferInventoryPricing pricing = new BufferInventoryPricing.simpleSeller
    (
        optimalInventory: 1000.0, //pointless sets, just for verbosity sake
        criticalInventory: 500.0,
        initialPrice:10.0
    );
    //until you tell it to update it thinks it is stocking up
    expect(pricing.stockingUp,true);


    pricing.updatePrice(data);
    expect(pricing.stockingUp,false);
    //prices should have been lowered!
    expect(pricing.price<10.0,true);



  });
}

void PIDFlows() {
  test("stay still", () {


    //if I set the initial price to 100 and target always equal cv, the price should stay at 100
    PIDPricing pricing = new PIDPricing((data) => 1.0, (data) => 1.0, offset:100.0);
    expect(pricing.price, 100);
    for (int i = 0; i < 100; i++) {
      pricing.updatePrice(new AgentData(["a"], (references) => (s) {
      }));
      expect(pricing.price, 100);
    }

  });


  test("increase", () {


    //if I set the initial price to 100 and target>cv, the price should increase
    PIDPricing pricing = new PIDPricing((data) => 1.0, (data) => 0.0, offset:100.0);
    expect(pricing.price, 100);
    for (int i = 0; i < 100; i++) {
      pricing.updatePrice(new AgentData(["a"], (references) => (s) {
      }));
      expect(pricing.price > 100, true);
    }

  });

  test("decrease", () {


    //if I set the initial price to 100 and target<cv, the price should decrease
    PIDPricing pricing = new PIDPricing((data) => -10.0, (data) => 0.0, offset:100.0);
    expect(pricing.price, 100);
    for (int i = 0; i < 100; i++) {
      pricing.updatePrice(new AgentData(["a"], (references) => (s) {
      }));
      expect(pricing.price < 100 && pricing.price >= 0, true);
    }

  });

  test("default seller increase", () {

    //the seller: when inflow > outflow price should go down
    PIDPricing pricing = new PIDPricing.DefaultSeller(initialPrice:100.0);
    //default seller takes "inflow" and "outflow" columns
    var data = new AgentData(["inflow", "outflow"], (references) => (Schedule s) {
      references["inflow"].add(1.0);
      references["outflow"].add(0.0);
    });

    expect(pricing.price, 100);
    data.updateStep(new Schedule()); //"update" inflow = 1, outflow = 0 ====> price ↓

    pricing.updatePrice(data);
    expect(pricing.price < 100, true);

  });

  test("default seller decrease", () {

    //the seller:  when inflow < outflow price go up
    PIDPricing pricing = new PIDPricing.DefaultSeller(initialPrice:100.0);
    //default seller takes "inflow" and "outflow" columns
    var data = new AgentData(["inflow", "outflow"], (references) => (Schedule s) {
      references["inflow"].add(0.0);
      references["outflow"].add(1.0);
    });

    expect(pricing.price, 100);
    data.updateStep(new Schedule()); //"update" inflow = 0, outflow = 1 ====> price ↑

    pricing.updatePrice(data);
    expect(pricing.price > 100, true);

  });

  test("ignore NAs and lack of data", () {

    PIDPricing pricing = new PIDPricing.DefaultSeller(initialPrice:100.0);
    var data = new AgentData(["inflow", "outflow"], (references) => (Schedule s) {
      //puts garbage in
      references["inflow"].add(double.NAN);
      references["outflow"].add(1.0);
    });

    expect(pricing.price, 100);
    //if i have no data, it shouldn't break it just shouldn't update
    pricing.updatePrice(data);
    expect(pricing.price, 100);


    data.updateStep(new Schedule()); //data is NAN

    pricing.updatePrice(data); //should be ignored
    expect(pricing.price, 100);

  });
}

