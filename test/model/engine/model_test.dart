/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
import 'package:unittest/unittest.dart';
import 'package:lancaster/model/lancaster_model.dart';


main(){

  test("simple seller scenario",(){

    Model model = new Model(0,new Scenario.simpleSeller());
    model.start();


    Trader seller = model.agents.first as Trader;

    for(int i=0; i<200; i++)
    {
      model.schedule.simulateDay();

    }
    print(
        "price ${seller.lastOfferedPrice} and quantity ${seller.currentOutflow}"
    );
    //should be correct by now
    expect(40,seller.currentOutflow);
    expect(60,seller.lastOfferedPrice);
    expect(model.gasMarket.quantityTraded,40);
    expect(model.gasMarket.averageClosingPrice,60);
  });



  test("simple buyer scenario",(){

    Model model = new Model(0,new Scenario.simpleBuyer());
    model.start();


    Trader buyer = model.agents.first as Trader;

    for(int i=0; i<200; i++)
    {
      model.schedule.simulateDay();

    }
    print(
        "price ${buyer.lastOfferedPrice} and quantity ${buyer.currentOutflow}"
    );
    //should be correct by now
    expect(40,buyer.currentInflow);
    expect(40,buyer.lastOfferedPrice);
    expect(model.gasMarket.quantityTraded,40);
    expect(model.gasMarket.averageClosingPrice,40);
  });


}