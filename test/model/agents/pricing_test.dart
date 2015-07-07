/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

library pricingtest;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:lancaster/model/lancaster_model.dart';



void main(){

  bufferTests();
  PIDFlows();
  buyerPIDFlows();
  extractorTests();

}


class MockAgentData extends Mock implements Data{}


void bufferTests(){
  //stocks up when it should
  test("correct flag setting", () {


    //should switch gracefully between flags
    //setup:
    var data = new MockAgentData();
    when(data.getLatestObservation(any)).thenReturn(0.0);
    when(data.getObservations(any)).thenReturn([0.0]);
    double inventory = 0.0;
    Extractor inventoryExtractor = new FunctionalExtractor((data) => inventory);



    BufferInventoryAdaptive pricing = new BufferInventoryAdaptive(
            new FixedExtractor(0.0),inventoryExtractor,
            new PIDAdaptive.DefaultSeller(),10.0,
            5.0);


    expect(pricing.stockingUp,true);

    //if inventory is 0 it is still stocking up
    inventory = 0.0;
    pricing.adapt(null,data);
    expect(pricing.stockingUp,true);

    //if inventory is above critical but below optimal, it is still stocking up
    inventory = 6.0;
    pricing.adapt(null,data);
    expect(pricing.stockingUp,true);

    //if inventory is at least optimal, it stops stocking up
    inventory = 10.0;
    pricing.adapt(null,data);
    expect(pricing.stockingUp,false);

    //if it drops below optimal but above critical, it still doesn't stock up
    inventory = 6.0;
    pricing.adapt(null,data);
    expect(pricing.stockingUp,false);

    //if it drops below critical it starts stocking up again!
    inventory = 4.0;
    pricing.adapt(null,data);
    expect(pricing.stockingUp,true);


  });

  //when stocking up even if the outflow is less than inflow,
  // it still raises prices
  test("raise price to stock up", (){

    //setup:
    var data = new MockAgentData();
    when(data.getObservations("inflow")).thenReturn([100.0]);

    //the outflow is very low, but if we are stocking up it doesn't matter
    when(data.getObservations("outflow")).thenReturn([1.0]);
    when(data.getObservations("inventory")).thenReturn([0.0]);

    BufferInventoryAdaptive pricing = new BufferInventoryAdaptive.simpleSeller
      (
      optimalInventory: 1000.0, //pointless sets, just for verbosity sake
      criticalInventory: 500.0,
      offset:10.0
      );
    //making sure the initial price is initialized correctly
    expect(pricing.value,10.0);


    pricing.adapt(null,data);
    expect(pricing.value>10.0,true); //price should have gone up even though
    // inflow>outflow!
  });


  //when not stocking up higher outflows than inflows means lower prices
  //when stocking up even if the outflow is a gazillion, it still raises prices
  test("lower price when not stocking up and it makes sense", (){

    //setup:
    var data = new MockAgentData();
    when(data.getObservations("inflow")).thenReturn([100.0]);
    //not selling enough, need to lower prices!
    when(data.getObservations("outflow")).thenReturn([1.0]);
    //enough inventory
    when(data.getObservations("inventory")).thenReturn([50000.0]);

    BufferInventoryAdaptive pricing = new BufferInventoryAdaptive.simpleSeller
    (
        optimalInventory: 1000.0, //pointless sets, just for verbosity sake
        criticalInventory: 500.0,
        offset:10.0
    );
    //until you tell it to update it thinks it is stocking up
    expect(pricing.stockingUp,true);


    pricing.adapt(null,data);
    expect(pricing.stockingUp,false);
    //prices should have been lowered!
    expect(pricing.value<10.0,true);



  });
}

void PIDFlows() {
  test("stay still", () {


    //if I set the initial price to 100 and target always equal cv, the price should stay at 100
    PIDAdaptive pricing = new PIDAdaptive(new FixedExtractor(1.0),
    new FixedExtractor(1.0),
    offset:100.0);
    expect(pricing.value, 100);
    for (int i = 0; i < 100; i++) {
      pricing.adapt(null,new Data(["a"], (references) => (s) {
      }));
      expect(pricing.value, 100);
    }

  });


  test("increase", () {


    //if I set the initial price to 100 and target>cv, the price should increase
    PIDAdaptive pricing = new PIDAdaptive(new FixedExtractor(1.0),
    new FixedExtractor(0.0), offset:100.0);
    expect(pricing.value, 100);
    for (int i = 0; i < 100; i++) {
      pricing.adapt(null,new Data(["a"], (references) => (s) {
      }));
      expect(pricing.value > 100, true);
    }

  });

  test("decrease", () {


    //if I set the initial price to 100 and target<cv, the price should decrease
    PIDAdaptive pricing = new PIDAdaptive(new FixedExtractor(-10.0),
    new FixedExtractor(0.0), offset:100.0);
    expect(pricing.value, 100);
    for (int i = 0; i < 100; i++) {
      pricing.adapt(null,new Data(["a"], (references) => (s) {
      }));
      expect(pricing.value < 100 && pricing.value >= 0, true);
    }

  });

  test("default seller increase", () {

    //the seller: when inflow > outflow price should go down
    PIDAdaptive pricing = new PIDAdaptive.DefaultSeller(offset:100.0);
    //default seller takes "inflow" and "outflow" columns
    var data = new Data(["inflow", "outflow"], (references) => (Schedule s) {
      references["inflow"].add(1.0);
      references["outflow"].add(0.0);
    });

    expect(pricing.value, 100);
    data.updateStep(new Schedule()); //"update" inflow = 1, outflow = 0 ====> price ↓

    pricing.adapt(null,data);
    expect(pricing.value < 100, true);

  });

  test("default seller decrease", () {

    //the seller:  when inflow < outflow price go up
    PIDAdaptive pricing = new PIDAdaptive.DefaultSeller(offset:100.0);
    //default seller takes "inflow" and "outflow" columns
    var data = new Data(["inflow", "outflow"], (references) => (Schedule s) {
      references["inflow"].add(0.0);
      references["outflow"].add(1.0);
    });

    expect(pricing.value, 100);
    data.updateStep(new Schedule()); //"update" inflow = 0, outflow = 1 ====> price ↑

    pricing.adapt(null,data);
    expect(pricing.value > 100, true);

  });

  test("ignore NAs and lack of data", () {

    PIDAdaptive pricing = new PIDAdaptive.DefaultSeller(offset:100.0);
    var data = new Data(["inflow", "outflow"], (references) => (Schedule s) {
      //puts garbage in
      references["inflow"].add(double.NAN);
      references["outflow"].add(1.0);
    });

    expect(pricing.value, 100);
    //if i have no data, it shouldn't break it just shouldn't update
    pricing.adapt(null,data);
    expect(pricing.value, 100);


    data.updateStep(new Schedule()); //data is NAN

    pricing.adapt(null,data); //should be ignored
    expect(pricing.value, 100);

  });
}


