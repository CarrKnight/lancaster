/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
/**
 * the java inventory was a very elegant hashmap with variable good-types, differentiated goods and so on.
 * Until I want to do that here, this is probably the complete opposite. it's basically three numbers hidden behind few functions
 */
class Inventory implements HasInventory{


  double _money=0.0;

  double _gas =0.0;

  int _labor =0;


  earn(double amount){
    _money += amount;
  }

  spend(double amount){
    _money -= amount;
    assert(_money >=0);
  }

  receive(double amount){
    _gas+=amount;
  }

  remove(double amount){
    _gas-=amount;
    assert(_gas >=0);
  }

  hire(int people){
    _labor += people;
  }

  fire(int people){
    _labor -=people;
    assert(_labor >=0);

  }

  get gas => _gas;
  get labor => _labor;
  get money => _money;

}

abstract class HasInventory{

  earn(double amount);
  spend(double amount);

  receive(double amount);
  remove(double amount);

  hire(int people);
  fire(int people);

  get gas;
  get labor;
  get money;


}

