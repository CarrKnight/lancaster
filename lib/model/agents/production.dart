/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.model;


/**
 * compute how much gets produced and how much gets consumed given inputs.
 * Doesn't actually produce anything. Useful for hypotheticals and marginals.
 * <br>
 * For now this only works on single input->single ouput. Might make more
 * complicated later
 */
class SISOProductionFunction
{

  bool consumeInput;

  /**
   * Consuming x input produces x*multiplier output
   */
  double multiplier;


  /**
   * how much gets produced given this inventory
   */
  SISOProductionFunction({this.consumeInput:true, this.multiplier:1.0});

  double production(double input) => input * multiplier;

  /**
   * how much of the input would get consumed during production?
   */
  double consumption(double input ) => consumeInput ? input : 0.0;

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
  this(inventory.getSection("gas"),inventory.getSection("labor"),
  new SISOProductionFunction());


  SISOPlant(this.output, this.input, this.function);

  /**
   * given this inventory, produce output and add it (and if needed consume
   * inputs)
   */
  void produce(){
      output.receive(function.production(input.amount));
      input.remove(function.consumption(input.amount));
  }



  String get inputType=>input.goodType;
  String get outputType=>output.goodType;
}
