import 'package:flutter/material.dart';

import '../../models/stock_data.dart';
import '../../models/pattern_detection.dart';
import '../../services/ai_trading_strategy_service.dart';
import '../../managers/app_manager.dart';

class WatchlistWidget extends StatefulWidget {
  final Map<String, StockDataSeries?> stockData;
  final VoidCallback onAddSymbol;
  final Function(String) onRemoveSymbol;
  final List<PatternMatch> patterns;
  final AppManager appManager;

  const WatchlistWidget({
    super.key,
    required this.stockData,
    required this.onAddSymbol,
    required this.onRemoveSymbol,
    required this.appManager,
    this.patterns = const [],
  });

  @override
  State<WatchlistWidget> createState() => _WatchlistWidgetState();
}

class _WatchlistWidgetState extends State<WatchlistWidget> {
  final AITradingStrategyService _aiTradingService =
      AITradingStrategyService.instance;
  final Map<String, Map<String, dynamic>?> _aiAnalysisResults = {};
  final Map<String, bool> _aiAnalysisLoading = {};

  @override
  Widget build(BuildContext context) {
    if (widget.stockData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.list_alt, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No symbols in watchlist',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add stock symbols to start monitoring',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onAddSymbol,
              icon: const Icon(Icons.add),
              label: const Text('Add Symbol'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Trigger manual refresh
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.stockData.length,
        itemBuilder: (context, index) {
          final entry = widget.stockData.entries.elementAt(index);
          final symbol = entry.key;
          final data = entry.value;

          return _buildStockCard(symbol, data);
        },
      ),
    );
  }

  Widget _buildStockCard(String symbol, StockDataSeries? data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  symbol,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'remove') {
                      widget.onRemoveSymbol(symbol);
                    } else if (value == 'ai_analysis') {
                      _performAIAnalysis(symbol);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'ai_analysis',
                      child: Row(
                        children: [
                          Icon(Icons.psychology, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('AI Strategy Analysis'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Remove from Watchlist'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (data == null)
              _buildNoDataWidget()
            else
              _buildDataWidget(symbol, data),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return const Row(
      children: [
        Icon(Icons.error_outline, color: Colors.orange, size: 20),
        SizedBox(width: 8),
        Text('No data available', style: TextStyle(color: Colors.orange)),
      ],
    );
  }

  Widget _buildDataWidget(String symbol, StockDataSeries data) {
    if (data.data.isEmpty) {
      return const Row(
        children: [
          Icon(Icons.warning, color: Colors.red, size: 20),
          SizedBox(width: 8),
          Text('Data series is empty', style: TextStyle(color: Colors.red)),
        ],
      );
    }

    final latestData = data.data.last;
    final previousData =
        data.data.length > 1 ? data.data[data.data.length - 2] : null;

    final priceChange =
        previousData != null ? latestData.close - previousData.close : 0.0;
    final percentChange = previousData != null && previousData.close != 0
        ? (priceChange / previousData.close) * 100
        : 0.0;

    final isPositive = priceChange >= 0;
    final changeColor = isPositive ? Colors.green : Colors.red;
    final changeIcon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${latestData.close.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (previousData != null)
                  Row(
                    children: [
                      Icon(changeIcon, color: changeColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? '+' : ''}\$${priceChange.toStringAsFixed(2)} (${percentChange.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          color: changeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Vol: ${_formatVolume(latestData.volume)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'H: \$${latestData.high.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'L: \$${latestData.low.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMiniChart(data.data),

        // AI Analysis Section
        if (_aiAnalysisResults[symbol] != null) ...[
          const SizedBox(height: 12),
          _buildAIAnalysisSection(symbol),
        ],

        // AI Analysis Button
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _aiAnalysisLoading[symbol] == true
                    ? null
                    : () => _performAIAnalysis(symbol),
                icon: _aiAnalysisLoading[symbol] == true
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.psychology, size: 16),
                label: Text(
                  _aiAnalysisLoading[symbol] == true
                      ? 'Analyzing...'
                      : 'AI Strategy Analysis',
                  style: const TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue.shade700,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Data points: ${data.data.length}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'Updated: ${_formatUpdateTime(data.lastUpdated)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniChart(List<StockData> dataPoints) {
    if (dataPoints.length < 2) {
      return Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Text(
            'Insufficient data for chart',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      );
    }

    final maxPrice =
        dataPoints.map((d) => d.high).reduce((a, b) => a > b ? a : b);
    final minPrice =
        dataPoints.map((d) => d.low).reduce((a, b) => a < b ? a : b);
    final priceRange = maxPrice - minPrice;

    if (priceRange == 0) {
      return Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Text(
            'No price movement',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      );
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: CustomPaint(
        painter: MiniChartPainter(dataPoints, minPrice, maxPrice),
        size: const Size(double.infinity, 40),
      ),
    );
  }

  String _formatVolume(int volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    }
    return volume.toString();
  }

  String _formatUpdateTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _performAIAnalysis(String symbol) async {
    if (_aiAnalysisLoading[symbol] == true) return;

    setState(() {
      _aiAnalysisLoading[symbol] = true;
      _aiAnalysisResults[symbol] = null;
    });

    try {
      // Get the stock data for this symbol
      final stockDataSeries = widget.stockData[symbol];
      if (stockDataSeries == null) {
        throw Exception('No stock data available for $symbol');
      }

      // Get patterns for this symbol
      final patterns =
          widget.patterns.where((p) => p.symbol == symbol).toList();

      // Perform AI analysis
      final result = await _aiTradingService.analyzeSymbolStrategy(
        symbol: symbol,
        stockData: stockDataSeries,
        patterns: patterns,
      );

      setState(() {
        _aiAnalysisResults[symbol] = result;
      });
    } catch (e) {
      print('Error performing AI analysis for $symbol: $e');
      setState(() {
        _aiAnalysisResults[symbol] = {
          'error': 'Failed to analyze: ${e.toString()}'
        };
      });
    } finally {
      setState(() {
        _aiAnalysisLoading[symbol] = false;
      });
    }
  }

  Widget _buildAIAnalysisSection(String symbol) {
    final isLoading = _aiAnalysisLoading[symbol] == true;
    final result = _aiAnalysisResults[symbol];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.psychology, size: 16, color: Colors.blue),
            SizedBox(width: 4),
            Text(
              'AI Trading Analysis',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            if (!isLoading)
              TextButton(
                onPressed: () => _performAIAnalysis(symbol),
                child: Text('Analyze', style: TextStyle(fontSize: 10)),
              ),
          ],
        ),
        if (isLoading)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (result != null) ...[
          if (result.containsKey('error'))
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                result['error'],
                style: TextStyle(fontSize: 10, color: Colors.red),
              ),
            )
          else ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trend: ${result['trend'] ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 10,
                      color: result['trend'] == 'Bullish'
                          ? Colors.green
                          : result['trend'] == 'Bearish'
                              ? Colors.red
                              : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (result['confidence'] != null)
                    Text(
                      'Confidence: ${result['confidence']}%',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  if (result['strategy'] != null)
                    Text(
                      'Strategy: ${result['strategy']}',
                      style: TextStyle(fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class MiniChartPainter extends CustomPainter {
  final List<StockData> dataPoints;
  final double minPrice;
  final double maxPrice;

  MiniChartPainter(this.dataPoints, this.minPrice, this.maxPrice);

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.length < 2) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final priceRange = maxPrice - minPrice;

    for (int i = 0; i < dataPoints.length; i++) {
      final x = (i / (dataPoints.length - 1)) * size.width;
      final y = size.height -
          ((dataPoints[i].close - minPrice) / priceRange) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
