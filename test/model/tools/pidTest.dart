
library pidtest;


import 'package:test/test.dart';
import 'package:lancaster/model/lancaster_model.dart';
import 'package:mockito/mockito.dart';
import 'dart:math';



class MockController extends Mock implements Controller{}
class MockRandom extends Mock implements Random{}

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
    PIDController controller = new PIDController(.01,.01,0.0);
    double target = 25.0;
    double output(PIDController)=>pow(controller.manipulatedVariable,2.0);
    for(int i=0; i<1000; i++) {
//      print("${controller.manipulatedVariable} ${output(controller)} " );
      controller.adjust(target, output(controller));
    }
    expect(controller.manipulatedVariable,
    closeTo(5,.01));
  }
  );


  test("delays correctly nonrandom",(){
    MockController controller = new MockController();
    StickyPID pid = new StickyPID.Fixed(controller,3);
    //first two days no adjust
    pid.adjust(0.0,0.0);
    verifyNever(controller.adjust(any,any));
    pid.adjust(0.0,0.0);
    verifyNever(controller.adjust(any,any));
    //adjust on the third day!
    pid.adjust(0.0,0.0);
    verify(controller.adjust(any,any));
    //two more days with no steps
    pid.adjust(0.0,0.0);
    verifyNever(controller.adjust(any,any));
    pid.adjust(0.0,0.0);
    verifyNever(controller.adjust(any,any));
    //again on the third day!
    pid.adjust(0.0,0.0);
    verify(controller.adjust(any,any));
  });

  test("delays correctly random",(){
    MockController controller = new MockController();
    MockRandom random = new MockRandom();
    StickyPID pid =new StickyPID.Random(controller,random,1);
    //as long as the random is too high, it doesn't happen
    when(random.nextDouble()).thenReturn(1.0);;
    for(int i=0; i<10; i++)
      pid.adjust(0.0,0.0);
    verifyNever(controller.adjust(any,any));

    when(random.nextDouble()).thenReturn(0.499);;
    pid.adjust(0.0,0.0);
    verify(controller.adjust(any,any));
  });

}