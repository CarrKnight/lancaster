/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
library inventory.test;
import 'package:test/test.dart';
import 'package:lancaster/model/lancaster_model.dart';

main(){

  test("Simple receive",(){

    HasInventory tested = new Inventory();

    tested.receive("gas",100.0);
    tested.receive("workers",4.0);
    tested.receive("money",200.0);
    tested.remove("workers",1.0);
    tested.remove("money",50.0);
    tested.remove("gas",50.0);
    expect(tested.hasHowMuch("gas"),50.0);
    expect(tested.hasHowMuch("money"),150.0);
    expect(tested.hasHowMuch("workers"),3);

  });

  test("Simple receive on crossSection",(){

    var totalInventory = new Inventory();
    InventoryCrossSection tested =totalInventory.getSection("pippo");

    tested.receive(100.0);
    tested.remove(50.0);
    expect(totalInventory.hasHowMuch("pippo"),50.0);

    expect(tested.amount,50.0);
    expect(tested.goodType,"pippo");
  });


  test("flows counted correctly (inside a zk trader)",(){

    var totalInventory = new Inventory();
    InventoryCrossSection tested =totalInventory.getSection("pippo");

    tested.receive(100.0);
    tested.remove(50.0);
    expect(tested.outflow,50.0);
    expect(tested.inflow,100.0);

    expect(tested.amount,50.0);
    expect(tested.goodType,"pippo");

    totalInventory.resetCounters();
    expect(tested.outflow,0.0);
    expect(tested.inflow,0.0);
    tested.receive(100.0);
    expect(tested.outflow,0.0);
    expect(tested.inflow,100.0);

  });


}