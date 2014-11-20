/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
library agent_test;

import 'pricing_test.dart' as pricing;
import 'seller_test.dart' as seller;
import 'production_test.dart' as production;
import 'maximization_test.dart' as maximization;

main(){
  pricing.main();
  seller.main();
  production.main();
  maximization.main();
}