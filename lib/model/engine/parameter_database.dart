part of lancaster.model;


/**
 * Given a json file with all the parameters it organizes it in a simple database. Whatever else is in the parameters,
 * "seed" is reserved and used as seed for the randomizer. If "seed" doesn't exist in JSON or is not a
 * number then the current time will be used as seed
 *
 * a facade for a JsonObject tree; I don't let JsonObject out by itself mostly so I can keep a tight log
 * on what comes out and in.
 */
class ParameterDatabase
{


  final JsonObject _root;


  final Map<String,NumberGenerator> _generators = new Map();


  Random random;


  /**
   * navigate to [address]; returns null if the address is invalid
   */
  ParameterDatabase(String json):
  _root = new JsonObject.fromJsonString(json)
  {

    Object seedParameter = _root["run.seed"];
    num seed;
    if(seedParameter == null || !(seedParameter  == "milliseconds"))
      seed = new DateTime.now().millisecondsSinceEpoch;
    else
      seed = seedParameter;
    random = new Random(seed.toInt());

    //add default generators
    _generators["normal"] = DEFAULT_NORMAL;
    _generators["uniform"] = DEFAULT_UNIFORM;
    _generators["empirical"] = DEFAULT_EMPIRICAL;

  }


  /**
   * merge with new json. The new object overwrites any conflict
   */
  mergeWithJSON(String json)
  {

    JsonObject toAdd = new JsonObject.fromJsonString(json);
    mergeSecondIntoFirst(_root,toAdd);
  }

  mergeSecondIntoFirst(JsonObject first, JsonObject second)
  {
    //before we go any further, if there is a link in the original and no link in the new one, kill the link
    if(first["link"] != null && second["link"]==null && second.length > 0)
      first.remove("link");


    //go through each key
    List<String> keys = new List.from(first.keys);

    for(String key in keys)
    {
      Object firstValue = first[key];
      Object secondValue = second[key];

      //if it doesn't exist in the second value, ignore it
      if(secondValue == null)
        continue;
      if(firstValue is JsonObject)
      {
        //if they are both branches, recursively merge
        if(secondValue is JsonObject)
          mergeSecondIntoFirst(firstValue,secondValue);
        else
        {
          //here it is neither null nor a branch, overwrites the old branch
          assert(secondValue != null);
          first[key] = secondValue;
        }
      }
      else
      {
        //the old tree has a leaf here, if the second has anything it overwrites
        if(secondValue != null)
          first[key] = secondValue;
      }
    }


    //now go through all the second object keys, if they don't exist in the first, add them immediately
    for(String key in second.keys)
    {
      if(!first.containsKey(key))
      {
        first.isExtendable = true; //briefly make it extendable
        first[key] = second[key];
        first.isExtendable = false; //clamp it again!
      }
    }



  }


  /**
   * get whatever is at [address]. null if the address is invalid
   */
  Object _getFieldAt(List<String> address)
  {
    Object leaf = _root;
    for(String path in address)
    {
      Object newLeaf = leaf[path];
      //if the path doesn't exist, return null
      if(newLeaf == null)
      {
        //is it a link?
        if(leaf["link"] == null)
          //no
          return null;
        else
        {//yes, then follow the link
          return _getFieldAt(leaf["link"]);
        }
      }
      leaf = newLeaf;
    }

    //if you landed on a link, follow it
    if(leaf is JsonObject && leaf["link"] != null)
      return _getFieldAtPath(leaf["link"]);

    return leaf;
  }

  /**
   * navigate to [address]; returns null if the address is invalid
   */
  Object _getFieldAtPath(String address)
  {

    return _getFieldAt(address.split("."));

  }

  Object _lookup(String bestPath, String fallbackPath)
  {
    //todo log

    Object parameter =_getFieldAtPath(bestPath);
    if(parameter == null && fallbackPath != null)
    {
      parameter =_getFieldAtPath(fallbackPath);
    }
    return parameter;
  }

  /**
   * get the parameter as a string, if possible. If you are looking for the parameter in : <br>
   * strategy1.strategy2.parameter  <br>
   * and if you don't find it then look in:  <br>
   * strategy3.parameter  <br>
   *[bestPath] would be "strategy1.strategy2.parameter" and [fallbackPath] would be "strategy3".parameter
   * Throws an exception if it's not in either. Throws also an exception if the parameter is not a string but rather a map
   */
  String getAsString(String bestPath, [String fallbackPath=null])
  {

    Object parameter =  _lookup(bestPath,fallbackPath);

    if(parameter ==null)
      throw new Exception("Couldn't find the field neither as $bestPath nor $fallbackPath");

    if(parameter is JsonObject)
      throw new Exception("The parameter is a map, not a string! ${parameter.toString()}");

    return parameter.toString();


  }


