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
  double production(double input);

  /**
   * how much of the input gets consumed
   */
  double consumption(double input);


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
  double multiplier;


  LinearProductionFunction({this.consumeInput:true, this.multiplier:1.0});
  /**
   * how much gets produced given this inventory
   */
  double production(double input) => input * multiplier;

  /**
   * how much of the input would get consumed during production?
   */
  double consumption(double input ) => consumeInput ? input : 0.0;

}

/**
 * output = [multiplier]*input^[exponent]
 */
class ExponentialProductionFunction implements SISOProductionFunction
{

  /**
   * how much gets produced even with no input
   */
  double freebie =0.0 ;

  double exponent;

  double multiplier;

  ExponentialProductionFunction({this.multiplier:1.0,this.exponent:1.0});


  /**
   * output = [multiplier]*input^[exponent]
   */
  double production(double input) => max(pow(input,exponent) * multiplier +
  freebie,0.0);

  /**
   * consume all
   */
  double consumption(double input ) => input;



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
  new LinearProductionFunction());


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
