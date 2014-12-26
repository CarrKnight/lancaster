/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.view;


/**
 * for now just a simple list of trades + ugly chart
 */
@Component(
    selector: 'beveridgeplot',
    templateUrl: 'packages/lancaster/view/charts/plot.html',
    cssUrl: 'packages/lancaster/view/charts/plot.css',
    publishAs: 'beveridge')
class BeveridgePlot implements ShadowRootAware{

  /***
   *     _  _   __    ___  __  ___    __ _  _  _  _  _  ____  ____  ____  ____
   *    ( \/ ) / _\  / __)(  )/ __)  (  ( \/ )( \( \/ )(  _ \(  __)(  _ \/ ___)
   *    / \/ \/    \( (_ \ )(( (__   /    /) \/ (/ \/ \ ) _ ( ) _)  )   /\___ \
   *    \_)(_/\_/\_/ \___/(__)\___)  \_)__)\____/\_)(_/(____/(____)(__\_)(____/
   */


  static const dataSize = 5;
  static const int w=600;
  static const int h=300;
  static const int padding = 30;
  static const int xTicks = 10;
  static const int yTicks = 5;

  /***
   *     ____  _  _  __ _  ____   __   _  _  ____  __ _  ____  __   __    ____
   *    (  __)/ )( \(  ( \(    \ / _\ ( \/ )(  __)(  ( \(_  _)/ _\ (  )  / ___)
   *     ) _) ) \/ (/    / ) D (/    \/ \/ \ ) _) /    /  )( /    \/ (_/\\___ \
   *    (__)  \____/\_)__)(____/\_/\_/\_)(_/(____)\_)__) (__)\_/\_/\____/(____/
   */

  /**
   * here we store the latest market events. It gets initially filled at
   * constructor time and then updated by listening to the market stream from
   * presentatino
   */
  ListQueue<MarketEvent> dataset = new ListQueue();


  /**
   * the html node containing the plot. It unfortunately doesn't exist
   * immediately so we fill it in onShadowRoot()
   */
  HTML.Element chartLocation;

  /**
   * the presentation object which is our interface to the model itself
   */
  SimpleMarketPresentation _presentation;

  @NgOneWay('presentation')
  set presentation(SimpleMarketPresentation presentation)
  {
    //reset local data by filling it with garbage
    for(int i=0;i<dataSize; i++)
      dataset.add(new MarketEvent(-1,-10.0,-10.0));

    _presentation = presentation;
    _buildChart();
  }



  /***
   *      __   _  _  __  ____
   *     / _\ ( \/ )(  )/ ___)
   *    /    \ )  (  )( \___ \
   *    \_/\_/(_/\_)(__)(____/
   */

  LinearScale xScale;
  LinearScale yScale;
  SvgAxis xAxis;
  SvgAxis yAxis;
  Selection yAxisContainer;
  Selection xAxisContainer;


  void _buildAxesAndScale(Selection axisGroup)
  {
    //create the scales so we can easily translate coordinates to pixels
    xScale = new LinearScale()
      ..domain = [0,100]
      ..range = [padding,w-padding];


    yScale = new LinearScale()
      ..domain = [0,100]
      ..range = [h-padding,padding];


    xAxis = new SvgAxis()
      ..orientation = ORIENTATION_BOTTOM
      ..scale = xScale
      ..suggestedTickCount=xTicks;

    xAxisContainer = axisGroup.append("g")
      ..attr('transform', "translate(0,${h - padding})")
      ..attr("class","axis");
    xAxis.axis(xAxisContainer);

    yAxis = new SvgAxis()
      ..orientation = ORIENTATION_LEFT
      ..scale = yScale
      ..suggestedTickCount=yTicks;

    yAxisContainer = axisGroup.append("g")
      ..attr('transform', "translate(${padding},0)")
      ..attr("class","axis");
    yAxis.axis(yAxisContainer);
  }

  /***
   *     ____   __    ___  __ _  ___  ____   __   _  _  __ _  ____
   *    (  _ \ / _\  / __)(  / )/ __)(  _ \ /  \ / )( \(  ( \(    \
   *     ) _ (/    \( (__  )  (( (_ \ )   /(  O )) \/ (/    / ) D (
   *    (____/\_/\_/ \___)(__\_)\___/(__\_) \__/ \____/\_)__)(____/
   */

  Selection clipPath;
  Selection areaMask;

