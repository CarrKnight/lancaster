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

    Object seedParameter = _root["seed"];
    num seed;
    if(seedParameter == null || !(seedParameter is num))
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
   * get whatever is at [address]. null if the address is invalid
   */
  Object _getFieldAt(List<String> address)
  {
    Object leaf = _root;
    for(String path in address)
    {
      leaf = leaf[path];
      //if the path doesn't exist, return null
      if(leaf == null)
        return null;
    }
    return leaf;
  }

  /**
   * navigate to [address]; returns null if the address is invalid
   */
  Object _getFieldAtPath(String address)
  {

    return _getFieldAt(address.split("."));

  }

  Object _lookup(String fieldName, String bestPath, String fallbackPath)
  {
    //todo log

    String address = bestPath.isEmpty ?  fieldName : "$bestPath.$fieldName";
    Object parameter =_getFieldAtPath(address);
    if(parameter == null && fallbackPath != null)
    {
      address = "$fallbackPath.$fieldName";
      parameter =_getFieldAtPath(address);
    }
    return parameter;
  }

  /**
   * get the parameter as a string, if possible. If you are looking for the parameter in : <br>
   * strategy1.strategy2.parameter  <br>
   * and if you don't find it then look in:  <br>
   * strategy3.parameter  <br>
   * then [fieldname] would be "parameter", [bestPath] would be "strategy1.strategy2" and [fallbackPath] would be "strategy3"
   * Throws an exception if it's not in either. Throws also an exception if the parameter is not a string but rather a map
   */
  String getAsString(String fieldName, String bestPath, [String fallbackPath=null])
  {

    Object parameter =  _lookup(fieldName,bestPath,fallbackPath);

    if(parameter ==null)
      throw new Exception("Couldn't find the field neither as $bestPath.$fieldName nor $fallbackPath.$fieldName");

    if(parameter is JsonObject)
      throw new Exception("The parameter is a map, not a string! ${parameter.toString()}");

    return parameter.toString();


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
   * then [fieldname] would be "parameter", [bestPath] would be "strategy1.strategy2" and [fallbackPath] would be "strategy3"
   * Throws an exception if it's not in either. Throws also an exception if the parameter is not a string but rather a map
   */
  num getAsNumber(String fieldName, String bestPath, [String fallbackPath=null])
  {

    Object parameter =  _lookup(fieldName,bestPath,fallbackPath);

    if(parameter ==null)
      throw new Exception("Couldn't find the field neither as $bestPath.$fieldName nor $fallbackPath.$fieldName");

    if(parameter is JsonObject)
      return _generateNumber(parameter);

    if(parameter is String)
      return num.parse(parameter);

    return parameter;


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