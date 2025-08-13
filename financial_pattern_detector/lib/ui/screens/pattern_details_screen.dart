import 'package:flutter/material.dart';

import '../../models/pattern_detection.dart';
import '../../services/firebase_ai_service.dart';
import '../../services/ai_response_cache_service.dart';

class PatternDetailsScreen extends StatefulWidget {
  final PatternMatch pattern;

  const PatternDetailsScreen({super.key, required this.pattern});

  @override
  State<PatternDetailsScreen> createState() => _PatternDetailsScreenState();
}

class _PatternDetailsScreenState extends State<PatternDetailsScreen> {
  TradingStrategy? _tradingStrategy;
  bool _isLoadingStrategy = false;
  String? _errorMessage;
  bool _isFromCache = false;

  @override
  void initState() {
    super.initState();
    _loadCachedStrategy();
  }

  Future<void> _loadCachedStrategy() async {
    try {
      final cachedStrategy = await AiResponseCacheService.instance
          .getCachedStrategy(widget.pattern.id);
      if (cachedStrategy != null) {
        setState(() {
          _tradingStrategy = cachedStrategy;
          _isFromCache = true;
        });
      }
    } catch (e) {
      // Silently handle cache loading errors
      print('Error loading cached strategy: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.pattern.symbol} - ${widget.pattern.patternName}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () => _sharePattern(context),
            icon: const Icon(Icons.share),
            tooltip: 'Share Pattern',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildDetailsCard(),
            const SizedBox(height: 16),
            _buildTimingCard(),
            const SizedBox(height: 16),
            _buildDescriptionCard(),
            const SizedBox(height: 16),
            _buildAiAnalysisCard(),
            if (widget.pattern.metadata.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildMetadataCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.pattern.symbol,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.pattern.patternName,
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getDirectionColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getDirectionColor()),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.pattern.directionEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.pattern.direction.name.toUpperCase(),
                        style: TextStyle(
                          color: _getDirectionColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildConfidenceIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceIndicator() {
    final percentage = widget.pattern.matchPercentage;
    final color = _getConfidenceColor(percentage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Confidence Score',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: widget.pattern.matchScore,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pattern Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Pattern Type', widget.pattern.patternName),
            _buildDetailRow(
              'Direction',
              '${widget.pattern.directionEmoji} ${widget.pattern.direction.name}',
            ),
            _buildDetailRow(
              'Confidence',
              '${widget.pattern.matchPercentage.toStringAsFixed(1)}%',
            ),
            if (widget.pattern.priceTarget != null)
              _buildDetailRow(
                'Price Target',
                '\$${widget.pattern.priceTarget!.toStringAsFixed(2)}',
              ),
            _buildDetailRow('Pattern ID', widget.pattern.id),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Timing Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
                'Detected At', _formatDateTime(widget.pattern.detectedAt)),
            _buildDetailRow(
              'Pattern Start',
              _formatDateTime(widget.pattern.startTime),
            ),
            _buildDetailRow(
                'Pattern End', _formatDateTime(widget.pattern.endTime)),
            _buildDetailRow('Duration', _calculateDuration()),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(widget.pattern.description,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            _buildPatternExplanation(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Technical Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...widget.pattern.metadata.entries.map((entry) {
              return _buildDetailRow(
                _formatMetadataKey(entry.key),
                entry.value.toString(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildPatternExplanation() {
    final explanation = _getPatternExplanation(widget.pattern.patternType);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'About This Pattern',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(explanation, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildAiAnalysisCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.purple),
                    SizedBox(width: 8),
                    Text(
                      'AI Trading Strategy',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_tradingStrategy != null && !_isLoadingStrategy)
                      IconButton(
                        onPressed: () => _loadAiAnalysis(forceRefresh: true),
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh Analysis',
                        color: Colors.purple,
                      ),
                    if (!_isLoadingStrategy && _tradingStrategy == null)
                      ElevatedButton.icon(
                        onPressed: _loadAiAnalysis,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Analyze'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingStrategy)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Analyzing pattern with AI...'),
                  ],
                ),
              )
            else if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Analysis Error',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_errorMessage!, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadAiAnalysis,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_tradingStrategy != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isFromCache)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cached, color: Colors.blue, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Cached Analysis',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildStrategyDetails(),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.psychology, color: Colors.grey, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'Get AI-powered trading strategy for this pattern',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyDetails() {
    final strategy = _tradingStrategy!;
    final recommendationColor =
        _getRecommendationColor(strategy.recommendation);
    final riskColor = _getRiskColor(strategy.riskLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recommendation Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: recommendationColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: recommendationColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strategy.recommendation,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: recommendationColor,
                    ),
                  ),
                  Text(
                    'Confidence: ${(strategy.confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: riskColor),
                ),
                child: Text(
                  '${strategy.riskLevel} RISK',
                  style: TextStyle(
                    color: riskColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Price Targets
        _buildStrategyDetailRow(
            'Entry Point', '\$${strategy.entryPoint.toStringAsFixed(2)}'),
        _buildStrategyDetailRow(
            'Stop Loss', '\$${strategy.stopLoss.toStringAsFixed(2)}'),
        _buildStrategyDetailRow(
            'Take Profit', '\$${strategy.takeProfit.toStringAsFixed(2)}'),
        _buildStrategyDetailRow('Duration', '${strategy.durationDays} days'),

        const SizedBox(height: 16),

        // Reasoning
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Analysis Reasoning',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(strategy.reasoning, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Key Factors
        if (strategy.keyFactors.isNotEmpty) ...[
          const Text(
            'Key Factors',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...strategy.keyFactors.map((factor) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                        child:
                            Text(factor, style: const TextStyle(fontSize: 14))),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildStrategyDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.w500, color: Colors.grey),
          ),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _loadAiAnalysis({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingStrategy = true;
      _errorMessage = null;
      if (forceRefresh) _isFromCache = false;
    });

    try {
      final strategy =
          await FirebaseAiService.instance.analyzePatternForStrategy(
        pattern: widget.pattern,
        stockHistory: [], // Empty for now, can be populated with actual stock data
        currentPrice: widget.pattern.priceTarget,
        forceRefresh: forceRefresh, // Use the parameter
      );

      setState(() {
        _tradingStrategy = strategy;
        _isLoadingStrategy = false;
        _isFromCache = false; // Fresh data from AI
      });

      if (strategy == null) {
        setState(() {
          _errorMessage =
              'Unable to generate trading strategy. Please try again later.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error analyzing pattern: ${e.toString()}';
        _isLoadingStrategy = false;
      });
    }
  }

  Color _getRecommendationColor(String recommendation) {
    switch (recommendation.toUpperCase()) {
      case 'BUY':
        return Colors.green;
      case 'SELL':
        return Colors.red;
      case 'HOLD':
      default:
        return Colors.orange;
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toUpperCase()) {
      case 'LOW':
        return Colors.green;
      case 'MEDIUM':
        return Colors.orange;
      case 'HIGH':
      default:
        return Colors.red;
    }
  }

  Color _getDirectionColor() {
    switch (widget.pattern.direction) {
      case PatternDirection.bullish:
        return Colors.green;
      case PatternDirection.bearish:
        return Colors.red;
      case PatternDirection.breakout:
        return Colors.orange;
    }
  }

  Color _getConfidenceColor(double percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _calculateDuration() {
    final duration =
        widget.pattern.endTime.difference(widget.pattern.startTime);
    if (duration.inDays > 0) {
      return '${duration.inDays} days';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hours';
    } else {
      return '${duration.inMinutes} minutes';
    }
  }

  String _formatMetadataKey(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) =>
              word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ')
        .trim();
  }

  String _getPatternExplanation(PatternType patternType) {
    switch (patternType) {
      case PatternType.headAndShoulders:
        return 'A bearish reversal pattern that forms after an uptrend. It consists of a left shoulder, head (highest peak), and right shoulder. This pattern typically signals a trend reversal from bullish to bearish.';

      case PatternType.cupAndHandle:
        return 'A bullish continuation pattern that resembles a cup with a handle. The cup forms a rounded bottom, and the handle is a slight downward drift. This pattern suggests the price will continue to rise after the handle formation.';

      case PatternType.doubleTop:
        return 'A bearish reversal pattern that occurs after an uptrend. It forms two peaks at approximately the same level with a valley between them. This suggests the uptrend is losing momentum and may reverse.';

      case PatternType.doubleBottom:
        return 'A bullish reversal pattern that occurs after a downtrend. It forms two troughs at approximately the same level with a peak between them. This suggests the downtrend is losing momentum and may reverse upward.';

      case PatternType.ascendingTriangle:
        return 'A bullish continuation pattern with a horizontal resistance line and an ascending support line. The converging lines suggest increasing buying pressure and typically leads to an upward breakout.';

      case PatternType.descendingTriangle:
        return 'A bearish continuation pattern with a horizontal support line and a descending resistance line. The converging lines suggest increasing selling pressure and typically leads to a downward breakdown.';

      case PatternType.triangle:
        return 'A neutral pattern where price moves within converging trend lines. The breakout direction (up or down) typically indicates the continuation of the prior trend or the beginning of a new trend.';

      case PatternType.flag:
        return 'A short-term continuation pattern that appears as a small rectangular consolidation after a strong price move. Flags typically slope against the prevailing trend and suggest the trend will continue.';

      case PatternType.wedge:
        return 'A pattern formed by converging trend lines where both lines slope in the same direction. Rising wedges are typically bearish, while falling wedges are typically bullish.';

      case PatternType.pennant:
        return 'A short-term continuation pattern that looks like a small symmetrical triangle. It typically forms after a strong price move and suggests the trend will continue in the same direction.';
    }
  }

  void _sharePattern(BuildContext context) {
    final shareText = '''
🚨 Pattern Alert: ${widget.pattern.symbol}

Pattern: ${widget.pattern.patternName}
Direction: ${widget.pattern.directionEmoji} ${widget.pattern.direction.name.toUpperCase()}
Confidence: ${widget.pattern.matchPercentage.toStringAsFixed(1)}%
Detected: ${_formatDateTime(widget.pattern.detectedAt)}

${widget.pattern.description}

Generated by Financial Pattern Detector
''';

    // In a real app, you would use a sharing plugin like share_plus
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Pattern details copied to clipboard'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Pattern Details'),
                content: Text(shareText),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
