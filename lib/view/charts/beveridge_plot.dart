/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.view;



/**
 * a way to plot price-quantity or whatever other 2d relationship over time,
 * possibly with other drawn curves to help figure stuff out.
 *
 * It updates by listening every day to
 */
@Component(
    selector: 'beveridgeplot',
    templateUrl: 'packages/lancaster/view/charts/plot.html',
    cssUrl: 'packages/lancaster/view/charts/plot.css')
class MarketBeveridge extends BeveridgePlot<MarketEvent>
{


  factory MarketBeveridge()
  {
    MarketBeveridge instance = new MarketBeveridge._internal();
    instance.repositoryGetter = (SimpleMarketPresentation p)=>p.curveRepository;
    return instance;
  }

  MarketBeveridge._internal():
  super(
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

