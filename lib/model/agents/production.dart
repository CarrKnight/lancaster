/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.model;


abstract class SISOProductionFunction
{
  /**
   * how much is produced given input
   */
  num production(num input);

  /**
   * how much of the input gets consumed
   */
  num consumption(num input);


}

/**
 * compute how much gets produced and how much gets consumed given inputs.
 * Doesn't actually produce anything. Useful for hypotheticals and marginals.
 * <br>
 * For now this only works on single input->single ouput. Might make more
 * complicated later
 */
class LinearProductionFunction implements SISOProductionFunction
{


  bool consumeInput;

  /**
   * Consuming x input produces x*multiplier output
   */
  num multiplier;

  static final String DB_ADDRESS = "default.strategy.LinearProductionFunction";

  LinearProductionFunction.FromDB(ParameterDatabase db, String container):
  this(
       db.getAsBoolean("$container.consumeInput","$DB_ADDRESS.consumeInput"),
       db.getAsNumber("$container.multiplier","$DB_ADDRESS.multiplier")
       );


  LinearProductionFunction(this.consumeInput, this.multiplier);
  /**
   * how much gets produced given this inventory
   */
  num production(num input) => input * multiplier;

  /**
   * how much of the input would get consumed during production?
   */
  num consumption(num input ) => consumeInput ? input : 0.0;

}

/**
 * output = [multiplier]*input^[exponent]
 */
class ExponentialProductionFunction implements SISOProductionFunction
{

  /**
   * how much gets produced even with no input
   */
  num freebie;

  num exponent;

  num multiplier;

  static final String DB_ADDRESS = "default.strategy.ExponentialProductionFunction";

  ExponentialProductionFunction.FromDB(ParameterDatabase db, String container):
  this(
      db.getAsNumber("$container.multiplier","$DB_ADDRESS.multiplier"),
      db.getAsNumber("$container.exponent","$DB_ADDRESS.exponent"),
      db.getAsNumber("$container.freebie","$DB_ADDRESS.freebie")
      );


  ExponentialProductionFunction(this.multiplier,this.exponent,this.freebie);


  /**
   * output = [multiplier]*input^[exponent]
   */
  num production(num input) => max(pow(input,exponent) * multiplier +
  freebie,0.0);

  /**
   * consume all
   */
  num consumption(num input ) => input;



}

/**
 * a plant is called during production to "produce": to add new goods to the
 * inventory
 */
class SISOPlant
{


  final InventoryCrossSection output;
  final InventoryCrossSection input;
  SISOProductionFunction function;


  SISOPlant.defaultSISO(Inventory inventory):
  this(inventory.getSection("labor"),inventory.getSection("gas"),
  new LinearProductionFunction(true,1.0));


  SISOPlant( this.input,this.output, this.function);

  /**
   * given this inventory, produce output and add it (and if needed consume
   * inputs)
   */
  void produce(){
      output.receive(function.production(input.amount));
      input.remove(function.consumption(input.amount));
  }

  /**
   * schedule itself to repeatedly produce
   */
  void start(Schedule schedule)
  {
    schedule.scheduleRepeating(Phase.PRODUCTION,(schedule)=>produce());
  }


  String get inputType=>input.goodType;
  String get outputType=>output.goodType;
}
