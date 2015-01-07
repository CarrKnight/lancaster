
/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */


import 'package:unittest/unittest.dart';
import 'package:lancaster/model/lancaster_model.dart';



main() {

  //store here all the print statements
  var printLog = [];
  //override (!!!) top level function
  void print(String s) => printLog.add(s);


  test("Construct and schedules fine ",(){
    Schedule schedule = new Schedule();//set up schedule
    //set up agent and its step
    Data data = new Data( ["title1","title2"], (data)=>
        (Schedule s){print("a");}
                          );
    //start the data, should schedule the stepper
    data.start(schedule);
    schedule.simulateDay();
    schedule.simulateDay();
    schedule.simulateDay();
    expect(printLog,["a","a","a"]);
  }
       );

  test("Adds data correctly and can retrieve it just fine ",(){
    Schedule schedule = new Schedule();//set up schedule
    Data data = new Data(["title1","title2"], (data)=>
        (Schedule s){ //the update steps fills it with 1 and 2s
      data["title1"].add(1.0);
      data["title2"].add(2.0);
    }
                         );
    //start the data, should schedule the stepper
    data.start(schedule);
    schedule.simulateDay();
    schedule.simulateDay();
    schedule.simulateDay();
    expect(data.getObservations("title1"),[1,1,1]);
    expect(data.getObservations("title2"),[2,2,2]);
    expect(data.getLatestObservation("title1"),1.0);
    expect(data.getLatestObservation("title2"),2.0);
  }
       );

  test("Latest is latest ",(){
    double i=1.0;
    Schedule schedule = new Schedule();//set up schedule
    Data data = new Data(["title1"], (data)=>
        (Schedule s){ //the update steps fills it with 1 and 2s
      data["title1"].add(i);
      i++;
    }
                         );
    //start the data, should schedule the stepper
    data.start(schedule);
    schedule.simulateDay();
    schedule.simulateDay();
    schedule.simulateDay();
    expect(data.getObservations("title1"),[1.0,2.0,3.0]);
    expect(data.getLatestObservation("title1"),3);
  }
       );


  test("Plugin data generator works fine",(){
    Schedule schedule = new Schedule();//set up schedule
    Data data = new Data(["title1"], (data)=>
        (Schedule s){ //the update steps fills it with 1 and 2s
      data["title1"].add(1.0);}
                         );
    data.addColumn("title2",()=>2.0);
    //start the data, should schedule the stepper
    data.start(schedule);
    schedule.simulateDay();
    schedule.simulateDay();
    schedule.simulateDay();
    expect(data.getObservations("title1"),[1,1,1]);
    expect(data.getObservations("title2"),[2,2,2]);
    expect(data.getLatestObservation("title1"),1.0);
    expect(data.getLatestObservation("title2"),2.0);
  }
       );

  test("Plugin filler",(){
    Schedule schedule = new Schedule();//set up schedule
    Data data = new Data(["title1"], (data)=>
        (Schedule s){ //the update steps fills it with 1 and 2s
      data["title1"].add(1.0);}
                         );
    //start the data, should schedule the stepper
    data.start(schedule);
    schedule.simulateDay();
    schedule.simulateDay();
    schedule.simulateDay();
    data.addColumn("title2",()=>3.0,2.0); //added late, fills with 2.0 rather
    // than 3

    expect(data.getObservations("title1"),[1,1,1]);
    expect(data.getObservations("title2"),[2,2,2]);
    expect(data.getLatestObservation("title1"),1.0);
    expect(data.getLatestObservation("title2"),2.0);
  }
       );

  test("Plugin with the same title fails",(){
    Schedule schedule = new Schedule();//set up schedule
    Data data = new Data(["title1"], (data)=>
        (Schedule s){ //the update steps fills it with 1 and 2s
      data["title1"].add(1.0);}
                         );
    //start the data, should schedule the stepper
    data.start(schedule);
    schedule.simulateDay();
    schedule.simulateDay();
    schedule.simulateDay();
    //same title means failure: expect an exception
    expect(()=> data.addColumn("title1",()=>3.0,2.0),throws);



  }
       );



}