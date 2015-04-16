/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.view2;


class MarketBeveridge extends BeveridgePlot<MarketEvent>
{


  factory MarketBeveridge(HTML.DivElement container,
                          Presentation<MarketEvent> presentation)
  {
    MarketBeveridge instance = new MarketBeveridge._internal(container,
                                                             presentation);
    instance.repositoryGetter = (SimpleMarketPresentation p)=>p.curveRepository;
    return instance;
  }

  MarketBeveridge._internal(HTML.DivElement container,
                            Presentation<MarketEvent> presentation):
  super(container,presentation,
          (MarketEvent e)
      {
        if(!e.quantity.isFinite || !e.price.isFinite)
          return null;
        else

          return new BeveridgeDatum(e.quantity, e.price, 8,
                                    "price: ${e.price.toStringAsFixed(
                                        2)}, day: ${e.day.toInt()}");
      }


      ,

          (SimpleMarketPresentation p)
      {
        List<BeveridgeDatum> data = [];
        p.marketEvents.forEach((e)=>data.add(
            new BeveridgeDatum(e.quantity,e.price,8,"price: ${e.price.
            toStringAsFixed(2)}, day: ${e.day.toInt()}")));
        return data;
      }
          );

}


/**
 * beveridge plot for a buying zero-knowledge agent (focuses on inflow)
 */

class BuyerBeveridge extends BeveridgePlot<ZKEvent>
{


  factory BuyerBeveridge(HTML.DivElement container,
                         Presentation<ZKEvent> presentation)
  {
    BuyerBeveridge toReturn = new   BuyerBeveridge._internal(
    container,presentation
    );
    toReturn.repositoryGetter = (ZKPresentation p)=>p.repository;
    return toReturn;
  }

//this.dailyDataExtractor, this.dataInitializer
  BuyerBeveridge._internal(HTML.DivElement container,
                           Presentation<ZKEvent> presentation)
  :
  super(container,presentation,
        _extractor,_initializer);





  static BeveridgeDatum _adapter(num inflow, num price, int day)
  {

    return new BeveridgeDatum(inflow,price,8,
                              "price: ${price.toStringAsFixed(2)}, day:${day}");



  }


  static BeveridgeDatum _extractor(ZKEvent e)
  {

    num inflow = e.trader.currentInflow;
    num price = e.trader.lastOfferedPrice;
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


/**
 * one day this might be the catch all, for now very very corner case only
 */
class SupplyAndDemandPlot extends BeveridgePlot<ZKEvent>
{

  factory SupplyAndDemandPlot.PresentationCase(HTML.DivElement container,
                                               Presentation<ZKEvent> presentation,
                                               ExponentialProductionFunction production,
                                               ExogenousCurve demand,
                                               {double resizeScale : 1.0})
  {

    //add the two curves to the repository
    CurveRepository demandAndSupply = new CurveRepository();
    demandAndSupply.addCurve(demand,"Demand");
    demandAndSupply.addCurvePath(new ExponentialMarginalCostPath(()=>1.0,production), "Supply");
    SupplyAndDemandPlot plot = new SupplyAndDemandPlot._internal(container,presentation,resizeScale:resizeScale);
    //todo you only need one of these two, figure out which!
  //  plot.curveRepository = demandAndSupply;
    print("curves ${demandAndSupply.curves}");
    plot.repositoryGetter = (presentation)=>demandAndSupply;
    assert(plot.curveRepository == demandAndSupply);

    return plot;
    

  }


  SupplyAndDemandPlot._internal(HTML.DivElement container,
                                Presentation<ZKEvent> presentation,
                                {double resizeScale : 1.0})
  :
  super(container,presentation,SellerBeveridge._extractor,SellerBeveridge._initializer,resizeScale:resizeScale);





}


/**
 * beveridge plot for a buying zero-knowledge agent (focuses on inflow)
 */
class SellerBeveridge extends BeveridgePlot<ZKEvent>
{


  factory SellerBeveridge(HTML.DivElement container,
                          Presentation<ZKEvent> presentation,{double resizeScale : 1.0})
  {
    SellerBeveridge toReturn = new   SellerBeveridge._internal(container,
    presentation,resizeScale : resizeScale);
    toReturn.repositoryGetter = (ZKPresentation p)=>p.repository;
    return toReturn;
  }

//this.dailyDataExtractor, this.dataInitializer
  SellerBeveridge._internal(HTML.DivElement container,
                            Presentation<ZKEvent> presentation,
                            {double resizeScale : 1.0})
  :
  super(container,presentation,_extractor,_initializer,resizeScale:resizeScale);





  static BeveridgeDatum _adapter(num  outflow, num price, int day)
  {

    return new BeveridgeDatum(outflow,price,8,
                              "price: ${price.toStringAsFixed(2)}, day:${day}");



  }


  static BeveridgeDatum _extractor(ZKEvent e)
  {

    num outflow = e.trader.currentOutflow;
    num price = e.trader.lastOfferedPrice;
    int day = e.day;

    return _adapter(outflow,price,day);



  }
  static  List<BeveridgeDatum> _initializer(ZKPresentation presentation)
  {
    //this happens only once!
    List<double> inflowObs = presentation.trader.data.getObservations("outflow");

    List<double> priceObs = presentation.trader.data.getObservations("offeredPrice");


    List<BeveridgeDatum> data = [];

    for(int i=0; i<inflowObs.length; i++)
    {
      data.add(_adapter(inflowObs[i],priceObs[i],i));

    }


    return data;

  }




}
