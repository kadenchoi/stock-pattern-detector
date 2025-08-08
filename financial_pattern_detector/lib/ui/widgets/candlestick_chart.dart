import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../models/stock_data.dart';
import '../../models/pattern_detection.dart';
import '../../services/pattern_prediction_service.dart';
import '../screens/pattern_details_screen.dart';

class CandlestickChart extends StatefulWidget {
  final StockDataSeries series;
  final List<PatternMatch> patterns;

  const CandlestickChart(
      {super.key, required this.series, required this.patterns});

  @override
  State<CandlestickChart> createState() => _CandlestickChartState();
}

class _CandlestickChartState extends State<CandlestickChart> {
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _start = widget.series.data.first.timestamp;
    _end = widget.series.data.last.timestamp;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.series.data
        .where((d) => d.timestamp.isAfter(_start) && d.timestamp.isBefore(_end))
        .toList();

    // Enrich patterns with predictions for overlay annotations
    final enriched = widget.patterns
        .where((p) => p.symbol == widget.series.symbol)
        .map((p) =>
            PatternPredictionService.instance.enrich(p, widget.series.data))
        .toList();

    // Build overlay series for patterns within window
    final overlaySeries = <CartesianSeries<StockData, DateTime>>[];
    for (final p in enriched) {
      if (p.startTime.isAfter(_end) || p.endTime.isBefore(_start)) continue;
      final startIdx = _closestIndex(widget.series.data, p.startTime);
      final endIdx = _closestIndex(widget.series.data, p.endTime);
      if (startIdx == null || endIdx == null) continue;
      final c1 = widget.series.data[startIdx].close;
      final c2 = widget.series.data[endIdx].close;
      final color = _patternColor(p);
      overlaySeries.add(LineSeries<StockData, DateTime>(
        dataSource: [
          StockData(
            symbol: widget.series.symbol,
            timestamp: widget.series.data[startIdx].timestamp,
            open: c1,
            high: c1,
            low: c1,
            close: c1,
            volume: 0,
          ),
          StockData(
            symbol: widget.series.symbol,
            timestamp: widget.series.data[endIdx].timestamp,
            open: c2,
            high: c2,
            low: c2,
            close: c2,
            volume: 0,
          ),
        ],
        xValueMapper: (s, _) => s.timestamp,
        yValueMapper: (s, _) => s.close,
        color: color,
        width: 2,
      ));
    }

    return Column(
      children: [
        Expanded(
          child: SfCartesianChart(
            enableAxisAnimation: true,
            zoomPanBehavior: ZoomPanBehavior(
              enablePanning: true,
              enablePinching: true,
              zoomMode: ZoomMode.xy,
            ),
            primaryXAxis: DateTimeAxis(
              intervalType: DateTimeIntervalType.days,
              edgeLabelPlacement: EdgeLabelPlacement.shift,
              plotBands: [
                for (final p in enriched)
                  if (!(p.startTime.isAfter(_end) ||
                      p.endTime.isBefore(_start)))
                    PlotBand(
                      isVisible: true,
                      start: p.startTime,
                      end: p.endTime,
                      color: _patternColor(p).withValues(alpha: 0.06),
                    ),
              ],
            ),
            primaryYAxis: const NumericAxis(opposedPosition: true),
            series: <CartesianSeries<StockData, DateTime>>[
              CandleSeries<StockData, DateTime>(
                dataSource: data,
                xValueMapper: (s, _) => s.timestamp,
                lowValueMapper: (s, _) => s.low,
                highValueMapper: (s, _) => s.high,
                openValueMapper: (s, _) => s.open,
                closeValueMapper: (s, _) => s.close,
              ),
              ...overlaySeries,
            ],
            annotations: [
              // Draw predicted target/stop as horizontal lines where relevant
              for (final p in enriched) ..._buildPatternAnnotations(p),
            ],
          ),
        ),
        _buildTimeSlider(widget.series.data.first.timestamp,
            widget.series.data.last.timestamp),
      ],
    );
  }

  int? _closestIndex(List<StockData> data, DateTime t) {
    if (data.isEmpty) return null;
    int lo = 0, hi = data.length - 1, best = 0;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final cmp = data[mid].timestamp.compareTo(t);
      if (cmp == 0) return mid;
      if (cmp < 0) {
        best = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return best;
  }

  Color _patternColor(PatternMatch p) {
    switch (p.direction) {
      case PatternDirection.bullish:
        return Colors.green;
      case PatternDirection.bearish:
        return Colors.red;
      case PatternDirection.breakout:
        return Colors.orange;
    }
  }

  List<CartesianChartAnnotation> _buildPatternAnnotations(
      PatternMatch pattern) {
    final target = pattern.metadata['targetPrice'] as num?;
    final stop = pattern.metadata['stopPrice'] as num?;
    final labelColor = pattern.direction == PatternDirection.bullish
        ? Colors.green
        : (pattern.direction == PatternDirection.bearish
            ? Colors.red
            : Colors.orange);

    final annotations = <CartesianChartAnnotation>[];
    if (target != null) {
      annotations.add(CartesianChartAnnotation(
        widget: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PatternDetailsScreen(pattern: pattern),
              ),
            );
          },
          child: Transform.translate(
            offset: const Offset(8, -8),
            child:
                _priceLabel('TARGET ${target.toStringAsFixed(2)}', labelColor),
          ),
        ),
        coordinateUnit: CoordinateUnit.point,
        x: pattern.endTime,
        y: target.toDouble(),
      ));
    }
    if (stop != null) {
      annotations.add(CartesianChartAnnotation(
        widget: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PatternDetailsScreen(pattern: pattern),
              ),
            );
          },
          child: Transform.translate(
            offset: const Offset(8, 8),
            child: _priceLabel('STOP ${stop.toStringAsFixed(2)}', Colors.grey),
          ),
        ),
        coordinateUnit: CoordinateUnit.point,
        x: pattern.endTime,
        y: stop.toDouble(),
      ));
    }
    return annotations;
  }

  Widget _priceLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11)),
    );
  }

  Widget _buildTimeSlider(DateTime min, DateTime max) {
    final minMs = min.millisecondsSinceEpoch.toDouble();
    final maxMs = max.millisecondsSinceEpoch.toDouble();
    final startMs = _start.millisecondsSinceEpoch.toDouble();
    final endMs = _end.millisecondsSinceEpoch.toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: RangeSlider(
        min: minMs,
        max: maxMs,
        divisions: 100,
        labels: RangeLabels(
          DateTime.fromMillisecondsSinceEpoch(startMs.toInt())
              .toIso8601String()
              .substring(0, 10),
          DateTime.fromMillisecondsSinceEpoch(endMs.toInt())
              .toIso8601String()
              .substring(0, 10),
        ),
        values: RangeValues(startMs, endMs),
        onChanged: (v) {
          setState(() {
            _start = DateTime.fromMillisecondsSinceEpoch(v.start.toInt());
            _end = DateTime.fromMillisecondsSinceEpoch(v.end.toInt());
          });
        },
      ),
    );
  }
}
