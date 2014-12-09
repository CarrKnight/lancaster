/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.view;


/**
 * for now just a simple list of trades + ugly chart
 */
@Component(
    selector: 'beveridgeplot',
    templateUrl: 'packages/lancaster/view/charts/plot.html',
    cssUrl: 'packages/lancaster/view/charts/plot.css',
    publishAs: 'beveridge',
    useShadowDom: false
)
class BeveridgePlot implements ShadowRootAware{

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
  ObservableList<List<num>> observationRows = toObservable([[0,0.0,0.0]]);

  Element chartLocation;


  @NgOneWay('presentation')
  set presentation(SimpleMarketPresentation presentation)
  {
    _presentation = presentation;
    _buildChart();
    _listenToModel();
  }



  void _buildChart(){
    priceSeries = new ChartSeries("price", [1], new LineChartRenderer());
  //  var quantity = new ChartSeries("quantity", [0], new LineChartRenderer());
    data = new ChartData([new ChartColumnSpec(label:'Quantity',
    type:ChartColumnSpec.TYPE_NUMBER),
    new ChartColumnSpec(label:'Price',
    type:ChartColumnSpec.TYPE_NUMBER,
    formatter:(x)=>"$x\$"),
    new ChartColumnSpec(label:'Day',
    type:ChartColumnSpec.TYPE_NUMBER)],
    observationRows);


    config = new ChartConfig([priceSeries], [0]);
    chartLocation = querySelector('.price-chart');
    _drawChart();


  }




  void _listenToModel(){
    _presentation.marketStream.listen((event){
      double price1 = event.price;
      double quantity = event.quantity;
      if(!price1.isFinite)
        price1=0.0;
      if(!quantity.isFinite)
        quantity=0.0;
      print([event.day,  price1]);
      observationRows.add([quantity,  price1,event.day]);
      if(observationRows.length > 10)
        observationRows.removeAt(0);
      //redraws automatically
    });

  }




  /**
   * so actually this gets called even when there is no shadowroot; it's very
   * handy though because when this is called we know the html is ready to be
   * selected
   */
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


