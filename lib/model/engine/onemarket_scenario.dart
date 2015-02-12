/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.model;





typedef AdaptiveStrategy  HrStrategyInitialization(SISOPlant plant, Firm firm,
                                                   Random r, ZeroKnowledgeTrader seller, OneMarketCompetition scenario);

typedef AdaptiveStrategy SalesStrategyInitialization(SISOPlant plant, Firm firm,
                                                     Random r,
                                                     OneMarketCompetition
                                                     scenario);

typedef void TraderConsumer(ZeroKnowledgeTrader trader);



class OneMarketCompetition extends Scenario
{


  double minInitialPriceBuying = 0.0;
  double maxInitialPriceBuying = 100.0;
  double minInitialPriceSelling = 0.0;
  double maxInitialPriceSelling = 100.0;
  double demandIntercept=100.0; double demandSlope=-1.0;
  //sales pid
  double salesMinP=0.05; double salesMaxP=.5;
  double salesMinI=0.05; double salesMaxI=.5;
  //purchases pid
  double purchaseMinP=0.05; double purchaseMaxP=.5;
  double purchaseMinI=0.05; double purchaseMaxI=.5;
  //plant
  double productionMultiplier = 1.0;
  int competitors = 1;
  List<Firm> firms = new List();

  /**
   * called to build the pricer of hr. By default it creates a marginal
   * maximizer
   */
  HrStrategyInitialization hrPricingInitialization = PID_MAXIMIZER_HR;


  //build labor market
  ExogenousBuyerMarket laborMarket = new ExogenousBuyerMarket.linear
  (intercept:0.0, slope:1.0, goodType : "labor");

  ExogenousSellerMarket goodMarket = new ExogenousSellerMarket.linear
  (intercept:100.0, slope:-1.0);

  /**
   * function that returns an hr initialization function, in this case one
   * that has a fixed target, useful for testing mostly
   */
  static HrStrategyInitialization FIXED_TARGET_HR(double target) =>
      (SISOPlant plant,
       Firm firm, Random r, ZeroKnowledgeTrader seller, OneMarketCompetition scenario
       ){
    double p = r.nextDouble() * (scenario.purchaseMaxP - scenario.purchaseMinP) +
               scenario.purchaseMinP;
    double i = r.nextDouble() * (scenario.purchaseMaxI - scenario
    .purchaseMinI)  + scenario.purchaseMinI;
    double initialPrice = r.nextDouble() *
                          (scenario.maxInitialPriceBuying - scenario.minInitialPriceBuying) +
                          scenario.minInitialPriceBuying;
    return new PIDAdaptive.FixedInflowBuyer(flowTarget:target,
                                            initialPrice:initialPrice,p:p,
                                            i:i,d:0.0);
  };

  static final HrStrategyInitialization MARGINAL_MAXIMIZER_HR = (SISOPlant plant,
                                                                 Firm firm,
                                                                 Random r,
                                                                 ZeroKnowledgeTrader seller,
                                                                 OneMarketCompetition scenario)
  {
    double p = r.nextDouble() * (scenario.purchaseMaxP - scenario.purchaseMinP) +
               scenario.purchaseMinP;
    double i = r.nextDouble() * (scenario.purchaseMaxI - scenario
    .purchaseMinI)  + scenario.purchaseMinI;
    double initialPrice = r.nextDouble() *
                          (scenario.maxInitialPriceBuying - scenario.minInitialPriceBuying) +
                          scenario.minInitialPriceBuying;
    AdaptiveStrategy s = new PIDAdaptive.MaximizerBuyer(plant,firm,r,
                                                        initialPrice:initialPrice,p:p,i:i,d:0.0);
    return s;
  };

  static final HrStrategyInitialization PID_MAXIMIZER_HR = (SISOPlant plant,
                                                            Firm firm,
                                                            Random r,
                                                            ZeroKnowledgeTrader seller,
                                                            OneMarketCompetition scenario)
  {
    double p = r.nextDouble() * (scenario.purchaseMaxP - scenario.purchaseMinP) +
               scenario.purchaseMinP;
    double i = r.nextDouble() * (scenario.purchaseMaxI - scenario
    .purchaseMinI)  + scenario.purchaseMinI;
    double initialPrice = r.nextDouble() *
                          (scenario.maxInitialPriceBuying - scenario.minInitialPriceBuying) +
                          scenario.minInitialPriceBuying;
    AdaptiveStrategy s = new PIDAdaptive.PIDMaximizerBuyer(plant,firm,r,
                                                           initialPrice:initialPrice,p:p,i:i,d:0.0,averagePIDPeriod:20);
    return s;
  };


