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

      expect(db.getAsString("a","object"),"b");
      expect(db.getAsString("a","scenario.object"),"b");

      expect(db.getAsString("string",""),"Hello World");
      expect(db.getAsString("seed",""),"12345");


    });

    test('fallback works', (){

      ParameterDatabase db = new ParameterDatabase(input);
      expect(db.getAsString("a","objetto","object"),"b");



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

      expect(db.getAsNumber("c","object"),5);
      expect(db.getAsNumber("e","object"),closeTo(10.5,.001));

      expect(db.getAsNumber("seed",""),12345);


    });

    test('fallback works', (){

      ParameterDatabase db = new ParameterDatabase(input);
      expect(db.getAsNumber("e","oggetto","object"),closeTo(10.5,.001));



    });


    test('wrong address throws exception', (){

      ParameterDatabase db = new ParameterDatabase(input);
      expect(() => db.getAsNumber("a","oggetto"), throws);

    });

    test('map gets randomized', (){

      ParameterDatabase db = new ParameterDatabase(input);
      expect(db.getAsNumber("e","scenario.object"),closeTo(5,.001));

    });

    test('unrecognized map is unrecognized!', (){

      ParameterDatabase db = new ParameterDatabase(input);
      expect(() => db.getAsNumber("scenario",""),throws);

    });


  });

  group("Update parameter db",()
  {

    test('set strings work', (){

      ParameterDatabase db = new ParameterDatabase(input);

      expect(db.getAsString("a","object"),"b");
      db.setField("a","object","c");
      expect(db.getAsString("a","object"),"c");


    });



    test('set number work', (){

      ParameterDatabase db = new ParameterDatabase(input);

      expect(db.getAsNumber("c","object"),5);
      db.setField("c","object",100);
      expect(db.getAsNumber("c","object"),100);


    });




  });

}