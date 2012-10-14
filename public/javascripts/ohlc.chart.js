var ohlc = {
  _init: function (params) {
      this.height = params['height'] || 650;
      this.width = params['height'] || 1300;
      this.margin = params['height'] || 50;
      this.data = params['data'];
      this.dateFormat = d3.time.format("%Y-%m-%d");

      this.data.forEach(function (d) {
          d['date'] = new Date(d['date']);
      });
      var firstDate = this.data[0]['date'];
      var lastDate = this.data[this.data.length - 1]['date'];

      this.stDate = new Date(firstDate).setDate(firstDate.getDate() - 3);
      this.enDate = new Date(lastDate).setDate(lastDate.getDate() + 3);

      var chartId = params['chartId'] || '#mychart';
      this._svg = d3.select(chartId).append("svg").attr("height", this.height).attr("width", this.width);
  },

  _createScale: function() {
      this._ymin = d3.min(this.data, function (d) { return d['low'] });
      this._ymax = d3.max(this.data, function (d) { return d['high'] });
      this._xscale = d3.time.scale().domain([this.stDate, this.enDate]).range([1, this.width - this.margin]);
      this._yscale = d3.scale.linear().domain([this._ymin, this._ymax]).range([this.height - this.margin, 0]);
  },

  _createAxis: function() {
      this._xaxis = d3.svg.axis().scale(this._xscale).orient("bottom").tickFormat(this.dateFormat);
      this._xaxis.tickSize(-this.width + 1);
      this._svg.append("g").attr("transform", "translate(" + (this.margin - 1) + "," + (this.height - this.margin) + ")")
          .attr("class", "axis").call(this._xaxis);

      this._yaxis = d3.svg.axis().scale(this._yscale).orient("left").tickSize(-this._xscale.range()[1] + 1);
      this._svg.append("g").attr("transform", "translate(" + this.margin + ", 0)").attr("class", "axis").call(this._yaxis);
  },

  _drawMovingAverage:  function (g, mov_avg) {
      var _xscale = this._xscale;
      var _yscale = this._yscale;
    var line = d3.svg.line()
        .x(function (d) {
            return _xscale(d['date']);
        })
        .y(function (d) {
            return _yscale(d[mov_avg]);
        });
    g.append("svg:path").attr("d", line(this.data)).attr("class", mov_avg);
    },

  _addVolumeBar: function(g) {
      this._volumeMin = d3.min(this.data, function (d) {return d['traded_quantity']});
      this._volumeMax = d3.max(this.data, function (d) {return d['traded_quantity']});
      this._volumeScale = d3.scale.linear().domain([this._volumeMin, this._volumeMax]).range([this.margin, (this.height - this.margin) / 4]);

      g.selectAll("rect").data(this.data).enter().append("rect")
          .attr("x",function (d) {
              return ohlc._xscale(d['date'])
          }).attr("y",function (d) {
              return ohlc.height - ohlc.margin - ohlc._volumeScale(d['traded_quantity']);
          }).attr("width", 2).attr("height", function (d) {
              return (ohlc._volumeScale(d['traded_quantity']));
          })
          .attr("class", "volume");
  },
  _addMovingAverageLines: function(g) {
      this._drawMovingAverage(g, 'mov_avg_10d');
      this._drawMovingAverage(g, 'mov_avg_50d');
      this._drawMovingAverage(g, 'mov_avg_200d');
  },

  _drawLine: function(g, x1, x2, y1, y2, className) {
      return g.append("line").attr("class", className).attr("x1", x1).attr("x2", x2).attr("y1", y1).attr("y2", y2);
  },

  _moveLine: function(line, x1, x2, y1, y2) {
      line.attr("x1", x1).attr("x2", x2).attr("y1", y1).attr("y2", y2);
  },

  _addOHLC: function(g) {
      var previousClose = 0;
      this.data.forEach(function (d) {
          var color = d['close'] > previousClose ? "green" : "red";
          var xposition = ohlc._xscale(d['date']);
          ohlc._drawLine(g, xposition - 3, xposition, ohlc._yscale(d['open']), ohlc._yscale(d['open']), color);
          ohlc._drawLine(g, xposition, xposition, ohlc._yscale(d['high']), ohlc._yscale(d['low']), color);
          ohlc._drawLine(g, xposition, xposition + 3, ohlc._yscale(d['close']), ohlc._yscale(d['close']), color);
          previousClose = d['close'];
      });
  },

  _drawCursorMarker:  function (g, xy, text) {
    var x = ohlc.dateFormat(ohlc._xscale.invert(xy[0])), y = ohlc._yscale.invert(xy[1]);
    if (this.xCursor == undefined) {
        this.xCursor = ohlc._drawLine(g, -1, -1, -1, -1, "cursor_axis");
        this.yCursor = ohlc._drawLine(g, -1, -1, -1, -1, "cursor_axis");
    }
    if ((xy[0] - ohlc.margin) > 0 && (ohlc.height - xy[1] - ohlc.margin) > 0) {
        ohlc._moveLine(this.xCursor, xy[0] - ohlc.margin, xy[0] - ohlc.margin, ohlc._yscale(ohlc._ymin), ohlc._yscale(ohlc._ymax));
        ohlc._moveLine(this.yCursor, ohlc._xscale(ohlc.stDate), ohlc._xscale(ohlc.enDate), xy[1], xy[1]);
    }
      text.text(x + " " + new Number(y).toFixed(2));
  },

  _addCursor: function(g, text) {
      var _drawCursorMarker = this._drawCursorMarker;
      this._svg.on("mousemove", function () {
          _drawCursorMarker(g, d3.mouse(this), text);
      });
      this._svg.on("mouseout", function () {
          g.selectAll('.cursor_axis').attr("x1", -1).attr("x2", -1).attr("y1", -1).attr("y2", -1);
          text.text("");
      });
      g.on("mousemove", function () {
          _drawCursorMarker(g, d3.mouse(this), text);
      });
  },

  _drawChart: function() {
      this._createScale();
      this._createAxis();
      var g = this._svg.append("g");
      var text = g.append("text").attr("x", this._xscale(this.enDate) - 150).attr("y", this._yscale(this._ymax) + 15);
      this._addVolumeBar(g);
      this._addMovingAverageLines(g);
      this._addOHLC(g);
      g.attr("transform", "translate(" + this.margin + ", 0)");
      this._addCursor(g, text);
  },

  draw: function(params) {
      this._init(params);
      this._drawChart();
  }
};




