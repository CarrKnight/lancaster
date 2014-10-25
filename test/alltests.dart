/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
import 'tools/tooltests.dart' as tools;
import 'engine/engine_test.dart' as engine;
import 'market/marketTest.dart' as market;
import 'agents/pricing_test.dart' as pricing;


void main(){
  tools.main();
  engine.main();
  market.main();
  pricing.main();
}