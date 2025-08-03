import 'package:flutter/material.dart';
import '../models/pattern_detection.dart';
import '../ui/widgets/patterns_filter_widget.dart';

class PatternFilterService {
  /// Filters and sorts a list of patterns based on the given criteria
  static List<PatternMatch> filterAndSort(
    List<PatternMatch> patterns,
    PatternFilterCriteria criteria,
  ) {
    var filteredPatterns = patterns.where((pattern) {
      // Filter by symbols
      if (criteria.selectedSymbols.isNotEmpty &&
          !criteria.selectedSymbols.contains(pattern.symbol)) {
        return false;
      }

      // Filter by direction
      if (criteria.selectedDirections.isNotEmpty &&
          !criteria.selectedDirections.contains(pattern.direction)) {
        return false;
      }

      // Filter by time range
      if (criteria.timeRange != null) {
        final timeRange = criteria.timeRange!;
        if (pattern.detectedAt.isBefore(timeRange.start) ||
            pattern.detectedAt
                .isAfter(timeRange.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      // Filter by minimum confidence
      if (pattern.matchScore < criteria.minConfidence) {
        return false;
      }

      return true;
    }).toList();

    // Sort patterns based on criteria
    switch (criteria.sortOption) {
      case SortOption.newestFirst:
        filteredPatterns.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
        break;
      case SortOption.oldestFirst:
        filteredPatterns.sort((a, b) => a.detectedAt.compareTo(b.detectedAt));
        break;
      case SortOption.highestConfidence:
        filteredPatterns.sort((a, b) => b.matchScore.compareTo(a.matchScore));
        break;
      case SortOption.lowestConfidence:
        filteredPatterns.sort((a, b) => a.matchScore.compareTo(b.matchScore));
        break;
    }

    return filteredPatterns;
  }

  /// Gets unique symbols from a list of patterns
  static Set<String> getUniqueSymbols(List<PatternMatch> patterns) {
    return patterns.map((pattern) => pattern.symbol).toSet();
  }

  /// Gets unique directions from a list of patterns
  static Set<PatternDirection> getUniqueDirections(
      List<PatternMatch> patterns) {
    return patterns.map((pattern) => pattern.direction).toSet();
  }

  /// Gets the date range of patterns
  static DateTimeRange? getPatternDateRange(List<PatternMatch> patterns) {
    if (patterns.isEmpty) return null;

    final sortedByDate = List<PatternMatch>.from(patterns)
      ..sort((a, b) => a.detectedAt.compareTo(b.detectedAt));

    return DateTimeRange(
      start: sortedByDate.first.detectedAt,
      end: sortedByDate.last.detectedAt,
    );
  }

  /// Gets filter summary text
  static String getFilterSummary(
    PatternFilterCriteria criteria,
    int totalPatterns,
    int filteredPatterns,
  ) {
    if (!criteria.hasActiveFilters) {
      return 'Showing all $totalPatterns patterns';
    }

    final filters = <String>[];

    if (criteria.selectedSymbols.isNotEmpty) {
      filters.add(
          '${criteria.selectedSymbols.length} symbol${criteria.selectedSymbols.length == 1 ? '' : 's'}');
    }

    if (criteria.selectedDirections.isNotEmpty) {
      filters.add(
          '${criteria.selectedDirections.length} direction${criteria.selectedDirections.length == 1 ? '' : 's'}');
    }

    if (criteria.timeRange != null) {
      filters.add('custom time range');
    }

    if (criteria.minConfidence > 0.0) {
      filters.add(
          '${(criteria.minConfidence * 100).toStringAsFixed(0)}%+ confidence');
    }

    final filterText = filters.join(', ');
    return 'Showing $filteredPatterns of $totalPatterns patterns ($filterText)';
  }

  /// Checks if a pattern matches the search query
  static bool matchesSearchQuery(PatternMatch pattern, String query) {
    if (query.isEmpty) return true;

    final lowercaseQuery = query.toLowerCase();
    return pattern.symbol.toLowerCase().contains(lowercaseQuery) ||
        pattern.patternType.name.toLowerCase().contains(lowercaseQuery) ||
        pattern.direction.name.toLowerCase().contains(lowercaseQuery) ||
        pattern.description.toLowerCase().contains(lowercaseQuery);
  }

  /// Gets quick filter presets
  static List<PatternFilterCriteria> getQuickFilterPresets() {
    return [
      const PatternFilterCriteria(
        sortOption: SortOption.newestFirst,
      ),
      const PatternFilterCriteria(
        selectedDirections: {PatternDirection.bullish},
        sortOption: SortOption.highestConfidence,
      ),
      const PatternFilterCriteria(
        selectedDirections: {PatternDirection.bearish},
        sortOption: SortOption.highestConfidence,
      ),
      const PatternFilterCriteria(
        minConfidence: 0.8,
        sortOption: SortOption.newestFirst,
      ),
      PatternFilterCriteria(
        timeRange: DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 7)),
          end: DateTime.now(),
        ),
        sortOption: SortOption.newestFirst,
      ),
    ];
  }

  /// Gets preset names for quick filters
  static List<String> getQuickFilterNames() {
    return [
      'All Patterns',
      'Bullish (High Confidence)',
      'Bearish (High Confidence)',
      'High Confidence (80%+)',
      'Last 7 Days',
    ];
  }
}
