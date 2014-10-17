library markets;

import 'package:lancaster/src/tools/inventory.dart';
import 'package:lancaster/src/engine/schedule.dart';
import 'package:lancaster/src/agents/seller.dart';
import 'dart:math';

/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

/*

Unlike the good old generic java model where this come from, here I am mostly going to deal with one kind of market:
set quotes at the beginning of the day, clear them by mid-day and forget them all.
As such all the infrastructure to update/delete quotes is useless.
I am also going to change how some customers work. For fixed demand I used to have to instantiate many "customer agents" who always
 asked the same price every day. Here I am probably just going to have a curve that does that.
 */

/**
 * interface for markets that allow sales quotes
 */
abstract class MarketForSellers{

  placeSaleQuote(Seller seller,double amount,double unitPrice);

}

abstract class MarketForBuyers{

  placeBuyerQuote(HasInventory buyer,double amount,double unitPrice);

}


/**
 * a market where the buying is "done" by a fixed linear demand while the sellers are normal agents
 */
class LinearDemandMarket implements MarketForSellers{


  final List<_SaleQuote> _quotes = new List();



  double _intercept;

  double _slope;

  double _soldToday = 0.0;

  /**
   * reset market means clearing up the quote and reset the already sold counter
   */
  Step _resetMarketStep;

  /**
   * trade--> market clears
   */
  Step _marketClearStep;



  LinearDemandMarket({num intercept : 100.0, num slope:-1.0}) {
    assert(slope <=0);
    this._intercept = intercept.toDouble();
    this._slope = slope.toDouble();


    _resetMarketStep= (schedule){
      _resetMarket(schedule);
    };

    _marketClearStep = (schedule){
      _clearMarket(schedule);
    };


  }

  void start(Schedule s){
    s.scheduleRepeating(Phase.DAWN,_resetMarket);

    s.scheduleRepeating(Phase.CLEAR_MARKETS,_clearMarket);
  }

  void _resetMarket(Schedule s){
    _quotes.clear();
    _soldToday = 0.0;

  }

  void _clearMarket(Schedule s){
    //sort quotes (last will be the best since last is faster to remove, I think)
    _quotes.shuffle(); //shuffle it to avoid first agent to always go first/last
    _quotes.sort((q1,q2)=>(-q1.pricePerunit.compareTo(q2.pricePerunit)));

    //as long as there are quotes
    while(_quotes.isNotEmpty){

      var best = _quotes.last;
      var price = best._pricePerUnit;
      var maxDemandForThisPrice = (intercept + slope * price)-_soldToday; //demand minus what has been already sold today!

      if(maxDemandForThisPrice <= 0) //if the best price gets no sales, we are done
        break;

      var amountTraded = min(maxDemandForThisPrice,best.amount);
      //trade!
      sold(best.owner,amountTraded,best.pricePerunit);
      _soldToday +=amountTraded;

      //if we filled the quote
      if(amountTraded == best.amount) {
        var removed = _quotes.removeLast();
        assert(removed == best);
      }
      else{
        assert(amountTraded < best.amount); //you must have traded less than the quote, it can never be more!
        best.amount -= amountTraded; //change the quote, even though it's pointless
        break; //bye bye
      }
    }
  }

  double get slope => _slope;

  set slope(double value){
    _slope = value;
    assert(_slope <=0);
  }

  double get intercept => _intercept;

  set intercept(double value){
    _intercept = value;
    assert(intercept>=0);

  }

  placeSaleQuote(Seller seller, double amount, double unitPrice) {
    _quotes.add(new _SaleQuote(seller,amount,unitPrice));
  }


}

class _SaleQuote
{

  double _amount;

  final double _pricePerUnit;

  final Seller _owner;

  _SaleQuote(this._owner, this._amount,this._pricePerUnit);


  Seller get owner => _owner;
  get pricePerunit=> _pricePerUnit;
  get amount=> _amount;

  set amount(double newAmount){
    _amount = newAmount;
    if(this.amount < 0)
      throw "A quote has negative amount!";
  }

}


//easy functions for trading

void sold(HasInventory seller, double amount, double price){

  seller.earn(price*amount);
  seller.remove(amount);

}

void bought(HasInventory buyer, double amount, double price){

  buyer.spend(price*amount);
  buyer.receive(amount);


}

void tradeBetweenTwoAgents(HasInventory buyer, HasInventory seller, double amount, double price ){
  sold(seller,amount,price);
  bought(buyer,amount,price);
}
