/*
 * Copyright (c) 2015 to Ernesto Carrella.
 * This is open source on MIT license. Isn't this jolly?
 */

part of  lancaster.view2;



/**
 * supposedly a time series chart with some degree of customizability
 */
abstract class BaseTimeSeriesChart<E extends PresentationEvent>{


  /***
   *     _  _   __    ___  __  ___    __ _  _  _  _  _  ____  ____  ____  ____
   *    ( \/ ) / _\  / __)(  )/ __)  (  ( \/ )( \( \/ )(  _ \(  __)(  _ \/ ___)
   *    / \/ \/    \( (_ \ )(( (__   /    /) \/ (/ \/ \ ) _ ( ) _)  )   /\___ \
   *    \_)(_/\_/\_/ \___/(__)\___)  \_)__)\____/\_)(_/(____/(____)(__\_)(____/
   */


  static const dataSize = 5;
  static const num aspectRatio=9.0/16.0;
  static const int padding = 30;
  static int xTicks = 10;
  static int yTicks = 5;
  int width;
  int height;
  double _resizeScale = 1.0;

  /**
   * the presentation object which is our interface to the model itself
   */
  final Presentation<E> _presentation;



  /**
   * The HTML node that contains all this. Set when shadow dom attaches
   */
  final HTML.Element chartLocation;


  /**
   * the svg node that contains everything
   */
  HTML.Element svgNode;






  /***
   *      __   _  _  __  ____
   *     / _\ ( \/ )(  )/ ___)
   *    /    \ )  (  )( \___ \
   *    \_/\_/(_/\_)(__)(____/
   */

  BaseTimeSeriesChart(this._presentation, this.chartLocation,{double resizeScale : 1.0}) {
    _resizeScale = resizeScale;
    recomputeMetrics();
    _buildChart();

    //start listening for resizes
    HTML.window.onResize.listen((event)=>resize());

  }

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
    xAxis.draw(xAxisContainer);

    //add label
    axisGroup.append("text")
    ..attr("class","axislabel")
    ..attr("text-anchor","end")
    ..attr("x",width-40)
    ..attr("y",height-35)
    ..text("Time");
  }

  drawYAxis() {
    yAxisContainer = axisGroup.append("g")
      ..attr("id", "yaxis")
      ..attr('transform', "translate(${padding},0)")
      ..attr("class", "axis");
    yAxis.draw(yAxisContainer);

    axisGroup.append("text")
      ..attr("class","axislabel")
      ..attr("text-anchor","end")
      ..attr("dy",".75em")
      ..attr("y",35)
      ..attr("transform","rotate(-90)")
      ..text("Value");
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


    xAxis = new SvgAxis(ORIENTATION_BOTTOM)
      ..scale = xScale;

    drawXAxis();

    yAxis = new SvgAxis(ORIENTATION_LEFT)
      ..scale = yScale;
    drawYAxis();
  }

  updateScales(int day, num maxY)
  {
    if(maxY>=yScale.domain.last)
    {
      yScale.domain = [0,maxY];
      yAxisContainer.remove();
      drawYAxis();
    }

    if(xScale.domain.last<=day) {
      xScale.domain = [0,day+DAY_SCALE_INCREASE];
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
    PathElement line = new PathElement();
    svgNode.append(line);
    line.classes = ["selectable", "line"];
    line.setAttribute("stroke", BeveridgePlot.COLORS[lines.length]);
    line.setAttribute("stroke-width", "3");
    line.setAttribute("fill", "none");
    //give it a toolTip
    Tooltip tooltip = new Tooltip(line,name);
    return line;
  }

  void updatePaths() {

    Iterable<String> columns = selectedColumns;
    if(columns == null) //if null given, select them all
      columns =  observations.keys;



    for (String column in columns) {
      //put the path in if it doesn't exist
      PathElement path = lines.putIfAbsent(column, () => createPathNode(column));
      //draw it
      path.setAttribute( "d", generatePathString(observations[column], xScale,
                                                 yScale));
    }


  }

  /**
   * just a redirect
   */
  Map<String, List<double>> get observations => _presentation.dailyObservations;

  /**
   * an adaptation of the SVGLine (charted library) path generator to work
   * without the trappings of the original
   */
  static String generatePathString(List<double> obs, Scale xScale,
                                   Scale yScale) {
    List<String> segments = [];
    List<MATH.Point> points = [];

    if(obs==null)
      return " ";

    for (int i = 0; i < obs.length; i++) {
      //if valid
      var observation = obs[i];
      if (observation >= 0 && observation.isFinite) {
        points.add(new MATH.Point(xScale.scale(i), yScale.scale(observation)));
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


    //tell the containing div how tall you are
    chartLocation.style.height=(height+2* padding).toString();

    _listenToModel();


  }

  bool listening = false;

  void _listenToModel() {
    if(!listening)
      _presentation.stream.listen((event) {

        listening = true;
        //we don't care so much about the values of the event, what we care
        // about is that presentation layer has updated its daily observations
        num maxY = 0.0;
        //find the maximum Y today
        if(selectedColumns == null)
          maxY =_presentation.dailyObservations.values.fold(
              0.0,(prev,column)=>MATH.max(prev,column.last));
        else
          _presentation.dailyObservations.forEach((name,column)
                                                  {
                                                    if(selectedColumns
                                                    .contains(name))
                                                      maxY = MATH.max(maxY,
                                                                      column.last);
                                                  });

        //update the plot
        updateScales(event.day, maxY);
        updatePaths();
      });
  }




  recomputeMetrics() {
    width = chartLocation.borderEdge.width;
    width = (width*_resizeScale).round();
    height = (width * aspectRatio).round();
    xTicks = MATH.max(width/50, 2).round();
    yTicks = MATH.max(width/50, 2).round();
  }


  void resize()
  {
    //you need to redraw everything!
    recomputeMetrics();

    chartLocation.lastChild.remove();
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


  /**
   * a list of columns to read from the dailyObservations. If null then all
   * columns are selected
   */
  List<String> get selectedColumns;

}