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
    cssUrl: 'packages/lancaster/view/charts/plot.css')
class BeveridgePlot implements ShadowRootAware{

  /***
   *     _  _   __    ___  __  ___    __ _  _  _  _  _  ____  ____  ____  ____
   *    ( \/ ) / _\  / __)(  )/ __)  (  ( \/ )( \( \/ )(  _ \(  __)(  _ \/ ___)
   *    / \/ \/    \( (_ \ )(( (__   /    /) \/ (/ \/ \ ) _ ( ) _)  )   /\___ \
   *    \_)(_/\_/\_/ \___/(__)\___)  \_)__)\____/\_)(_/(____/(____)(__\_)(____/
   */


  static const dataSize = 5;
  static const double aspectRatio=9.0/16.0;
  static const int padding = 30;
  int xTicks = 10;
  int yTicks = 5;
  int width;
  int height;

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
    _presentation = presentation;


    //reset local data by filling it with garbage
    for(int i=0;i<dataSize; i++)
      dataset.add(new MarketEvent(-1,-10.0,-10.0));


    //add real data if it exists
    for(MarketEvent event in _presentation.marketEvents)
    {
      dataset.removeFirst();
      dataset.addLast(event);
    }

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
      ..range = [padding,width-padding];


    yScale = new LinearScale()
      ..domain = [0,100]
      ..range = [height-padding,padding];


    xAxis = new SvgAxis()
      ..orientation = ORIENTATION_BOTTOM
      ..scale = xScale
      ..suggestedTickCount=xTicks;

    xAxisContainer = axisGroup.append("g")
      ..attr('transform', "translate(0,${height - padding})")
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
  SvgLine liner;

  static const CLIP_PATH_ID = "clippath";

  static final List<String> COLORS = ["rgb(86,180,233)",
  "rgb(240,228,66)",
  "rgb(0,114,178)",
  "rgb(204,94,0)",
  "rgb(0,158,115)"];
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
      ..attr("pointer-events", "all")
      ..attr("width", width - 2 * padding )
      ..attr("height", height - 2* padding);

    //just a rect to color the area
    areaMask = svg.append("rect")               //Make a new clipPath
      ..attr("id", "areamask")
      ..attr("pointer-events", "all")
      ..attr("clip-path","url(#$CLIP_PATH_ID)")
      ..attr("fill", "rgb(0,255, 255) ")
      ..attr("opacity", "0.1")
      ..attr("x", padding)
      ..attr("y", padding)
      ..attr("width", width - padding )
      ..attr("height", height - padding);

    //todo move this to css
    //highlight
    areaMask.on("mouseover",(d,i,e)=> areaMask.attr(
        "opacity","0.2"));
    areaMask.on("mouseout",(d,i,e)=> areaMask.attr(
        "opacity","0.1"));

  }

  /**
   * build things like fixed demand and supply curves
   */
  void _buildBackgroundCurves(Selection svg)
  {
    //line uniting the points
    liner = new SvgLine();
    liner.xAccessor = (d,i) => xScale.apply(d[0]);
    liner.yAccessor = (d,i)=>yScale.apply(d[1]);
    liner.defined = (List<double> d,i,e)=> d[0].isFinite && d[1].isFinite;

    //draw curves
    Selection curves = svg.append("g");
    curves.attr("pointer-events","all");
    curves.attr("clip-path","url(#clippath)");
    int i=0;
    print(_presentation.curveRepository.curves);
    for(ExogenousCurve curve in _presentation.curveRepository.curves )
    {
      String name = _presentation.curveRepository.getName(curve);
      Selection pathContainer = curves.append("g");
      pathContainer.attr("pointer-events","all");
      DataSelection path =  pathContainer.selectAll("path")
      .data([_presentation.curveRepository.curveToPath(curve,
                                                       0.0,100.0,0.0,100.0)]);
      var line = path.enter
      .append("path")
        ..attr("class","selectable line")
        ..attr("tooltip",name)
        ..attrWithCallback("d",(d,i,e)=>liner.path(d,i,e))
        ..attr('stroke', COLORS[i])
        ..attr('stroke-width', "2")
        ..attr("fill","none");
      HTML.Element lineElement = line.first;


      //add tooltip
      Tooltip tooltip = new Tooltip(lineElement);
      tooltip.message = _presentation.curveRepository.getName(curve);

      i++;
    }




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

  /**
   * a map circle to tooltips
   */
  List<Tooltip> dataToolTip = new List<Tooltip>();

  void _updateCircles(Selection circles)
  {
    circles
    //   .transition()
      ..attrWithCallback("cx",(MarketEvent datum, i, c)=>xScale.apply(datum.quantity))
      ..attrWithCallback("cy",(MarketEvent datum, i, c)=>yScale.apply(datum.price))
      ..attr("r",8)
      ..attrWithCallback("opacity",(datum, i, c)=>MATH.pow((i+1)/(dataset.length+1), 2))
    ;




    //if this is the first time you arrange them:
    if(!dataToolTip.isEmpty) {
      for (Tooltip t in dataToolTip) {
        t.killTooltip();
      }
      dataToolTip.clear();
    }
    circles.each((MarketEvent d, i, e)
                               {
                                 Tooltip t = new Tooltip(e);
                                 t.message="price: ${d.price
                                 .toStringAsFixed(2)}, day: ${d
                                 .day.toInt()}";
                               });



  }

  Selection _drawCircles(Selection svg)
  {

    //we need to put the circles in a group, so we can attach clip-path to it
    Selection circles = svg.append("g");
    circles.attr("pointer-events","all");

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

  //flag, starts false and becomes true when the chart is built
  bool ready = false;

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
      ..attr("width",width)
      ..attr("height",height);

    //build the axis
    _buildAxesAndScale(svg);
    //background
    _buildChartBackground(svg);
    //draw the curves
    _buildBackgroundCurves(svg);


    //circles
    _drawCircles(svg);
    //set yourself up to listen to the stream of data
    _listenToPresentation(svg);



    ready=true;


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
    _recomputeMetrics();
    _buildChart();

    HTML.window.onResize.listen((event)=>resize());

  }


  resize()
  {
    print("resize!");
    //you need to redraw everything!
    _recomputeMetrics();

    //remove previous svg
    chartLocation.firstChild.remove();
    //redraw it!
    _reset();
    _buildChart();
  }

  _recomputeMetrics() {
    width = chartLocation.borderEdge.width;
    height = (width * aspectRatio).round();
    xTicks = MATH.max(width/50, 2);
    yTicks = MATH.max(width/50, 2);
  }


  _reset(){
    xScale=null;
    yScale=null;
    xAxis=null;
    yAxis=null;
    yAxisContainer=null;
    xAxisContainer=null;
    clipPath=null;
    areaMask=null;
    liner=null;
    dataToolTip.clear();
  }


}


