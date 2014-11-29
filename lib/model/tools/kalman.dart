/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.model;

/**
 * mostly a copy-paste job from the good trusty java version. Lack of syntax
 * for 2d arrays is quite annoying.
 */
class KalmanFilter
{
  /**
   * here we keep the gains
   */
  final List<double> kGains;

  /**
   * here we keep the P matrix
   */
  List<List<double>> pCovariance;

  /**
   * the coefficients proper
   */
  final List<double> beta;

  /**
   * A variance to subject the betas to
   */
  double noiseVariance = 1.0;




  /**
   * create an empty kalman filter
   */
  KalmanFilter(int dimensions,[double covariancePrior=1000000.0]):
  kGains = new List(dimensions),
  beta = new List.filled(dimensions,0.0),
  pCovariance = new List(dimensions)
  {
    for(int i=0;i<dimensions; i++) {
      pCovariance[i] = new List.filled(dimension,0.0);
      pCovariance[i][i]=covariancePrior;
    }
  }

  void addObservation(double observationWeight, double y,
                      List<double> observation)
  {
  assert(observation.length == dimension);


  /****************************************************
   * compute K!
   ***************************************************/
  _updateKGains(observation,observationWeight);
  /****************************************************
   * Update Beta!
   ***************************************************/
  _updateBeta(y, observation);
  /****************************************************
   * Update P
   ***************************************************/
  _updateCovarianceP(observation);

  }


  void _updateBeta(double y, List<double> observation) {
    double predicted = 0.0;
    for(int i=0; i< dimension; i++)
      predicted += beta[i] * observation[i];
    double residual = y - predicted;

    List<double> weightedResidual = new List(dimension);
    for(int i=0; i < dimension; i++)
      weightedResidual[i] = residual * kGains[i];

    //update beta
    for(int i=0; i< dimension; i++)
      beta[i] = beta[i] + weightedResidual[i];

  }

  void _updateKGains(List<double> observation, double weight) {

    //compute error dispersion
    //P*x
    List<double> px = new List.filled(dimension,0.0);
    for(int i=0; i<dimension; i++)
    {
      for(int j=0; j<dimension; j++) {
        px[i] += pCovariance[i][j] * observation[j];
      }
    }

    double denominator = 0.0;
    for(int i=0; i<dimension; i++)
      denominator += observation[i] * px[i];
    denominator += noiseVariance / weight;

    if(denominator != 0){
      //divide, that's your K gain
      for(int i=0; i< px.length; i++)
      {
        kGains[i] = px[i]/denominator;
        assert(kGains[i].isFinite);
      }
    }
  }

  void _updateCovarianceP(List<double> observation) {
    List<List<double>> toMultiply = new List(dimension);
    for(int i=0;i<dimension; i++)
      toMultiply[i]=new List(dimension);


    for(int i=0; i< dimension; i++)
      for(int j=0; j<dimension; j++)
      {
        toMultiply[i][j]=-(kGains[i]*observation[j]);
        if(i==j)
          toMultiply[i][j]+=1; //diagonal element needs to be summed to a diag(1)
      }




    List<List<double>> newP =  new List(dimension);
    for(int i=0;i<dimension; i++)
      newP[i] = new List.filled(dimension,0.0);

    for(int row=0; row<dimension; row++)
    {
      for(int column=0; column<dimension; column++)
      {
        for(int i=0; i<dimension; i++)
        {
          newP[row][column] +=toMultiply[row][i] * pCovariance[i][column];
        }
      }

    }
    //todo reject if any eigenvalue is negative


    //copy the new result into the old matrix
    pCovariance = newP;





  }



  int get dimension => kGains.length;

}





