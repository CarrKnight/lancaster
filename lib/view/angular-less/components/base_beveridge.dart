/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.view2;

/**
 * function called every day to extract from the event a new x-y relationship.
 * If it returns null, we ignore the observation.
 */
//extract datum from daily observation
typedef BeveridgeDatum DailyDataExtractor<E extends PresentationEvent>(E event);

//initialize data (return a list?)
typedef List<BeveridgeDatum> DataInitializer<E extends PresentationEvent>
    (Presentation<E> presentation);

//initialize data (return a list?)
typedef CurveRepository RepositoryGetter<E extends PresentationEvent>
    (Presentation<E> presentation);


/**
 * a way to plot price-quantity or whatever other 2d relationship over time,
 * possibly with other drawn curves to help figure stuff out.
 *
 * It updates by listening every day to a presentation and its events
 */
abstract class BeveridgePlot<E extends PresentationEvent>{

  /***
   *     _  _   __    ___  __  ___    __ _  _  _  _  _  ____  ____  ____  ____
   *    ( \/ ) / _\  / __)(  )/ __)  (  ( \/ )( \( \/ )(  _ \(  __)(  _ \/ ___)
   *    / \/ \/    \( (_ \ )(( (__   /    /) \/ (/ \/ \ ) _ ( ) _)  )   /\___ \
   *    \_)(_/\_/\_/ \___/(__)\___)  \_)__)\____/\_)(_/(____/(____)(__\_)(____/
   */


  static const dataSize = 5;
  static const num aspectRatio=9.0/16.0;
  static const int padding = 30;
  int xTicks = 10;
  int yTicks = 5;
  int width;
  int height;
  double _resizeScale = 1.0;

  /***
   *     ____  _  _  __ _  ____   __   _  _  ____  __ _  ____  __   __    ____
   *    (  __)/ )( \(  ( \(    \ / _\ ( \/ )(  __)(  ( \(_  _)/ _\ (  )  / ___)
   *     ) _) ) \/ (/    / ) D (/    \/ \/ \ ) _) /    /  )( /    \/ (_/\\___ \
   *    (__)  \____/\_)__)(____/\_/\_/\_)(_/(____)\_)__) (__)\_/\_/\____/(____/
   */



  /**
   * the presentation object which is our interface to the model itself
   */
  Presentation<E> _presentation;

  /**
   *  called every day to extract a x-y relationship from the event
   */
  final DailyDataExtractor<E> dailyDataExtractor;


  /**
   *  called every day to extract a x-y relationship from the event
   */
  final DataInitializer<E> dataInitializer;

  /**
   * the container that holds the plot
   */
  final HTML.DivElement _chartLocation;

  BeveridgePlot(this._chartLocation, this._presentation,
                this.dailyDataExtractor, this.dataInitializer,
                {resizeScale : 1.0})
  {
    this._resizeScale = resizeScale;
    _recomputeMetrics();
    _buildChart();

    HTML.window.onResize.listen((event)=>resize());

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
  num _maxX = 100.0; num get maxX=>_maxX;
  num _maxY = 100.0; num get maxY=>_maxY;
  set maxX(num newMax)
  {
    _maxX = newMax;
    resize();
  }
  set maxY(num newMax)
  {
    _maxY = newMax;
    resize();
  }


  void _buildAxesAndScale(Selection axisGroup)
  {
    //create the scales so we can easily translate coordinates to pixels
    xScale = new LinearScale()
      ..domain = [0,_maxX]
      ..range = [padding,width-padding];


    yScale = new LinearScale()
      ..domain = [0,_maxY]
      ..range = [height-padding,padding];


    xAxis = new SvgAxis(orientation: CHARTED.ORIENTATION_BOTTOM,
                        scale: xScale);

    xAxisContainer = axisGroup.append("g")
      ..attr('transform', "translate(0,${height - padding})")
      ..attr("class","axis");
    xAxis.draw(xAxisContainer);

    //add label
    axisGroup.append("text")
      ..attr("class","axislabel")
      ..attr("text-anchor","end")
      ..attr("x",width-40)
      ..attr("y",height-35)
      ..text("Quantity");

    yAxis = new SvgAxis(orientation:CHARTED.ORIENTATION_LEFT,scale:yScale);

    yAxisContainer = axisGroup.append("g")
      ..attr('transform', "translate(${padding},0)")
      ..attr("class","axis");
    yAxis.draw(yAxisContainer);


    //add label
    axisGroup.append("text")
      ..attr("class","axislabel")
      ..attr("text-anchor","end")
      ..attr("dy",".75em")
      ..attr("y",35)
      ..attr("transform","rotate(-90)")
      ..text("Price");

  }

  /***
   *     ____   __    ___  __ _  ___  ____   __   _  _  __ _  ____
   *    (  _ \ / _\  / __)(  / )/ __)(  _ \ /  \ / )( \(  ( \(    \
   *     ) _ (/    \( (__  )  (( (_ \ )   /(  O )) \/ (/    / ) D (
   *    (____/\_/\_/ \___)(__\_)\___/(__\_) \__/ \____/\_)__)(____/
   */

  Selection clipPath;
  Selection areaMask;
  CHARTED.SvgLine liner;

  static const CLIP_PATH_ID = "clippath";


  RepositoryGetter<E> repositoryGetter = null;
  CurveRepository curveRepository;
  Map<String, PathElement> drawnCurves = new HashMap();
  GElement curves;

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

    //highlight
    areaMask.on("mouseover",(d,i,e)=> areaMask.attr(
        "opacity","0.2"));
    areaMask.on("mouseout",(d,i,e)=> areaMask.attr(
        "opacity","0.1"));

  }


