library database.test;
import 'package:unittest/unittest.dart';
import 'dart:math';
import 'package:lancaster/model/lancaster_model.dart';
import 'package:json_object/json_object.dart';

main()
{

  String input =
  '''
{
  "array": [
    1,
    2,
    3
  ],
  "boolean": true,
  "null": null,
  "number": 123,
  "object": {
    "a": "b",
    "c": 5,
    "e": "10.5"
  },
  "string": "Hello World",

  "seed" : 12345,

  "scenario":
  {
    "type" : "lame",
    "parameter1" : 123,
    "parameter2" : true,
    "object":
    {
      "a": "b",
      "c": 5,
      "e":
      {
       "type" : "uniform",
       "min" : 5.0,
       "max" : 5.0
       }
    }
  }
}
  ''';

  group("parameter is a string",(){

    test('simple lookup works', (){

      ParameterDatabase db = new ParameterDatabase(input);

      expect(db.getAsString("object.a"),"b");
      expect(db.getAsString("scenario.object.a"),"b");

      expect(db.getAsString("string"),"Hello World");
      expect(db.getAsString("seed"),"12345");


    });

    test('fallback works', (){

      ParameterDatabase db = new ParameterDatabase(input);
      expect(db.getAsString("objetto.a","object.a"),"b");



    });


    test('wrong address throws exception', (){

      ParameterDatabase db = new ParameterDatabase(input);
      expect(() => db.getAsString("a","oggetto"), throws);

    });

    test('map is not a string, throws exception', (){

      ParameterDatabase db = new ParameterDatabase(input);
      expect(() => db.getAsString("object","scenario"), throws);

    });


  });



  group("parameter is a number",(){

    test('simple lookup works', (){

      ParameterDatabase db = new ParameterDatabase(input);

      expect(db.getAsNumber("object.c"),5);
      expect(db.getAsNumber("object.e"),closeTo(10.5,.001));

      expect(db.getAsNumber("seed"),12345);


    });

    test('fallback works', (){

      ParameterDatabase db = new ParameterDatabase(input);
      expect(db.getAsNumber("oggetto.e","object.e"),closeTo(10.5,.001));



    });


    test('wrong address throws exception', (){

      ParameterDatabase db = new ParameterDatabase(input);
      expect(() => db.getAsNumber("oggetto.a"), throws);

    });

    test('map gets randomized', (){

      ParameterDatabase db = new ParameterDatabase(input);
      expect(db.getAsNumber("scenario.object.e"),closeTo(5,.001));

    });

    test('unrecognized map is unrecognized!', (){

      ParameterDatabase db = new ParameterDatabase(input);
      expect(() => db.getAsNumber("scenario"),throws);

    });


  });

  group("Update parameter db",()
  {

    test('set strings work', (){

      ParameterDatabase db = new ParameterDatabase(input);

      expect(db.getAsString("object.a"),"b");
      db.setField("a","object","c");
      expect(db.getAsString("object.a"),"c");


    });



    test('set number work', (){

      ParameterDatabase db = new ParameterDatabase(input);

      expect(db.getAsNumber("object.c"),5);
      db.setField("c","object",100);
      expect(db.getAsNumber("object.c"),100);


    });

  });



  String input2 =
  '''
  {
  "non-default":
  {
    "class" : "TestClass",
    "library" : "database.test",
    "constructor" : "fromDB",
    "variable1": 10
  },
   "incomplete":
  {
    "variable1": 3
  },

  "default":
  {
    "testclass":
    {
      "class" : "TestClass",
      "library" : "database.test",
      "constructor" : "fromDB",
      "variable1": 5,
      "variable2": 12
    }

  }
}
  ''';

  group("Instantiate object",()
  {
    test('instantiates correctly', (){

      ParameterDatabase db = new ParameterDatabase(input2);
      //reads correctly
      expect(db.getAsNumber("default.testclass.variable2"),12);
      //now let's build
      TestClass ob = db.getAsInstance("non-default","");
      expect(ob.variable1,10); //best path has preference
      expect(ob.variable2,12); //not available on best path so it should have switched to default

    });

    //if there is an incomplete map it reads the constructor/class data from default
    test('incomplete is fine', (){

      ParameterDatabase db = new ParameterDatabase(input2);
      //now let's build
      TestClass ob = db.getAsInstance("incomplete","default.testclass");
      expect(ob.variable1,3); //best path has preference
      expect(ob.variable2,12); //not available on best path so it should have switched to default

    });
  });

}


class TestClass
{




  final int variable1;

  final int variable2;

  static const String _DEFAULT_DB_PATH= "default.testclass";

  TestClass(this.variable1,this.variable2);

  TestClass.fromDB(ParameterDatabase db,String alternativePath)
  :
  this(db.getAsNumber("$alternativePath.variable1","$_DEFAULT_DB_PATH.variable1"),
       db.getAsNumber("$alternativePath.variable2","$_DEFAULT_DB_PATH.variable2"));


}