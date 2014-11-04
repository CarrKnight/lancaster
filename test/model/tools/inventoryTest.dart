/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

import 'package:unittest/unittest.dart';
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
    OneGoodInventory tested = new InventoryCrossSection(totalInventory,"pippo");

    tested.receive(100.0);
    tested.earn(200.0);
    tested.spend(50.0);
    tested.remove(50.0);
    expect(totalInventory.hasHowMuch("pippo"),50.0);
    expect(totalInventory.hasHowMuch("money"),150.0);

    expect(tested.good,50.0);
    expect(tested.money,150.0);
    expect(tested.goodType,"pippo");
  });


}