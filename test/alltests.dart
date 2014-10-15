/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
import 'tools/tooltests.dart' as tools;
import 'scheduleTest.dart' as schedule;
import 'market/marketTest.dart' as market;
import 'agents/pricingTest.dart' as pricing;


void main(){
  tools.main();
  schedule.main();
  market.main();
  pricing.main();
}