/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

library production.test;

import 'package:unittest/unittest.dart';
import 'package:lancaster/model/lancaster_model.dart';

main(){
  test("production function works",(){
    SISOProductionFunction function = new SISOProductionFunction
    (multiplier:2.0,consumeInput:true);

    expect(function.production(100.0),200);
    expect(function.consumption(100.0),100);

    function.consumeInput=false;

    expect(function.production(100.0),200);
    expect(function.consumption(100.0),0);

    function.multiplier = 0.5;
    expect(function.production(100.0),50);
    expect(function.consumption(100.0),0);

  });


  test("plant produces correctly",(){
    SISOProductionFunction function = new SISOProductionFunction(multiplier:2.0,
    consumeInput:true);
    Inventory totalInventory = new Inventory();


    SISOPlant plant = new SISOPlant.defaultSISO(totalInventory);
    totalInventory.receive("labor",100.0);
    plant.function.multiplier=2.0;

    expect(totalInventory.hasHowMuch("gas"),0);
    expect(totalInventory.hasHowMuch("labor"),100);

    plant.produce();

    expect(totalInventory.hasHowMuch("gas"),200);
    expect(totalInventory.hasHowMuch("labor"),0);



  });


  test("multiple productions",(){
    SISOProductionFunction function = new SISOProductionFunction(multiplier:2.0,
    consumeInput:true);
    Inventory totalInventory = new Inventory();
    Schedule s = new Schedule();


    SISOPlant plant = new SISOPlant.defaultSISO(totalInventory);
    totalInventory.receive("labor",100.0);
    plant.start(s);
    plant.function.multiplier=2.0;
    expect(totalInventory.hasHowMuch("gas"),0);
    expect(totalInventory.hasHowMuch("labor"),100);

    s.simulateDay();
    expect(totalInventory.hasHowMuch("gas"),200);
    expect(totalInventory.hasHowMuch("labor"),0);
    totalInventory.receive("labor",100.0);
    s.simulateDay();
    expect(totalInventory.hasHowMuch("gas"),400);
    expect(totalInventory.hasHowMuch("labor"),0);




  });
}

