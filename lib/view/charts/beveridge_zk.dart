/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.view;

/**
 * beveridge plot for a buying zero-knowledge agent (focuses on inflow)
 */
@Component(
    selector: 'buyerbeveridge',
    templateUrl: 'packages/lancaster/view/charts/plot.html',
    cssUrl: 'packages/lancaster/view/charts/plot.css')
class BuyerBeveridge extends BeveridgePlot<ZKEvent>
{


  factory BuyerBeveridge()
  {
    BuyerBeveridge toReturn = new   BuyerBeveridge._internal();
    toReturn.repositoryGetter = (ZKPresentation p)=>p.repository;
    return toReturn;
  }

//this.dailyDataExtractor, this.dataInitializer
  BuyerBeveridge._internal()
  :
  super(_extractor,_initializer);





  static BeveridgeDatum _adapter(double inflow, double price, int day)
  {

    return new BeveridgeDatum(inflow,price,8,
                              "price: ${price.toStringAsFixed(2)}, day:${day}");



  }


  static BeveridgeDatum _extractor(ZKEvent e)
  {

    double inflow = e.trader.currentInflow;
    double price = e.trader.lastOfferedPrice;
    int day = e.day;

    return _adapter(inflow,price,day);



  }
  static  List<BeveridgeDatum> _initializer(ZKPresentation presentation)
  {
    //this happens only once!
    List<double> inflowObs = presentation.trader.data.getObservations("inflow");

    List<double> priceObs = presentation.trader.data.getObservations("offeredPrice");


    List<BeveridgeDatum> data = [];

    for(int i=0; i<inflowObs.length; i++)
    {
      data.add(_adapter(inflowObs[i],priceObs[i],i));

    }


    return data;

  }

}