  static const CLIP_PATH_ID = "clippath";
  /**
   * builds a clip-path to avoid drawing out of boundaries and a background
   * area to color
   */
  void _buildChartBackground(Selection svg)
  {
    //clip-path is basically an area container
    //it works to contain the circles
    clipPath =svg.append("clipPath")               //Make a new clipPath
      ..attr("id", CLIP_PATH_ID);             //Assign an ID
    Selection clipPathRectangle = clipPath.append("rect")
    //  ..attr("opacity", "0.1 ")
    //Set rect's position and size…
      ..attr("x", padding)
      ..attr("y", padding)
      ..attr("width", w - 2 * padding )
      ..attr("height", h - 2* padding);

    //just a rect to color the area
    areaMask = svg.append("rect")               //Make a new clipPath
      ..attr("id", "areamask")
      ..attr("clip-path","url(#$CLIP_PATH_ID)")
      ..attr("fill", "rgb(0,255, 255) ")
      ..attr("opacity", "0.1")
      ..attr("x", padding)
      ..attr("y", padding)
      ..attr("width", w - padding )
      ..attr("height", h - padding);

    //todo move this to css
    //highlight
    areaMask.on("mouseover",(d,i,e)=> areaMask.transition().attr(
        "opacity","0.2"));
    areaMask.on("mouseout",(d,i,e)=> areaMask.transition().attr(
        "opacity","0.1"));
  }


  /***
   *     ____   __  ____  _  _  ____
   *    (  _ \ / _\(_  _)/ )( \/ ___)
   *     ) __//    \ )(  ) __ (\___ \
   *    (__)  \_/\_/(__) \_)(_/(____/
   */

  /**
   * turn dataset into a format that charted can plot with ease
   */
  List<List<List<MarketEvent>>> _segments(){


    var toReturn = [];
    for(int i=0; i<dataset.length-1;i++)
    {
      toReturn.add([dataset.elementAt(i),dataset.elementAt(i+1)]);
    }
    return toReturn;


  }



  /***
   *      ___  __  ____   ___  __    ____  ____
   *     / __)(  )(  _ \ / __)(  )  (  __)/ ___)
   *    ( (__  )(  )   /( (__ / (_/\ ) _) \___ \
   *     \___)(__)(__\_) \___)\____/(____)(____/
   */


  static const CIRCLES_ID = "beveridge_data";

  void _updateCircles(Selection circles)
  {
    circles
    .transition()
      ..attrWithCallback("cx",(MarketEvent datum, i, c)=>xScale.apply(datum.quantity))
      ..attrWithCallback("cy",(MarketEvent datum, i, c)=>yScale.apply(datum.price))
      ..attr("r",5)
      ..attrWithCallback("opacity",(datum, i, c)=>MATH.pow((i+1)/(dataset.length+1), 2));



    //highlight them a bit

    circles.on("mouseover",null); //remove previous one
    circles.on("mouseover",(d,i, element)
    {
      print(d);
    });

  }

  Selection _drawCircles(Selection svg)
  {

    //we need to put the circles in a group, so we can attach clip-path to it
    Selection circles = svg.append("g");
    circles.attr("id","beveridge_data");
    circles.attr("clip-path","url(#clippath)");


    circles = circles
    .selectAll("circle")
    .data(dataset)
    .enter
    .append("circle");

    circles.attr("class","selectable datapoints");


    //place them
    _updateCircles(circles);



    return circles;
  }

  /**
   * this get actually called twice, but it runs only once. We need the
   * presentation object (which is given to us by whoever instantiates us)
   * and the chartLocation object (which gets created when the shadow root or
   * its substitute is ready). Whenever one of those two is set, they call
   * _buildChart() but the chart gets actually built only when both are set
   */
  void _buildChart(){

    /**
     * if either is null, wait for the other!
     */
    if(chartLocation == null || _presentation == null)
      return;

    //create the svg uber node
    Selection svg = new SelectionScope.element(chartLocation)
    .append("svg:svg") //notice that charted for a few nodes has to do name:name
      ..attr("width",w)
      ..attr("height",h);

    //build the axis
    _buildAxesAndScale(svg);
    //background
    _buildChartBackground(svg);
    //circles
    _drawCircles(svg);
    //set yourself up to listen to the stream of data
    _listenToPresentation(svg);







  }




  void _listenToPresentation(Selection svg){
    _presentation.marketStream.listen((event){
      print([event.day,  event.price]);

      //useless observation
      if(!event.quantity.isFinite || !event.price.isFinite)
        return;

      dataset.removeFirst();
      dataset.addLast(event);

      //update circles
      _updateCircles(
      //find it by id
          svg.select("#beveridge_data").selectAll("circle").data(dataset)
      );

    });

  }




  /**
   * so actually this gets called even when there is no shadowroot; it's very
   * handy though because when this is called we know the html is ready to be
   * selected
   */
  void onShadowRoot(HTML.ShadowRoot shadowRoot){
    chartLocation=shadowRoot.querySelector('.price-chart');
    _buildChart();
  }






}


