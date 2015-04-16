/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of lancaster.model;





typedef AdaptiveStrategy  HrStrategyInitialization(SISOPlant plant, Firm firm,
                                                   Random r, ZeroKnowledgeTrader seller,
                                                   ParameterDatabase db,
                                                   String containerPath);

typedef AdaptiveStrategy SalesStrategyInitialization(SISOPlant plant, Firm firm,
                                                     Random r,
                                                     ParameterDatabase db,
                                                     String containerPath);

typedef void TraderConsumer(ZeroKnowledgeTrader trader);


class OneMarketCompetition extends Scenario
{


  String DB_ADDRESS = "default.scenario.OneMarketCompetition";





  SalesStrategyInitialization _generateSalesPricingFromDB(ParameterDatabase db)
  {
    String strategyName = db.getAsString("$DB_ADDRESS.salesPricingInitialization.salesPricingStrategy");
    if (strategyName == "FIXED_PRICE")
      return FIXED_PRICE;
    if (strategyName == "BUFFER_PID")
      return BUFFER_PID;
    if (strategyName == "STOCKOUT_SALES")
      return STOCKOUT_SALES;
    if (strategyName == "PROFIT_MAXIMIZER_PRICING")
      return PROFIT_MAXIMIZER_PRICING;

    throw new Exception("don't know what $strategyName is regarding sales pricing!");
    //salesPricingStrategy
  }

  List<Firm> firms = new List();



  /**
   * called to build the pricer of hr. By default it creates a marginal
   * maximizer
   */
  HrStrategyInitialization hrPricingInitialization;



  HrStrategyInitialization _generateHRPricingFromDB(ParameterDatabase db)
  {
    String strategyName = db.getAsString("$DB_ADDRESS.hrPricingInitialization.hrPricingStrategy");
    if (strategyName == "FIXED_TARGET_HR")
      return FIXED_TARGET_HR;
    if (strategyName == "MARGINAL_MAXIMIZER_HR")
      return MARGINAL_MAXIMIZER_HR;
    if (strategyName == "PID_MAXIMIZER_HR")
      return PID_MAXIMIZER_HR;
    if (strategyName == "FIXED_PRICE_HR")
      return FIXED_PRICE_HR;
    if (strategyName == "STICKY_STOCKOUT_QUOTA_BUYER")
      return STICKY_STOCKOUT_QUOTA_BUYER;

    throw new Exception("don't know what $strategyName is regarding hr pricing!");

  }

  //build labor market
  ExogenousBuyerMarket laborMarket;

  ExogenousSellerMarket goodMarket;


  static HrStrategyInitialization STICKY_STOCKOUT_QUOTA_BUYER = (SISOPlant plant, Firm firm,
                                                                 Random r,
                                                                 ZeroKnowledgeTrader seller,
                                                                 ParameterDatabase db,
                                                                 String containerPath)
  {

    PIDAdaptive pricing = new PIDAdaptive.
    StockoutQuotaBuyerFromDB(db,"$containerPath.STICKY_STOCKOUT_QUOTA_BUYER");


    pricing.pid = new StickyPID.Random(pricing.pid,r,
                                       db.getAsNumber("$containerPath.STICKY_STOCKOUT_QUOTA_BUYER.averagePIDPeriod"));
    return pricing;
  };



  /**
   * Price. Price never changes.
   */
  static HrStrategyInitialization FIXED_PRICE_HR = (SISOPlant plant, Firm firm,
                                                    Random r,
                                                    ZeroKnowledgeTrader seller,
                                                    ParameterDatabase db,
                                                    String containerPath)
  {
    FixedValue fixedPrice = new FixedValue.FromDB(db,"$containerPath.FIXED_PRICE_HR");
    return fixedPrice;
  };


  static HrStrategyInitialization FIXED_TARGET_HR =
      (SISOPlant plant,
       Firm firm, Random r, ZeroKnowledgeTrader seller,
       ParameterDatabase db,
       String containerPath //this will probably be DB_ADDRESS.
       )
  {
    return new PIDAdaptive.FixedInflowBuyerFromDB(db, "$containerPath.FIXED_TARGET_HR");
  };

  static final HrStrategyInitialization MARGINAL_MAXIMIZER_HR = (SISOPlant plant,
                                                                 Firm firm,
                                                                 Random r,
                                                                 ZeroKnowledgeTrader seller,
                                                                 ParameterDatabase db,
                                                                 String containerPath)
  {
    AdaptiveStrategy s = new PIDAdaptive.MaximizerBuyerFromDB(plant, firm, db,
                                                              "$containerPath.MARGINAL_MAXIMIZER_HR");
    return s;
  };

