/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
import 'package:lancaster/view/lancaster_view_angularless.dart';
import 'package:lancaster/model/lancaster_model.dart';
import 'package:lancaster/presentation/lancaster_presentation.dart';
import 'dart:html' as HTML;
import 'package:stagexl/stagexl.dart';
import 'dart:async';

main()
{
  // BuildTestStage();

  StageXL.stageOptions.renderEngine = RenderEngine.Canvas2D;
  StageXL.stageOptions.stageScaleMode = StageScaleMode.SHOW_ALL;
  StageXL.stageOptions.stageAlign = StageAlign.NONE;
  StageXL.stageOptions.inputEventMode = InputEventMode.MouseAndTouch;
  StageXL.stageOptions.backgroundColor = 0xFFE0FFFF;


  //model
  Model model = new Model(1);
  GeographicalMarket market = new GeographicalMarket((x,y)
                                                     {
                                                       return CartesianDistance(x,y)/100;
                                                     });
  market.start(model.schedule,model);
  GeographicalMarketPresentation presentation = new GeographicalMarketPresentation(market,model,
                                                                                   new GeoBuyerFixedPriceGenerator());


  buildDefaultStage(presentation, HTML.querySelector('#stage'),800,600).then(
          (TraderStage stage)
      {

      //  market.start(model.schedule,model); //model reference not needed
        //create a bunch of traders
        for(int i=0; i<100; i++)
        {
          //each buyer buys 1 unit every day at the same price, if possible
          ZeroKnowledgeTrader buyer = new ZeroKnowledgeTrader(market, new FixedValue(i), new FixedValue(1),
                                                              new GeographicalBuyerTrading(new Location([model.random.nextInt(800),
                                                              model.random.nextInt(600)])),
                                                              new Inventory());
          buyer.dawnEvents.add(BurnInventories());
          buyer.start(model.schedule);
        }

        //initial price 100
        ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader.PIDBufferSellerFixedInflow(40.0,
                                                                                        market,initialPrice:100.0,
                                                                                        location: new Location([0,0]));
        seller.start(model.schedule);

        new Timer.periodic(new Duration(seconds:1),(Timer timer)
        {
          model.schedule.simulateDay();
        });

      }
          );




}