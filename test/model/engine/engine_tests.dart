library engine_test;


/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
import 'schedule_test.dart' as schedule;
import 'model_test.dart' as model;
import 'one_market_test.dart' as one;
import 'database_test.dart' as db;



main(){
  model.main();
  schedule.main();
  one.main();
  db.main();
}