  static final HrStrategyInitialization PID_MAXIMIZER_HR = (SISOPlant plant,
                                                            Firm firm,
                                                            Random r,
                                                            ZeroKnowledgeTrader seller,
                                                            ParameterDatabase db,
                                                            String containerPath)
  {

    AdaptiveStrategy s = new PIDAdaptive.PIDMaximizerBuyerFromDB(plant, firm, db,
                                                                 "$containerPath.PID_MAXIMIZER_HR");
    return s;
  };


  HrStrategyInitialization hrQuotaInitializer;


  HrStrategyInitialization _generateHRQuotingFromDB(ParameterDatabase db)
  {

    String container = "$DB_ADDRESS.hrQuotaInitialization";
    String strategyName = db.getAsString("$container.hrQuotaStrategy");

    if (strategyName == "BUY_ALL")
      return BUY_ALL;
    if (strategyName == "MARSHALLIAN_QUOTA")
      return MARSHALLIAN_QUOTA;
    if (strategyName == "KEYNESIAN_QUOTA")
      return KEYNESIAN_QUOTA;
    if (strategyName == "KEYNESIAN_STOCKOUT_QUOTA")
      return KEYNESIAN_STOCKOUT_QUOTA;


    throw new Exception("I don't know how to instantiate $strategyName quota initializer");
  }


  static final HrStrategyInitialization BUY_ALL = (SISOPlant plant, Firm firm,
                                                   Random r, ZeroKnowledgeTrader seller,
                                                   ParameterDatabase db,
                                                   String containerPath)
  =>
  new FixedValue.FromDB(db, "$containerPath.BUY_ALL");

  /**
   * Useful when Marhsall meets infinitely elastic supply
   */
  static final HrStrategyInitialization MARSHALLIAN_QUOTA =
      (SISOPlant plant, Firm firm,
       Random r, ZeroKnowledgeTrader seller,
       ParameterDatabase db,
       String containerPath)
  {

    PIDMaximizer delegate = new PIDMaximizer.ForHumanResourcesFromDB(plant,null , db,
                                                                     "$containerPath.MARSHALLIAN_QUOTA");

    return new PIDMaximizerFacade(delegate, firm, plant,
                                  db.getAsNumber("$containerPath.MARSHALLIAN_QUOTA.currentTarget")
                                  );
  };


