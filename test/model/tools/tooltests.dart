import 'agentDataTest.dart' as agent;
import 'pidTest.dart' as pid;
import 'inventoryTest.dart' as inventory;
import 'kalman_test.dart' as kalman;
/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

main() {
  agent.main();
  pid.main();
  inventory.main();
  kalman.main();
}
