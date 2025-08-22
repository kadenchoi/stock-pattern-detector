import 'package:flutter/material.dart';
import '../../models/pattern_detection.dart';

class PatternCard extends StatelessWidget {
  final PatternMatch pattern;
  final VoidCallback? onTap;

  const PatternCard({super.key, required this.pattern, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCompactHeader(),
              const SizedBox(height: 6),
              _buildCompactInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Row(
      children: [
        // Symbol badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            pattern.symbol,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Pattern type
        Expanded(
          child: Text(
            pattern.patternName,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Confidence badge
        _buildCompactConfidenceBadge(),
      ],
    );
  }

  Widget _buildCompactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Direction chip
            _buildCompactDirectionChip(),
            const SizedBox(width: 6),

            // Detection time info
            Expanded(
              child: Text(
                'Detected ${_formatCompactTime(pattern.detectedAt)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ),

            // Theoretical target if available (with disclaimer)
            if (pattern.metadata['theoreticalTarget'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'Theory: \$${(pattern.metadata['theoreticalTarget'] as num).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        // Duration and end time info
        _buildDurationInfo(),
      ],
    );
  }

  Widget _buildCompactConfidenceBadge() {
    final percentage = pattern.matchPercentage;
    final color = _getConfidenceColor(percentage);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        '${percentage.toStringAsFixed(0)}%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildCompactDirectionChip() {
    final color = _getDirectionColor();
    final icon = _getDirectionIcon();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            _getDirectionText(),
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompactTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  String _getDirectionText() {
    switch (pattern.direction) {
      case PatternDirection.bullish:
        return 'Bull';
      case PatternDirection.bearish:
        return 'Bear';
      case PatternDirection.breakout:
        return 'Break';
    }
  }

  IconData _getDirectionIcon() {
    switch (pattern.direction) {
      case PatternDirection.bullish:
        return Icons.trending_up;
      case PatternDirection.bearish:
        return Icons.trending_down;
      case PatternDirection.breakout:
        return Icons.open_in_full;
    }
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

  Widget _buildDurationInfo() {
    final duration = pattern.endTime.difference(pattern.startTime);
    final durationText = _formatDuration(duration);
    final endTimeText = _formatCompactTime(pattern.endTime);

    return Row(
      children: [
        // Duration info
        Icon(Icons.schedule, size: 10, color: Colors.grey[500]),
        const SizedBox(width: 2),
        Text(
          'Duration: $durationText',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 8),

        // Pattern end time
        Icon(Icons.flag, size: 10, color: Colors.grey[500]),
        const SizedBox(width: 2),
        Text(
          'Ended $endTimeText',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
