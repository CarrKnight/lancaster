/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
import 'model/tools/tooltests.dart' as tools;
import 'model/engine/engine_test.dart' as engine;
import 'model/market/market_tests.dart' as market;
import 'model/agents/pricing_test.dart' as pricing;


void main(){
  tools.main();
  engine.main();
  market.main();
  pricing.main();
}