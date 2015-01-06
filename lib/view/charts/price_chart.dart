/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

/*
 * Copyright (c) 2014 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */
part of lancaster.view;


/**
 * supposedly a time series chart with some degree of customizability
 */
@Component(
    selector: 'priceplot',
    templateUrl: 'packages/lancaster/view/charts/plot.html',
    cssUrl: 'packages/lancaster/view/charts/plot.css'
    )
class TimeSeriesChart implements ShadowRootAware {


  /***
   *     _  _   __    ___  __  ___    __ _  _  _  _  _  ____  ____  ____  ____
   *    ( \/ ) / _\  / __)(  )/ __)  (  ( \/ )( \( \/ )(  _ \(  __)(  _ \/ ___)
   *    / \/ \/    \( (_ \ )(( (__   /    /) \/ (/ \/ \ ) _ ( ) _)  )   /\___ \
   *    \_)(_/\_/\_/ \___/(__)\___)  \_)__)\____/\_)(_/(____/(____)(__\_)(____/
   */


  static const dataSize = 5;
  static const double aspectRatio=6.0/8.0;
  static const int padding = 30;
  static const int xTicks = 10;
  static const int yTicks = 5;
  int width;
  int height;

  /**
   * the presentation object which is our interface to the model itself
   */
  SimpleMarketPresentation _presentation;



  /**
   * The HTML node that contains all this. Set when shadow dom attaches
   */
  HTML.Element chartLocation;


  /**
   * the svg node that contains everything
   */
  HTML.Element svgNode;

  /**
   * the presentation object
   */
  @NgOneWay('presentation')
  set presentation(SimpleMarketPresentation presentation) {
    _presentation = presentation;
    _buildChart();
  }


  /***
   *      __   _  _  __  ____
   *     / _\ ( \/ )(  )/ ___)
   *    /    \ )  (  )( \___ \
   *    \_/\_/(_/\_)(__)(____/
   */

  int minimumDays = 100;

  /**
   * whenever there are more days observed then [minimumDays], then increase
   * [minimumDays] by this much.
   */
  static final DAY_SCALE_INCREASE = 100;

  LinearScale xScale;
  LinearScale yScale;
  SvgAxis xAxis;
  SvgAxis yAxis;
  Selection yAxisContainer;
  Selection xAxisContainer;
  Selection axisGroup;

  drawXAxis() {
    xAxisContainer = axisGroup.append("g")
      ..attr("id", "xaxis")
      ..attr('transform', "translate(0,${height - padding})")
      ..attr("class", "axis");
    xAxis.axis(xAxisContainer);
  }

  drawYAxis() {
    yAxisContainer = axisGroup.append("g")
      ..attr("id", "yaxis")
      ..attr('transform', "translate(${padding},0)")
      ..attr("class", "axis");
    yAxis.axis(yAxisContainer);
  }

  void _buildAxesAndScale(Selection axisGroup) {
    this.axisGroup=axisGroup;
    //create the scales so we can easily translate coordinates to pixels
    xScale = new LinearScale()
      ..domain = [0, DAY_SCALE_INCREASE]
      ..range = [padding, width - padding];


    yScale = new LinearScale()
      ..domain = [0, 100]
      ..range = [height - padding, padding];


    xAxis = new SvgAxis()
      ..orientation = ORIENTATION_BOTTOM
      ..scale = xScale
      ..suggestedTickCount = xTicks;

    drawXAxis();

    yAxis = new SvgAxis()
      ..orientation = ORIENTATION_LEFT
      ..scale = yScale
      ..suggestedTickCount = yTicks;

    drawYAxis();
  }

  updateScales(int day, double maxY)
  {
    if(maxY>=yScale.domain[1])
    {
      yScale.domain[1] = maxY;
      yAxisContainer.remove();
      drawYAxis();
    }

    if(xScale.domain[1]<=day) {
      xScale.domain[1] += DAY_SCALE_INCREASE;
      xAxisContainer.remove();
      drawXAxis();
    }

  }