  HrStrategyInitialization hrQuotaInitializer = BUY_ALL;



  static final HrStrategyInitialization BUY_ALL = (SISOPlant plant, Firm firm,
                                                   Random r, ZeroKnowledgeTrader seller,
                                                   OneMarketCompetition scenario) => new FixedValue();

  /**
   * Useful when Marhsall meets infinitely elastic supply
   */
  static final HrStrategyInitialization MARSHALLIAN_QUOTA =
  MARSHALLIAN_QUOTAS(1.0);
  /**
   * confusing? function that returns the function that creates the hr
   * strategy. Useful, even though not intuitive
   */
  static HrStrategyInitialization MARSHALLIAN_QUOTAS(double initialTarget)
  =>(SISOPlant plant,
     Firm firm,
     Random r, ZeroKnowledgeTrader seller,
     OneMarketCompetition scenario) {
    PIDMaximizer delegate = new PIDMaximizer.ForHumanResources(plant, null, r);
    return new PIDMaximizerFacade(delegate, firm, plant,initialTarget);
  };




  static final HrStrategyInitialization KEYNESIAN_QUOTA =  (SISOPlant plant, Firm firm,
                                                            Random r, ZeroKnowledgeTrader seller,
                                                            OneMarketCompetition scenario)
  {

    double p = r.nextDouble() * (scenario.purchaseMaxP - scenario.purchaseMinP) +
               scenario.purchaseMinP;
    double i = r.nextDouble() * (scenario.purchaseMaxI - scenario
    .purchaseMinI)  + scenario.purchaseMinI;


    //here price really is people to hire
    BufferInventoryAdaptive quotaStrategy =
    new BufferInventoryAdaptive.simpleSeller(initialPrice:1.0,p:p,d:0.0,
                                             i:i,columnName: "quota");
    //we want to change L given the seller results rather than our own
    quotaStrategy.targetExtractingStockingUp = new OtherDataExtractor(seller,
                                                                      quotaStrategy.targetExtractingStockingUp);
    quotaStrategy.originalTargetExtractor = new OtherDataExtractor(seller,
                                                                   quotaStrategy.originalTargetExtractor);
    quotaStrategy.inventoryExtractor = new OtherDataExtractor(seller,
                                                              quotaStrategy.inventoryExtractor);
    quotaStrategy.delegate.cvExtractor = new OtherDataExtractor(seller,
                                                                quotaStrategy.delegate.cvExtractor);

    return quotaStrategy;
  };


  static final HrStrategyInitialization KEYNESIAN_STOCKOUT_QUOTA =
  KEYNESIAN_STOCKOUT_QUOTAS(1.0);

  static HrStrategyInitialization KEYNESIAN_STOCKOUT_QUOTAS(double
                                                            initialTarget) {
    return (SISOPlant
            plant, Firm firm,
            Random r, ZeroKnowledgeTrader seller,
            OneMarketCompetition scenario) {
      double p = r.nextDouble() * (scenario.purchaseMaxP - scenario.purchaseMinP) +
                 scenario.purchaseMinP;
      double i = r.nextDouble() * (scenario.purchaseMaxI - scenario
      .purchaseMinI) + scenario.purchaseMinI;


      //here price really is people to hire
      PIDAdaptive quotaStrategy =
      new PIDAdaptive.StockoutSeller(initialPrice:initialTarget, p:p, d:0.0,
                                     i:i);
      //we want to change L given the seller results rather than our own
      quotaStrategy.targetExtractor = new OtherDataExtractor(seller,
                                                             quotaStrategy.targetExtractor);
      quotaStrategy.cvExtractor = new OtherDataExtractor(seller,
                                                         quotaStrategy.cvExtractor);

      return quotaStrategy;
    };
  }


  SalesStrategyInitialization salesPricingInitialization = BUFFER_PID;


  /**
   * Price. Price never changes.
   */
  static SalesStrategyInitialization FIXED_PRICE =  (SISOPlant plant, Firm firm,
                                                     Random r,
                                                     OneMarketCompetition
                                                     scenario)
  {
    double price = r.nextDouble() * (scenario.minInitialPriceSelling - scenario
    .maxInitialPriceSelling)  + scenario.minInitialPriceSelling;
    FixedValue fixedPrice = new FixedValue(price);
    return fixedPrice;
  };


