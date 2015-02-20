part of lancaster.model;

/**
 * sometimes the user needs a number, but the JSON field is actually a map. The number
 * generator is supposed to turn it into a number
 */
typedef num NumberGenerator(JsonObject leaf, Random random);



final NumberGenerator DEFAULT_UNIFORM = (JsonObject leaf,Random random)
{
  assert(leaf.type == "uniform");
  //read max and min from the list!
  num maximum= leaf["max"];
  num minimum= leaf["min"];

  return random.nextDouble() * (maximum-minimum) + minimum;
};



final NumberGenerator DEFAULT_NORMAL = (JsonObject leaf,Random random)
{

  //here I use the ratio-of-uniforms method
  //see here: http://stackoverflow.com/questions/13001485/implementing-the-ratio-of-uniforms-for-normal-distribution-in-c
  assert(leaf.type == "normal");
  //read the two parameters from the list
  num mu= leaf.mean;
  num sigma= leaf.sigma;

  while(true)
  {
    num u=random.nextDouble();
    num v=1.7156*(random.nextDouble()-0.5);
    num x=u-0.449871;
    num y=v.abs()+0.386595;
    num q=x*x+y*(0.19600*y-0.25472*x);
    if(!(q>0.27597 && (q>0.27846 || v*v>-4*log(u)*u*u)))
      return  mu + sigma * (v/u);
  }

};


/**
 * random number generator that chooses at random from a list of numbers
 */
final NumberGenerator  DEFAULT_EMPIRICAL= (JsonObject leaf,Random random)
{

  //here I use the ratio-of-uniforms method
  //see here: http://stackoverflow.com/questions/13001485/implementing-the-ratio-of-uniforms-for-normal-distribution-in-c
  assert(leaf.type == "empirical");
  //read the two parameters from the list
  List<num> sample = leaf.sample;
  assert(sample.length > 0);


  return sample.elementAt(random.nextInt(sample.length));






};