  /***
   *     ____   __  ____  _  _  ____
   *    (  _ \ / _\(_  _)/ )( \/ ___)
   *     ) __//    \ )(  ) __ (\___ \
   *    (__)  \_/\_/(__) \_)(_/(____/
   */


  /**
   * utility class to draw svg lines
   */
  SvgLine line ;

  /**
   * for each curve, the html element containing the path
   */
  final Map<String, PathElement> lines = new Map();


  /**
   * utility method creates an svg path node and adds a tooltip to it
   */
  PathElement createPathNode(String name) {
    print("creating a line");
    PathElement line = new PathElement();
    svgNode.append(line);
    line.classes = ["selectable", "line"];
    line.setAttribute("stroke", BeveridgePlot.COLORS[lines.length]);
    line.setAttribute("stroke-width", "3");
    line.setAttribute("fill", "none");
    //give it a toolTip
    Tooltip tooltip = new Tooltip(line);
    tooltip.message = name;
    return line;
  }

  void updatePaths() {

    for (String data in observations.keys) {
      //put the path in if it doesn't exist
      PathElement path = lines.putIfAbsent(data, () => createPathNode(data));
      //draw it
      path.setAttribute("d", generatePathString(observations[data], xScale,
                                                yScale));
    }
    print("$lines");


  }

  Map<String, List<double>> get observations => _presentation.dailyObservations;

  /**
   * an adaptation of the SVGLine (charted library) path generator to work
   * without the trappings of the original
   */
  static String generatePathString(List<double> obs, Scale xScale,
                                   Scale yScale) {
    List<String> segments = [];
    List<MATH.Point> points = [];


    for (int i = 0; i < obs.length; i++) {
      //if valid
      var observation = obs[i];
      if (observation >= 0 && observation.isFinite) {
        points.add(new MATH.Point(xScale.apply(i), yScale.apply(observation)));
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


  void _buildChart() {

    /**
     * if either is null, wait for the other!
     */
    if(chartLocation == null || _presentation == null)
      return;

    //create svg node
    svgNode = new SvgElement.tag("svg");
    svgNode.setAttribute("width",width.toString());
    svgNode.setAttribute("height",height.toString());
    //add node to location
    chartLocation.append(svgNode);

    //now create an svg group for axes
    _buildAxesAndScale(new SelectionScope.element(svgNode).append("g"));

    //now create the paths
    updatePaths();

    _listenToModel();


  }

  bool listening = false;

  void _listenToModel() {
    if(!listening)
      _presentation.marketStream.listen((event) {

        listening = true;
        //we don't care so much about the values of the event, what we care
        // about is that presentation layer has updated its daily observations

        //find the maximum Y today
        double maxY =_presentation.dailyObservations.values.fold(
            0.0,(prev,column)=>MATH.max(prev,column.last));



        //update the plot
        updateScales(event.day, maxY);
        updatePaths();
      });
  }


  /**
   * so actually this gets called even when there is no shadowroot; it's very
   * handy though because when this is called we know the html is ready to be
   * selected
   */
  void onShadowRoot(HTML.ShadowRoot shadowRoot) {
    chartLocation = shadowRoot.querySelector('.price-chart');
    width = chartLocation.borderEdge.width;
    height = (width*aspectRatio).round();
    _buildChart();

    //start listening for resizes
    HTML.window.onResize.listen((event)=>resize());
  }

  void resize()
  {
    print("resize!");
    //you need to redraw everything!
    width = chartLocation.borderEdge.width;
    height = (width*aspectRatio).round();

    chartLocation.firstChild.remove();
    //redraw it!
    _reset();
    _buildChart();

  }



  void _reset()
  {
    xScale=null;
    yScale=null;
    xAxis=null;
    yAxis=null;
    yAxisContainer=null;
    xAxisContainer=null;
    axisGroup=null;
    line=null;
    lines.clear();
    svgNode = null;
  }


}