  /**
   * create a new path but doesn't set its d, that's the update job
   */
  PathElement _createPathElement(String name)
  {
    PathElement line = new PathElement();
    curves.append(line);
    line.classes = ["selectable", "line"];
    line.setAttribute("stroke", BeveridgePlot.COLORS[drawnCurves.length]);
    line.setAttribute("stroke-width", "3");
    line.setAttribute("fill", "none");
    //give it a toolTip
    Tooltip tooltip = new Tooltip(line,name);
    return line;
  }

  /**
   * build things like fixed demand and supply curves
   */
  _updateCurves() {



    for (CurvePath curve in curveRepository.curves) {
      String name = curveRepository.getName(curve);
      PathElement path = drawnCurves.putIfAbsent(name, () => _createPathElement
      (name));


      path.setAttribute("d", generatePathFromXYObs(curve.toPath(0.0,
                                                                _maxY, 0.0,
                                                                _maxX)
                                                   , xScale, yScale));

    }
  }

  void _buildBackgroundCurves(SvgElement svg)
  {
    //put all this in a group
    curves = svg.append(new GElement());
    //keep them inside the plot area
    curves.setAttribute("pointer-events","all");
    curves.setAttribute("clip-path","url(#clippath)");

    _updateCurves();


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
  LinkedHashMap<BeveridgeDatum,CircleElement> drawnCircles = new LinkedHashMap();
  LinkedHashMap<BeveridgeDatum,Tooltip> dataToolTip = new LinkedHashMap();

  /**
   * deletes the circle associated with this datum
   */
  void _deleteOldestDatum()
  {

    //should be coordinated
    //  assert(identical(dataToolTip.keys.first,drawnCircles.keys.first));
    BeveridgeDatum toDelete = dataToolTip.keys.first;

    dataToolTip.remove(toDelete).killTooltip();
    drawnCircles.remove(toDelete).remove();
  }

  /**
   * creates a new circle for this new datum. Doesn't set it up properly
   * though, that happens at _updateCircles() anyway.
   */
  void _addDatum(BeveridgeDatum toAdd)
  {

    //create circle
    CircleElement circle = new CircleElement();
    drawnCircles[toAdd]=circle;
    //add it to the group
    circles.append(circle);
    circle.classes.addAll(["selectable", "datapoints"]);


    //create appropriate tooltip
    //create tooltip
    Tooltip t = new Tooltip(circle,toAdd.message);
    dataToolTip[toAdd]=t;

  }


  void _updateCircles()
  {


    //now draw them again!
    int i=0;
    drawnCircles.forEach(( event,circle){

      //set it up
      circle.setAttribute("cx",(xScale.scale(event.x)).toString());
      circle.setAttribute("cy",yScale.scale(event.y).toString());
      circle.setAttribute("r",event.r.toString());
      //linked hash set should be able to deal with this!
      circle.setAttribute("opacity",MATH.pow((i+1)/(drawnCircles.length+1), 2)
      .toString());

      i++;
    });

  }

  GElement circles;

  GElement _initializeCircles(SvgElement svg)
  {

    //we need to put the circles in a group, so we can attach clip-path to it
    circles =     svg.append(new GElement());

    circles.setAttribute("pointer-events","all");

    circles.setAttribute("id","beveridge_data");
    circles.setAttribute("clip-path","url(#clippath)");


    //initialize dataset
    //reset local data by filling it with garbage
    for(int i=0;i<dataSize; i++)
      _addDatum(new BeveridgeDatum(-10.0,-10.0,0,""));




    List<BeveridgeDatum> initialData = dataInitializer(_presentation);

    //add real data if it exists
    for(BeveridgeDatum datum in initialData)
    {
      _deleteOldestDatum();
      _addDatum(datum);
    }



    //place them
    _updateCircles();



    return circles;
  }

  //flag, starts false and becomes true when the chart is built
  bool ready = false;


  SvgElement svgNode;
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
    assert (_chartLocation!=null);
    assert (_presentation!=null);



    svgNode = _chartLocation.append(new SvgElement.tag("svg"));
    svgNode.setAttribute("width",width.toString());
    svgNode.setAttribute("height",height.toString());

    //need a selection for charted
    Selection svg = new SelectionScope.element(svgNode).append("g");

    //build the axis
    _buildAxesAndScale(svg);
    //background
    _buildChartBackground(svg);


    curveRepository = repositoryGetter == null ? null :
                      repositoryGetter(_presentation);
    if(curveRepository != null)
      _buildBackgroundCurves(svgNode);


    //circles
    _initializeCircles(svgNode);
    //set yourself up to listen to the stream of data
    _listenToPresentation();



    //tell the containing div how tall you are
    _chartLocation.style.height=(height+2* padding).toString();
    ready=true;


  }


