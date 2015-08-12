part of lancaster.view2;
/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */



class LancasterDemoGUI
{


  GeographicalMarketPresentation _presentation;
  Model _model;


  LancasterDemoGUI(String rootSelector)
  {

    HTML.Element root = HTML.querySelector(rootSelector);
    //clear if you must
    while(root.hasChildNodes())
      root.firstChild.remove();

    //start up the model
    _model = new Model(new DateTime.now().millisecond);
    GeographicalMarket market = new GeographicalMarket((x,y)
                                                       {
                                                         return CartesianDistance(x,y)/100;
                                                       });

    //create control bar
    ModelPresentation base = new ModelPresentation(_model);
    HTML.DivElement controlBar = new HTML.DivElement();
    root.append(controlBar);
    ControlBar bar = new ControlBar(controlBar,
                                    base,"Experimental Geography",
                                        ()=>new LancasterDemoGUI(rootSelector),
                                    speed:60);

    //create the canvas
    market.start(_model.schedule,_model);
    _presentation = new GeographicalMarketPresentation(market,_model,
                                                       new GeoBuyerFixedPriceGenerator());
    _presentation.start(_model.schedule);
    HTML.DivElement parent = new HTML.DivElement();
    HTML.CanvasElement canvas = new HTML.CanvasElement();
    canvas.width = 800;
    canvas.height = 600;
    parent.append(canvas);
    root.append(parent);
    //now build the map!
    buildDefaultStage(_presentation,canvas,800,600).then((TraderStage stage) {

      //  market.start(model.schedule,model); //model reference not needed
      //create a bunch of traders
      for(int i=90; i<100; i++)
      {
        //each buyer buys 1 unit every day at the same price, if possible
        ZeroKnowledgeTrader buyer = new ZeroKnowledgeTrader(market, new FixedValue(i), new FixedValue(1),
                                                            new GeographicalBuyerTrading(new Location([_model.random.nextInt(800),
                                                            _model.random.nextInt(600)])),
                                                            new Inventory());
        buyer.dawnEvents.add(BurnInventories());
        buyer.start(_model.schedule);
      }

      //initial price 100
      ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader.PIDBufferSellerFixedInflow(5.0,
                                                                                      market,initialPrice:100.0,
                                                                                      location: new Location([0,0]));
      seller.start(_model.schedule);

      print("started EVERYTHING!");

    });



  }

}