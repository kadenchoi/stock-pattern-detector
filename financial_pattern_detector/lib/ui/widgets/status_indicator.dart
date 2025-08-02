import 'package:flutter/material.dart';

class StatusIndicator extends StatelessWidget {
  final String status;

  const StatusIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: _getStatusColor().withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _getStatusIcon(),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status,
              style: TextStyle(
                color: _getStatusColor(),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_isAnalyzing())
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    final lowerStatus = status.toLowerCase();

    if (lowerStatus.contains('error') || lowerStatus.contains('failed')) {
      return Colors.red;
    } else if (lowerStatus.contains('warning') ||
        lowerStatus.contains('no symbols')) {
      return Colors.orange;
    } else if (lowerStatus.contains('complete') ||
        lowerStatus.contains('success')) {
      return Colors.green;
    } else if (lowerStatus.contains('analyzing') ||
        lowerStatus.contains('fetching')) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  Widget _getStatusIcon() {
    final lowerStatus = status.toLowerCase();
    final color = _getStatusColor();

    if (lowerStatus.contains('error') || lowerStatus.contains('failed')) {
      return Icon(Icons.error, color: color, size: 16);
    } else if (lowerStatus.contains('warning') ||
        lowerStatus.contains('no symbols')) {
      return Icon(Icons.warning, color: color, size: 16);
    } else if (lowerStatus.contains('complete') ||
        lowerStatus.contains('success')) {
      return Icon(Icons.check_circle, color: color, size: 16);
    } else if (lowerStatus.contains('analyzing') ||
        lowerStatus.contains('fetching')) {
      return Icon(Icons.analytics, color: color, size: 16);
    } else {
      return Icon(Icons.info, color: color, size: 16);
    }
  }

  bool _isAnalyzing() {
    final lowerStatus = status.toLowerCase();
    return lowerStatus.contains('analyzing') ||
        lowerStatus.contains('fetching') ||
        lowerStatus.contains('processing');
  }
}
