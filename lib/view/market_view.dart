/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.view;

//todo make into component
class MarketView
{

  /**
   *
   */
  SimpleMarketPresentation _presentation;


  /**
   * to be displayed by the highchart in the html
   */
  HighChart priceChart;


  /**
   * updated by listening to the presentation
   */
  Series priceSeries;


  void _buildChart(){

    priceSeries = new Series()
                  ..numData =[]
                  ..name = "Prices"
                  ..type = "line";

    priceChart = new HighChart ()
      ..title = (new Title ()
      ..text = 'Gas Market')
      ..chart = (new Chart ()
      ..type = 'line'
      ..animation = true
      ..borderColor = '#CCC'
      ..borderWidth = 1
      ..borderRadius = 8
      ..backgroundColor = 'rgba(0,0,0,0)'
    )
      ..subtitle = (new Subtitle()
      ..text = 'Average Price'
      ..x = -20)
      ..xAxis = (new XAxis())
      ..yAxis = (new YAxis ()
      ..title = (new AxisTitle()
      ..text = 'Price \$'))
      ..tooltip = (new Tooltip()
      ..valueSuffix = '\$')
      ..legend = (new Legend ()
      ..layout = 'vertical'
      ..align = 'right'
      ..verticalAlign = 'middle'
      ..borderWidth = 0)
      ..series = [priceSeries];

  }


  void _listenToModel(){
      _presentation.marketStream.listen((event)=>
          priceSeries.numData.add(event.price));
  }

  @NgOneWay('market')
  set presentation(SimpleMarketPresentation presentation)
  {
    _presentation = presentation;
    _buildChart();
    _listenToModel();
  }

}
