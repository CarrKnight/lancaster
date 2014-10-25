/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

import 'package:unittest/unittest.dart';
import 'package:lancaster/model/lancaster_model.dart';

main(){

  test("Simple receive",(){

    HasInventory tested = new Inventory();

    tested.receive(100.0);
    tested.hire(4);
    tested.earn(200.0);
    tested.fire(1);
    tested.spend(50.0);
    tested.remove(50.0);
    expect(tested.gas,50.0);
    expect(tested.money,150.0);
    expect(tested.labor,3);

  });


}