import 'package:flutter/material.dart';

import '../../models/pattern_detection.dart';

class PatternCard extends StatelessWidget {
  final PatternMatch pattern;
  final VoidCallback? onTap;

  const PatternCard({super.key, required this.pattern, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildPatternInfo(),
              const SizedBox(height: 12),
              _buildDescription(),
              const SizedBox(height: 12),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pattern.symbol,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              pattern.patternName,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        _buildConfidenceBadge(),
      ],
    );
  }

  Widget _buildConfidenceBadge() {
    final percentage = pattern.matchPercentage;
    final color = _getConfidenceColor(percentage);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '${percentage.toStringAsFixed(1)}%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPatternInfo() {
    return Row(
      children: [
        _buildDirectionChip(),
        const SizedBox(width: 12),
        if (pattern.priceTarget != null) _buildPriceTarget(),
      ],
    );
  }

  Widget _buildDirectionChip() {
    final color = _getDirectionColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(pattern.directionEmoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            pattern.direction.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceTarget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.my_location, size: 14, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            '\$${pattern.priceTarget!.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      pattern.description,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTimeInfo(),
        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ],
    );
  }

  Widget _buildTimeInfo() {
    final now = DateTime.now();
    final difference = now.difference(pattern.detectedAt);

    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      timeAgo = '${difference.inMinutes}m ago';
    } else {
      timeAgo = 'Just now';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detected $timeAgo',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          _formatDateRange(),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  String _formatDateRange() {
    final startDate = '${pattern.startTime.month}/${pattern.startTime.day}';
    final endDate = '${pattern.endTime.month}/${pattern.endTime.day}';
    return 'Pattern: $startDate - $endDate';
  }

  Color _getDirectionColor() {
    switch (pattern.direction) {
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
}