  /**
   * this turns true the first time we call _listenToPresentation so that we
   * only listen to it once
   */
  bool listeningToStream = false;

  void _listenToPresentation(){

    if(listeningToStream) //we are already doing this!
      return;

    _presentation.stream.listen((event){

      BeveridgeDatum newObservation = dailyDataExtractor(event);
      if(newObservation != null) {
        //delete oldest, add new
        _deleteOldestDatum();
        _addDatum(newObservation);
      }
      //update data
      _updateCircles();
      if(curveRepository == null)
      {
        curveRepository = repositoryGetter(_presentation);
        _buildBackgroundCurves(svgNode);
      }
      _updateCurves();
    });

    listeningToStream = true;

  }







  resize()
  {
    //you need to redraw everything!
    _recomputeMetrics();

    //remove previous svg
    _chartLocation.lastChild.remove();
    //redraw it!
    _reset();
    _buildChart();
  }

  _recomputeMetrics() {
    width = _chartLocation.borderEdge.width;
    width = (width*_resizeScale).round();
    height = (width * aspectRatio).round();
    xTicks = MATH.max(width/50, 2).round();
    yTicks = MATH.max(width/50, 2).round();
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
    drawnCurves.clear();

  }


}

/**
 * the data type we store to turn into drawing
 */
class BeveridgeDatum
{

  final num x;

  final num y;

  final int r;

  /**
   * tooltip
   */
  final String message;

  BeveridgeDatum(this.x, this.y, this.r,this.message);


}



/**
 * similar to generatePathString in the time series object, but dealing with
 * x-y rather than x-i observations
 */
String generatePathFromXYObs(List<List<double>> obs, Scale xScale,
                             Scale yScale) {
  List<String> segments = [];
  List<MATH.Point> points = [];


  for (int i = 0; i < obs.length; i++) {
//if valid
    var observation = obs[i];
    if (observation.every((e)=>e.isFinite)) {
      points.add(new MATH.Point(xScale.scale(observation[0]), yScale.scale
      (observation[1])));
//an invalid observation is a break, draw what you got
    }
    else if (points.isNotEmpty) {
      segments.add("M ${points.map((pt) => '${pt.x},${pt.y} ').join('L')}");
    }
  }
//one last segment, if needed
  if (points.isNotEmpty) {
    segments.add("M ${points.map((pt) => '${pt.x},${pt.y} ').join('L')}");
  }

  return segments.join();


}