  static final SalesStrategyInitialization BUFFER_PID = (SISOPlant plant, Firm firm,
                                                         Random r,
                                                         OneMarketCompetition
                                                         scenario)
  {
    double p = r.nextDouble() * (scenario.salesMaxP - scenario.salesMinP) +
               scenario
               .salesMinP;
    double i = r.nextDouble() * (scenario.salesMaxI - scenario.salesMinI) +
               scenario
               .salesMinI;
    double initialPrice = r.nextDouble() *
                          (scenario.maxInitialPriceSelling - scenario.minInitialPriceSelling) +
                          scenario.minInitialPriceSelling;
    return new BufferInventoryAdaptive.simpleSeller(initialPrice:initialPrice,
                                                    p:p,d:0.0,i:i);
  };

  /**
   * just tries to sell inflow=outflow but it counts "stockouts" as outflows
   * as well so it doesn't need inventory buffers
   */
  static final SalesStrategyInitialization STOCKOUT_SALES = (SISOPlant plant,
                                                             Firm firm,
                                                             Random r,
                                                             OneMarketCompetition
                                                             scenario)
  {
    double p = r.nextDouble() * (scenario.salesMaxP - scenario.salesMinP) +
               scenario
               .salesMinP;
    double i = r.nextDouble() * (scenario.salesMaxI - scenario.salesMinI) +
               scenario
               .salesMinI;
    double initialPrice = r.nextDouble() *
                          (scenario.maxInitialPriceSelling - scenario.minInitialPriceSelling) +
                          scenario.minInitialPriceSelling;
    return new PIDAdaptive.StockoutSeller(initialPrice:initialPrice,p:p,i:i,
                                          d:0.0);
  };



  static final SalesStrategyInitialization
  PROFIT_MAXIMIZER_PRICING = (SISOPlant p,Firm firm,Random r,
                              OneMarketCompetition scenario)
  {
    double initialPrice = r.nextDouble() * (scenario.maxInitialPriceSelling -
                                            scenario
                                            .minInitialPriceSelling)  + scenario.minInitialPriceSelling;

    double pidMultiplier = r.nextDouble() * (scenario.salesMaxP - scenario
    .salesMinP) +
                           scenario
                           .salesMinP;


    PIDMaximizerFacade pricer = new PIDMaximizerFacade.PricingFacade(p,firm,r,
                                                                     initialPrice,20,pidMultiplier);
    return pricer;
  };

  SalesStrategyInitialization salesQuotaInitialization = ALL_OWNED;


  static final SalesStrategyInitialization ALL_OWNED = (SISOPlant plant, Firm
  firm,
                                                        Random r,
                                                        OneMarketCompetition
                                                        scenario)
  => new AllOwned();


  /**
   * called after sales has been built for further tuning. By default we just
   * put a last price predictor in there
   */
  TraderConsumer salesInitializer = (ZeroKnowledgeTrader sales){
    sales.predictor = new LastPricePredictor();
  };

  /**
   * called after hr has been built for further tuning. By default we just
   * put a last price predictor in there
   */
  TraderConsumer hrIntializer = (ZeroKnowledgeTrader hr){
    hr.predictor = new LastPricePredictor();
  };


  SISOProductionFunction productionFunction = new LinearProductionFunction();



  start(Model model) {

    Random random = model.random;


    laborMarket.start(model.schedule);
    model.markets["labor"] = laborMarket;

    //build sales market

    goodMarket.start(model.schedule);
    model.markets["gas"] = goodMarket;


    for(int competitor =0; competitor< competitors; competitor++) {
      Firm firm = new Firm();

      //build plant
      SISOPlant plant = new SISOPlant(firm.getSection("labor"),
                                      firm.getSection("gas"), productionFunction);
      firm.addPlant(plant);

      model.agents.add(firm);


      //build sales
      ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader(
          goodMarket, salesPricingInitialization(plant,firm,random,this) ,
          salesQuotaInitialization(plant,firm,random,this) ,
          new SimpleSellerTrading() ,firm);
      salesInitializer(seller);
      firm.addSalesDepartment(seller);


      //build hr
      (maxInitialPriceBuying - minInitialPriceBuying) + minInitialPriceBuying;
      ZeroKnowledgeTrader hr = new ZeroKnowledgeTrader(laborMarket,
                                                       hrPricingInitialization(plant, firm, random, seller,this),
                                                       hrQuotaInitializer(plant, firm, random, seller,this),
                                                       new SimpleBuyerTrading(), firm);
      hrIntializer(hr);
      firm.addPurchasesDepartment(hr);


      firms.add(firm);
      firm.start(model.schedule);


    }
  }

}




