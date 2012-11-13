function OHLC(params) {

    OHLC.prototype._init = function (params) {
        this.height = params.height || 650;
        this.width = params.width || 1300;
        this.margin = params.margin || 50;
        this.data = params.data;
        this.eps_data = params.eps_data;
        this.movingAverageTypes = ['mov_avg_10d', 'mov_avg_50d', 'mov_avg_200d'];

        this.dateFormat = d3.time.format("%Y-%m-%d");
        var attributes = ['open', 'high', 'low', 'close', 'mov_avg_10d', 'mov_avg_50d', 'mov_avg_200d', 'traded_quantity']
        this.data.forEach(function (d) {
            d.date = new Date(d.date);
            attributes.forEach(function (attr) {
                d[attr] = parseFloat(d[attr]);
            });
        });
        var firstDate = this.data[0].date;
        var lastDate = this.data[this.data.length - 1].date;

        this.stDate = new Date(firstDate).setDate(firstDate.getDate() - 3);
        this.enDate = new Date(lastDate).setDate(lastDate.getDate() + 3);

        this.eps_data.forEach(function (d) {
            d.quarter_start = new Date(d.quarter_start);
            d.quarter_end = new Date(d.quarter_end);
            d.eps = parseFloat(d.eps);
            if (d.quarter_start < firstDate) {
                d.quarter_start = firstDate;
            }
        });
        var chartId = params.chartId || '#chart';
        this._svg = d3.select(chartId).append("svg").attr("height", this.height).attr("width", this.width);
    };

    OHLC.prototype._createScale = function () {
        this._ymin = d3.min(this.data, function (d) {
            return d.low;
        });
        this._ymax = d3.max(this.data, function (d) {
            return d.high;
        });
        this._xscale = d3.time.scale().domain([this.stDate, this.enDate]).range([1, this.width - this.margin]);
        this._xscale.clamp();
        this._yscale = d3.scale.linear().domain([this._ymin, this._ymax]).range([this.height - this.margin, 0]);
    };

    OHLC.prototype._createAxis = function () {
        this._xaxis = d3.svg.axis().scale(this._xscale).orient("bottom").tickFormat(this.dateFormat);
        this._xaxis.tickSize(-this.width + 1);
        this._svg.append("g").attr("transform", "translate(" + (this.margin - 1) + "," + (this.height - this.margin) + ")")
            .attr("class", "axis").call(this._xaxis);

        this._yaxis = d3.svg.axis().scale(this._yscale).orient("left").tickSize(-this._xscale.range()[1] + 1);
        this._svg.append("g").attr("transform", "translate(" + this.margin + ", 0)").attr("class", "axis").call(this._yaxis);
    };

    OHLC.prototype._drawMovingAverage = function (g, mov_avg) {
        var _xscale = this._xscale;
        var _yscale = this._yscale;
        var line = d3.svg.line()
            .x(function (d) {
                return _xscale(d.date);
            })
            .y(function (d) {
                return _yscale(d[mov_avg]);
            });
        g.append("svg:path").attr("d", line(this.data)).attr("class", mov_avg);
    };

    OHLC.prototype._addEPS = function(g, chart) {
        this._epsMin = d3.min(this.eps_data, function (d) {
            return d.eps;
        });
        this._epsMax = d3.max(this.eps_data, function (d) {
            return d.eps;
        });
        this._epsScale = d3.scale.linear().domain([this._epsMin, this._epsMax]).range([this.margin, (this.height - this.margin)*0.9]);

        g.selectAll(".eps").data(this.eps_data).enter().append("rect")
            .attr("x",function (d) {
                return chart._xscale(d.quarter_start);
            }).attr("y",function (d) {
                return chart.height - chart.margin - chart._epsScale(d.eps);
            }).attr("width", function(d) {
                return chart._xscale(d.quarter_end) - chart._xscale(d.quarter_start);
            }).attr("height", function (d) {
                return (chart._epsScale(d.eps));
            })
            .attr("class", "eps");
    };

    OHLC.prototype._addVolumeBar = function (g, chart) {
        this._volumeMin = d3.min(this.data, function (d) {
            return d.traded_quantity;
        });
        this._volumeMax = d3.max(this.data, function (d) {
            return d.traded_quantity;
        });
        this._volumeScale = d3.scale.linear().domain([this._volumeMin, this._volumeMax]).range([this.margin, (this.height - this.margin) / 4]);

        g.selectAll(".volume").data(this.data).enter().append("rect")
            .attr("x",function (d) {
                return chart._xscale(d.date);
            }).attr("y",function (d) {
                return chart.height - chart.margin - chart._volumeScale(d.traded_quantity);
            }).attr("width", 2).attr("height", function (d) {
                return (chart._volumeScale(d.traded_quantity));
            })
            .attr("class", "volume");
    };

    OHLC.prototype._addMovingAverageLines = function (g) {
        var chart = this;
        this.movingAverageTypes.forEach(function (movingAverageType) {
            chart._drawMovingAverage(g, movingAverageType);
        });
    };

    OHLC.prototype._drawLine = function (g, x1, x2, y1, y2, className) {
        return this._moveLine(g.append("line").attr("class", className), x1, x2, y1, y2);
    };

    OHLC.prototype._moveLine = function (line, x1, x2, y1, y2) {
        return line.attr("x1", x1).attr("x2", x2).attr("y1", y1).attr("y2", y2);
    };

    OHLC.prototype._addOHLC = function (g) {
        var previousClose = 0;
        var chart = this;
        this.data.forEach(function (d) {
            var color = d.close > previousClose ? "green" : "red", x = chart._xscale(d.date);
            chart._drawLine(g, x - 3, x, chart._yscale(d.open), chart._yscale(d.open), color);
            chart._drawLine(g, x, x, chart._yscale(d.high), chart._yscale(d.low), color);
            chart._drawLine(g, x, x + 3, chart._yscale(d.close), chart._yscale(d.close), color);
            previousClose = d.close;
        });
    };

    OHLC.prototype._drawCursorMarker = function (g, xy, text) {
        var x = this.dateFormat(this._xscale.invert(xy[0])), y = this._yscale.invert(xy[1]);
        if (this.xCursor === undefined) {
            this.xCursor = this._drawLine(g, -1, -1, -1, -1, "cursor_axis");
            this.yCursor = this._drawLine(g, -1, -1, -1, -1, "cursor_axis");
        }
        if ((xy[0] - this.margin) > 0 && (this.height - xy[1] - this.margin) > 0) {
            this._moveLine(this.xCursor, xy[0] - this.margin, xy[0] - this.margin, this._yscale(this._ymin), this._yscale(this._ymax));
            this._moveLine(this.yCursor, this._xscale(this.stDate), this._xscale(this.enDate), xy[1], xy[1]);
        }
        text.text(x + " " + y.toFixed(2));
    };

    OHLC.prototype._addCursor = function (chart, g, text) {
        this._svg.on("mousemove", function () {
            chart._drawCursorMarker(g, d3.mouse(this), text);
        });
        this._svg.on("mouseout", function () {
            g.selectAll('.cursor_axis').attr("x1", -1).attr("x2", -1).attr("y1", -1).attr("y2", -1);
            text.text("");
        });
        g.on("mousemove", function () {
            chart._drawCursorMarker(g, d3.mouse(this), text);
        });
    };

    OHLC.prototype._drawChart = function () {
        this._createScale();
        this._createAxis();
        var g = this._svg.append("g");
        var text = g.append("text").attr("x", this._xscale(this.enDate) - 150).attr("y", this._yscale(this._ymax) + 15);
        this._addEPS(g, this);
        this._addVolumeBar(g, this);
        this._addMovingAverageLines(g);
        this._addOHLC(g);
        g.attr("transform", "translate(" + this.margin + ", 0)");
        this._addCursor(this, g, text);
    };

    this._init(params);
    this._drawChart();
}