  /**
   * get the parameter as a boolean, if possible. If you are looking for the parameter in : <br>
   * strategy1.strategy2.parameter  <br>
   * and if you don't find it then look in:  <br>
   * strategy3.parameter  <br>
   *[bestPath] would be "strategy1.strategy2.parameter" and [fallbackPath] would be "strategy3".parameter
   * Throws an exception if it's not in either. Throws also an exception if the parameter is not a string but rather a map
   */
  bool getAsBoolean(String bestPath, [String fallbackPath=null])
  {

    Object parameter =  _lookup(bestPath,fallbackPath);

    if(parameter ==null)
      throw new Exception("Couldn't find the field neither as $bestPath nor $fallbackPath");

    if(parameter is JsonObject)
      throw new Exception("The parameter is a map, not a string! ${parameter.toString()}");

    return parameter;


  }


  /**
   * if you need a number but you got a map it might be a random parameter. Check if it has a type and if so feed it to the
   * randomizer
   */
  num _generateNumber(JsonObject parameter)
  {

    String type = parameter["type"];
    if(type == null)
      throw new Exception(" you are trying to turn $parameter into a number.It iss neither a number nor has a type to randomize");

    NumberGenerator generator = _generators[type];

    if(generator == null)
      throw new Exception("types of randomizers known: ${_generators.keys} , $type isn't one of them!");

    return generator(parameter,random);



  }



  /**
   * get the parameter as a number; If the field is a number, then it is returned immediately; if it is a map, it is fed to the number
   * generator associated with its "type" field. <br>
   * If you are looking for the parameter in : <br>
   * strategy1.strategy2.parameter  <br>
   * and if you don't find it then look in:  <br>
   * strategy3.parameter  <br>
   * then [bestPath] would be "strategy1.strategy2.parameter" and [fallbackPath] would be "strategy3.parameter"
   * Throws an exception if it's not in either. Throws also an exception if the parameter is not a string but rather a map
   */
  num getAsNumber(String bestPath, [String fallbackPath=null])
  {

    Object parameter =  _lookup(bestPath,fallbackPath);

    if(parameter ==null)
      throw new Exception("Couldn't find the field neither as $bestPath nor $fallbackPath");

    if(parameter is JsonObject)
      return _generateNumber(parameter);



    if(parameter is String)
      return num.parse(parameter);

    return parameter;


  }


  //todo when dart implements generic methods make this into one
  /**
   * use reflect to create an instance of the class with constructor [constructorName] having 2 parameters:
   * ParameterDataBase and String optionalArgument (usually a sub-path).
   */
  Object _instantiate(String className, String libraryName, String constructorName, String optionalArgument )
  {

    MirrorSystem mirrors = currentMirrorSystem();
    LibraryMirror lm = mirrors.libraries.values.firstWhere(
            (LibraryMirror lm) => lm.qualifiedName == new Symbol(libraryName));

    ClassMirror cm = lm.declarations[new Symbol(className)];

    InstanceMirror im = cm.newInstance(new Symbol(constructorName), [this,optionalArgument]);

    return im.reflectee;

  }
  //todo when dart implements generic methods make this into one

  /**
   * turns the field into an instance. It looks for 3 fields, "class","library" and "constructor". The last is optional
   * and is the name of the constructor to use (if none, use the default one), library and class are needed to know what
   * class this object actually is. It searches for each field separately first in the best path then in the fallback one <br>
   * Notice that the constructor must be with parameters (ParameterDatabase,String), at least for now!
   */
  Object getAsInstance(String bestPath, [String fallbackPath=null])
  {

    String className = getAsString("$bestPath.class","$fallbackPath.class");
    String libraryName = getAsString("$bestPath.library","$fallbackPath.library");
    String constructorName = getAsString("$bestPath.constructor","$fallbackPath.constructor");
    if(constructorName == null)
      constructorName = ""; //default constructor if no constructor name is provided

    assert(className != null);
    assert(libraryName != null);

    //instantiate it then, passing as optional parameter the address of the class.
    return _instantiate(className,libraryName,constructorName,bestPath);



  }






  /**
   * set path.fieldName to value. Over-writes with no mercy. [path] must exists, even if [fieldname] doesn't
   */
  void setField(String fieldName, String path, Object value )
  {
    JsonObject json = _getFieldAtPath(path);
    json[fieldName] = value;

  }

  /**
   * set path.fieldName to json. [path] must exists, even if [fieldname] doesn't
   */
  void setFieldToJson(String fieldName, String path, String jsonValue )
  {
    JsonObject json = _getFieldAtPath(path);
    json[fieldName] = new JsonObject.fromJsonString(jsonValue);

  }






}