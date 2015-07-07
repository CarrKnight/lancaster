import 'package:test/test.dart';
import 'package:lancaster/model/lancaster_model.dart';
import 'dart:collection';


main(){



  test("Simple Schedule",()
  {

    Schedule s = new Schedule();
    Queue toFill = new Queue();
    s.schedule(Phase.DAWN,(s)=>toFill.addLast(10));
    s.schedule(Phase.CLEANUP,(s)=>toFill.addLast(30));
    s.schedule(Phase.PRODUCTION,(s)=>toFill.addLast(15));
    s.schedule(Phase.PRODUCTION,(s)=>toFill.addLast(20));
    s.simulateDay();
    expect(toFill,[10,15,20,30]);

  });


  test("Tomorrow Schedule",()
  {

    Schedule s = new Schedule();
    Queue toFill = new Queue();
    int i = 10;
    Step stepper = (schedule){
      toFill.addLast(i);
      i+=10;
    };
    s.schedule(Phase.DAWN,(schedule) {
      stepper(schedule);
      s.scheduleTomorrow(stepper);
    });
    s.simulateDay();
    s.simulateDay();
    expect(toFill,[10,20]);

  });


  test("Repeating Schedule",()
  {

    Schedule s = new Schedule();
    Queue toFill = new Queue();
    s.scheduleRepeating(Phase.PRODUCTION,(schedule)=>toFill.addLast(10));

    s.simulateDay();
    s.simulateDay();
    s.simulateDay();
    s.simulateDay();
    expect(toFill,[10,10,10,10]);

  });



}

