import 'package:flutter/material.dart';
import '../../utils/pattern_filter_service.dart';
import 'patterns_filter_widget.dart';

class QuickFiltersWidget extends StatelessWidget {
  final PatternFilterCriteria currentCriteria;
  final Function(PatternFilterCriteria) onFilterSelected;

  const QuickFiltersWidget({
    super.key,
    required this.currentCriteria,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final presets = PatternFilterService.getQuickFilterPresets();
    final presetNames = PatternFilterService.getQuickFilterNames();

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        itemBuilder: (context, index) {
          final preset = presets[index];
          final name = presetNames[index];
          final isSelected = _isPresetSelected(preset);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(name),
              selected: isSelected,
              onSelected: (_) => onFilterSelected(preset),
              avatar: _getPresetIcon(index),
            ),
          );
        },
      ),
    );
  }

  bool _isPresetSelected(PatternFilterCriteria preset) {
    return _criteriaEquals(currentCriteria, preset);
  }

  bool _criteriaEquals(PatternFilterCriteria a, PatternFilterCriteria b) {
    return a.selectedSymbols.length == b.selectedSymbols.length &&
        a.selectedSymbols.containsAll(b.selectedSymbols) &&
        a.selectedDirections.length == b.selectedDirections.length &&
        a.selectedDirections.containsAll(b.selectedDirections) &&
        a.sortOption == b.sortOption &&
        a.minConfidence == b.minConfidence &&
        ((a.timeRange == null && b.timeRange == null) ||
            (a.timeRange != null &&
                b.timeRange != null &&
                a.timeRange!.start
                        .difference(b.timeRange!.start)
                        .inDays
                        .abs() <=
                    1));
  }

  Widget _getPresetIcon(int index) {
    switch (index) {
      case 0:
        return const Icon(Icons.all_inclusive, size: 16);
      case 1:
        return const Icon(Icons.trending_up, size: 16);
      case 2:
        return const Icon(Icons.trending_down, size: 16);
      case 3:
        return const Icon(Icons.star, size: 16);
      case 4:
        return const Icon(Icons.schedule, size: 16);
      default:
        return const Icon(Icons.filter_list, size: 16);
    }
  }
}
