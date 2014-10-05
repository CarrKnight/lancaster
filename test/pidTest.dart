import 'package:unittest/unittest.dart';
import 'package:lancaster/src/tools/PIDController.dart';
import 'dart:math';


main(){


  test("error>0 increases mv ",(){
    PIDController controller = new PIDController.standardPI();
    controller.offset = 50.0;
    controller.adjust(50.0,0.0); //error = 50
    expect(controller.manipulatedVariable,
    60);
  }
  );

  test("error<0 decreases mv ",(){
    PIDController controller = new PIDController.standardPI();
    controller.offset = 50.0;
    controller.adjust(0.0,50.0); //error = -50
    expect(controller.manipulatedVariable,
    40);
  }
  );


  test("simple convergence ",(){
    PIDController controller = new PIDController(.01,.01,0);
    double target = 25.0;
    double output(PIDController)=>pow(controller.manipulatedVariable,2.0);
    for(int i=0; i<1000; i++) {
      print("${controller.manipulatedVariable} ${output(controller)} " );
      controller.adjust(target, output(controller));
    }
    expect(controller.manipulatedVariable,
    closeTo(5,.01));
  }
  );






}