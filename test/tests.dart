/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

import 'model/tools/tooltests.dart' as tools;
import 'model/engine/engine_tests.dart' as engine;
import 'model/market/market_tests.dart' as market;
import 'model/agents/agent_tests.dart' as agent;
import 'presentation/presentation_test.dart' as presentation;



void main(){
  tools.main();
  engine.main();
  market.main();
  agent.main();
  presentation.main();

}