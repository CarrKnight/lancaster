/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.view;

/**
 * for now just a simple list of trades + ugly chart
 */
@Component(
    selector: 'marketview',
    templateUrl: 'packages/lancaster/view/marketview/marketview.html',
    publishAs: 'market',
    useShadowDom: false
)
class MarketView implements ShadowRootAware{ //AttachAware

  /**
   * the presentation object which is our interface to the model itself
   */
  SimpleMarketPresentation _presentation;



  /**
   * in a perfect world this chart would be in the presentation folder. 
   * Unfortunately as soon as there is a dependency on html the tests don't run
   * so there is no benefit in putting this in the presentation layer
   */
  ChartSeries priceSeries;
  ChartData data;
  ChartConfig config;
  ChartArea area;
  ObservableList<List<num>> observationRows = toObservable([[0,0.0]]);

  Element chartLocation;
  
  
 
 


  void _buildChart(){
    priceSeries = new ChartSeries("price", [1], new LineChartRenderer());
    data = new ChartData([new ChartColumnSpec(label:'Day',
                                        type:ChartColumnSpec.TYPE_NUMBER),
                                        new ChartColumnSpec(label:'Price',
                                            type:ChartColumnSpec.TYPE_NUMBER,
                                            formatter:(x)=>"$x\$")], 
                                            observationRows);
    config = new ChartConfig([priceSeries], [0]);
    chartLocation = querySelector('.price-chart');
    _drawChart();

    
  }


  double price = double.NAN;

  double quantity = double.NAN;

  void _listenToModel(){
    _presentation.marketStream.listen((event){
      price = event.price;
      quantity = event.quantity;
      double price1 = event.price; 
      if(!price1.isFinite)
        price1=0.0;
      print([event.day,  price1]);
      observationRows.add([event.day,  price1]);
    });
  }

  @NgOneWay('presentation')
  set presentation(SimpleMarketPresentation presentation)
  {
    _presentation = presentation;
    _buildChart();
    _listenToModel();
  }

  void onShadowRoot(ShadowRoot shadowRoot){
    chartLocation=querySelector('.price-chart');
    _drawChart();
  }
  
  void _drawChart(){
    //draw it only once
    if(area != null || chartLocation == null || priceSeries == null)
      return;
    area = new ChartArea(chartLocation,
                 data, config, autoUpdate:true, dimensionAxesCount:1);
         area.draw();
  }



}