  static final HrStrategyInitialization KEYNESIAN_QUOTA =
      (SISOPlant plant, Firm firm,
       Random r, ZeroKnowledgeTrader seller,
       ParameterDatabase db,
       String containerPath)
  {

    //here price really is people to hire
    BufferInventoryAdaptive quotaStrategy =
    new BufferInventoryAdaptive.SimpleSellerFromDB(db, "$containerPath.KEYNESIAN_QUOTA");

    //we want to change L given the seller results rather than hr
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
      (SISOPlant
       plant, Firm firm,
       Random r, ZeroKnowledgeTrader seller,
       ParameterDatabase db,
       String containerPath)
  {


    //here price really is people to hire
    PIDAdaptive quotaStrategy =
    new PIDAdaptive.StockoutSellerFromDB(db, "$containerPath.KEYNESIAN_STOCKOUT_QUOTA");
    //we want to change L given the seller results rather than our own
    quotaStrategy.targetExtractor = new OtherDataExtractor(seller,
                                                           quotaStrategy.targetExtractor);
    quotaStrategy.cvExtractor = new OtherDataExtractor(seller,
                                                       quotaStrategy.cvExtractor);

    return quotaStrategy;
  };


  SalesStrategyInitialization salesPricingInitialization;


  /**
   * Price. Price never changes.
   */
  static SalesStrategyInitialization FIXED_PRICE = (SISOPlant plant, Firm firm,
                                                    Random r,
                                                    ParameterDatabase db,
                                                    String containerPath)
  {
    FixedValue fixedPrice = new FixedValue.FromDB(db,"$containerPath.FIXED_PRICE");
    return fixedPrice;
  };


  static final SalesStrategyInitialization BUFFER_PID = (SISOPlant plant, Firm firm,
                                                         Random r,
                                                         ParameterDatabase db,
                                                         String containerPath)
  {

    return new BufferInventoryAdaptive.SimpleSellerFromDB(db,"$containerPath.BUFFER_PID");
  };

  /**
   * just tries to sell inflow=outflow but it counts "stockouts" as outflows
   * as well so it doesn't need inventory buffers
   */
  static final SalesStrategyInitialization STOCKOUT_SALES = (SISOPlant plant,
                                                             Firm firm,
                                                             Random r,
                                                             ParameterDatabase db,
                                                             String containerPath)
  {

    return new PIDAdaptive.StockoutSellerFromDB(db,"$containerPath.STOCKOUT_SALES");
  };


  static final SalesStrategyInitialization
  PROFIT_MAXIMIZER_PRICING = (SISOPlant p, Firm firm, Random r,
                              ParameterDatabase db,
                              String containerPath)
  {

    PIDMaximizerFacade pricer = new PIDMaximizerFacade.
    FromDB(p,firm,db,"$containerPath.PROFIT_MAXIMIZER_PRICING");
    return pricer;
  };

  SalesStrategyInitialization salesQuotaInitialization = ALL_OWNED;


  static final SalesStrategyInitialization ALL_OWNED = (SISOPlant plant, Firm firm,
                                                        Random r,
                                                        ParameterDatabase db,
                                                        String containerPath)
  => new AllOwned();


  /**
   * called after sales has been built for further tuning. By default we just
   * put a last price predictor in there
   */
  TraderConsumer salesInitializer = (ZeroKnowledgeTrader sales) {
    sales.predictor = new LastPricePredictor();
  };

  /**
   * called after hr has been built for further tuning. By default we just
   * put a last price predictor in there
   */
  TraderConsumer hrIntializer = (ZeroKnowledgeTrader hr) {
    hr.predictor = new LastPricePredictor();
  };


  SISOProductionFunction productionFunction;


  start(Model model)
  {

    Random random = model.random;

    int competitors = model.parameters.getAsNumber("$DB_ADDRESS.competitors");


    if (laborMarket == null)//not overriden?
      laborMarket = model.parameters.getAsInstance("$DB_ADDRESS.laborMarket",
                                                   "${ExogenousBuyerMarket.DB_ADDRESS}");


    laborMarket.start(model.schedule,model);
    model.markets["labor"] = laborMarket;

    //build sales market
    if (goodMarket == null)//not overriden?
      goodMarket = model.parameters.getAsInstance("$DB_ADDRESS.goodMarket",
                                                  "${ExogenousSellerMarket.DB_ADDRESS}");
    goodMarket.start(model.schedule,model);
    model.markets["gas"] = goodMarket;

    //if it hasn't been overridden
    if (productionFunction == null)
      productionFunction = model.parameters.getAsInstance("$DB_ADDRESS.productionFunction");


    for (int competitor = 0; competitor < competitors; competitor++) {
      Firm firm = new Firm();

      //build plant
      SISOPlant plant = new SISOPlant(firm.getSection("labor"),
                                      firm.getSection("gas"), productionFunction);
      firm.addPlant(plant);

      model.agents.add(firm);


      if(salesPricingInitialization == null) //not overriden
        salesPricingInitialization=_generateSalesPricingFromDB(model.parameters);

      //build sales
      ZeroKnowledgeTrader seller = new ZeroKnowledgeTrader(
          goodMarket, salesPricingInitialization(plant, firm, random, model.parameters,
                                                 "$DB_ADDRESS.salesPricingInitialization"),
          salesQuotaInitialization(plant, firm, random, model.parameters,
                                   "$DB_ADDRESS.salesQuotaInitialization"),
          new SimpleSellerTrading(), firm);
      salesInitializer(seller);
      firm.addSalesDepartment(seller);


      //build hr
      if (hrPricingInitialization == null) //not overriden
        hrPricingInitialization = _generateHRPricingFromDB(model.parameters);

      if (hrQuotaInitializer == null) //not overriden
        hrQuotaInitializer = _generateHRQuotingFromDB(model.parameters);


      ZeroKnowledgeTrader hr = new ZeroKnowledgeTrader(laborMarket,
                                                       hrPricingInitialization(plant, firm, random, seller,
                                                                               model.parameters,
                                                                               "$DB_ADDRESS.hrPricingInitialization"),
                                                       hrQuotaInitializer(plant, firm, random, seller,
                                                                          model.parameters,
                                                                          "$DB_ADDRESS.hrQuotaInitialization"),
                                                       new SimpleBuyerTrading(), firm);
      hrIntializer(hr);
      firm.addPurchasesDepartment(hr);


      firms.add(firm);
      firm.start(model.schedule);


    }
  }



}