void buyerPIDFlows(){
  test("buyer flows stay still", () {


    //if I set the initial price to 100 and target always equal cv, the price should stay at 100
    PIDAdaptive pricing = new PIDAdaptive.FixedInflowBuyer(
        flowTarget:20.0, initialPrice:100.0);
    expect(pricing.value, 100);
    for (int i = 0; i < 100; i++) {
      var data = new Data(["inflow"], (references) => (Schedule s) {
        references["inflow"].add(20.0);
      });
      data.updateStep(new Schedule()); //"update" data
      pricing.adapt(null,data);
      expect(pricing.value, 100);
    }

  });


  test("buyer increase prices when flow too low", () {


    //if I set the initial price to 100 and target>cv, the price should increase
    PIDAdaptive pricing = new PIDAdaptive.FixedInflowBuyer(
        flowTarget:20.0, initialPrice:100.0);
    expect(pricing.value, 100);
    for (int i = 0; i < 100; i++) {
      var data = new Data(["inflow"], (references) => (Schedule s) {
        references["inflow"].add(10.0); //wants 20, only get 10, raise price
      });
      data.updateStep(new Schedule()); //"update" data
      pricing.adapt(null,data);
      expect(pricing.value > 100, true);
    }

  });

  test("buyer lowers price when buying too much", () {


    //if I set the initial price to 100 and target<cv, the price should decrease
    PIDAdaptive pricing = new PIDAdaptive.FixedInflowBuyer(
        flowTarget:20.0, initialPrice:100.0);
    expect(pricing.value, 100);
    for (int i = 0; i < 100; i++) {
      var data = new Data(["inflow"], (references) => (Schedule s) {
        references["inflow"].add(30.0); //buying too much
      });
      data.updateStep(new Schedule()); //"update" data
      pricing.adapt(null,data);
      expect(pricing.value < 100 && pricing.value >= 0, true);
    }

  });


  test("buyer inventory stay still", () {


    //if I set the initial price to 100 and target always equal cv, the price should stay at 100
    PIDAdaptive pricing = new PIDAdaptive.FixedInventoryBuyer(
        inventoryTarget:20.0, initialPrice:100.0);
    expect(pricing.value, 100);
    for (int i = 0; i < 100; i++) {
      var data = new Data(["inventory"], (references) => (Schedule s) {
        references["inventory"].add(20.0);
      });
      data.updateStep(new Schedule()); //"update" data
      pricing.adapt(null,data);
      expect(pricing.value, 100);
    }

  });


  test("buyer increase prices when flow too low", () {


    //if I set the initial price to 100 and target>cv, the price should increase
    PIDAdaptive pricing = new PIDAdaptive.FixedInventoryBuyer(
        inventoryTarget:20.0, initialPrice:100.0);
    expect(pricing.value, 100);
    for (int i = 0; i < 100; i++) {
      var data = new Data(["inventory"], (references) => (Schedule s) {
        references["inventory"].add(10.0); //wants 20, only get 10, raise price
      });
      data.updateStep(new Schedule()); //"update" data
      pricing.adapt(null,data);
      expect(pricing.value > 100, true);
    }

  });

  test("buyer lowers price when buying too much", () {


    //if I set the initial price to 100 and target<cv, the price should decrease
    PIDAdaptive pricing = new PIDAdaptive.FixedInventoryBuyer(
        inventoryTarget:20.0, initialPrice:100.0);
    expect(pricing.value, 100);
    for (int i = 0; i < 100; i++) {
      var data = new Data(["inventory"], (references) => (Schedule s) {
        references["inventory"].add(30.0); //buying too much
      });
      data.updateStep(new Schedule()); //"update" data
      pricing.adapt(null,data);
      expect(pricing.value < 100 && pricing.value >= 0, true);
    }

  });

}


void extractorTests(){

   test("Fixed Extractor is not variable",(){
     double target = 100.0;
     Extractor fix = new FixedExtractor(target);
     expect(100.0,fix.extract(null));
     target = 1.0;
     expect(100.0,fix.extract(null)); //not 1!


   });


}
