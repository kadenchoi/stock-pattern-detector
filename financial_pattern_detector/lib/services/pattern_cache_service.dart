import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/pattern_detection.dart';

class PatternCacheService {
  static final PatternCacheService instance = PatternCacheService._();
  PatternCacheService._();

  static const _boxName = 'pattern_cache';
  static const _latestPatternsKey = 'latest_patterns';
  static const _allPatternsKey = 'all_patterns';
  static const _lastUpdateKey = 'last_update';
  Box<String>? _box;

  Future<void> initialize() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  /// Cache the latest patterns from analysis
  Future<void> cachePatterns(List<PatternMatch> patterns) async {
    if (_box == null) await initialize();
    final jsonList = patterns.map((p) => jsonEncode(p.toJson())).toList();
    await _box!.put(_latestPatternsKey, jsonEncode(jsonList));
    await _box!.put(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  /// Cache all patterns (including historical ones)
  Future<void> cacheAllPatterns(List<PatternMatch> patterns) async {
    if (_box == null) await initialize();
    final jsonList = patterns.map((p) => jsonEncode(p.toJson())).toList();
    await _box!.put(_allPatternsKey, jsonEncode(jsonList));
    await _box!.put(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  /// Get cached patterns from latest analysis
  Future<List<PatternMatch>> getCachedPatterns() async {
    if (_box == null) await initialize();
    final raw = _box!.get(_latestPatternsKey);
    if (raw == null) return [];
    return _parsePatternList(raw);
  }

  /// Get all cached patterns (including historical)
  Future<List<PatternMatch>> getAllCachedPatterns() async {
    if (_box == null) await initialize();
    final raw = _box!.get(_allPatternsKey);
    if (raw == null) return [];
    return _parsePatternList(raw);
  }

  /// Get the last cache update time
  Future<DateTime?> getLastUpdateTime() async {
    if (_box == null) await initialize();
    final raw = _box!.get(_lastUpdateKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// Merge cached patterns with new patterns, removing duplicates
  List<PatternMatch> mergePatterns(
    List<PatternMatch> cachedPatterns,
    List<PatternMatch> newPatterns,
  ) {
    final Map<String, PatternMatch> patternMap = {};

    // Add cached patterns first
    for (final pattern in cachedPatterns) {
      final key = _generatePatternKey(pattern);
      patternMap[key] = pattern;
    }

    // Add new patterns, which will override cached ones if they're duplicates
    for (final pattern in newPatterns) {
      final key = _generatePatternKey(pattern);
      patternMap[key] = pattern;
    }

    // Convert back to list and sort by detection time (newest first)
    final mergedList = patternMap.values.toList();
    mergedList.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));

    return mergedList;
  }

  /// Check if two patterns are similar (potential duplicates)
  bool arePatternsSimular(PatternMatch pattern1, PatternMatch pattern2) {
    if (pattern1.symbol != pattern2.symbol) return false;
    if (pattern1.patternType != pattern2.patternType) return false;
    if (pattern1.direction != pattern2.direction) return false;

    // Check if the time ranges overlap significantly
    final overlap = _calculateTimeOverlap(pattern1, pattern2);
    if (overlap < 0.5) return false; // Less than 50% overlap

    // Check if match scores are similar (within 10%)
    final scoreDiff = (pattern1.matchScore - pattern2.matchScore).abs();
    if (scoreDiff > 0.1) return false;

    return true;
  }

  /// Remove duplicate patterns from a list
  List<PatternMatch> removeDuplicates(List<PatternMatch> patterns) {
    final Map<String, PatternMatch> uniquePatterns = {};

    for (final pattern in patterns) {
      final key = _generatePatternKey(pattern);

      // If we already have a pattern with this key, keep the one with higher confidence
      if (uniquePatterns.containsKey(key)) {
        final existing = uniquePatterns[key]!;
        if (pattern.matchScore > existing.matchScore) {
          uniquePatterns[key] = pattern;
        }
      } else {
        uniquePatterns[key] = pattern;
      }
    }

    return uniquePatterns.values.toList();
  }

  /// Generate a unique key for pattern deduplication
  String _generatePatternKey(PatternMatch pattern) {
    final startDay = DateTime(
      pattern.startTime.year,
      pattern.startTime.month,
      pattern.startTime.day,
    );
    final endDay = DateTime(
      pattern.endTime.year,
      pattern.endTime.month,
      pattern.endTime.day,
    );

    return '${pattern.symbol}_${pattern.patternType.name}_${pattern.direction.name}_${startDay.millisecondsSinceEpoch}_${endDay.millisecondsSinceEpoch}';
  }

  /// Calculate time overlap between two patterns (0.0 to 1.0)
  double _calculateTimeOverlap(PatternMatch pattern1, PatternMatch pattern2) {
    final start1 = pattern1.startTime.millisecondsSinceEpoch;
    final end1 = pattern1.endTime.millisecondsSinceEpoch;
    final start2 = pattern2.startTime.millisecondsSinceEpoch;
    final end2 = pattern2.endTime.millisecondsSinceEpoch;

    final overlapStart = start1 > start2 ? start1 : start2;
    final overlapEnd = end1 < end2 ? end1 : end2;

    if (overlapStart >= overlapEnd) return 0.0;

    final overlapDuration = overlapEnd - overlapStart;
    final totalDuration = (end1 - start1) + (end2 - start2) - overlapDuration;

    return totalDuration > 0 ? overlapDuration / totalDuration : 0.0;
  }

  /// Parse pattern list from JSON string
  List<PatternMatch> _parsePatternList(String raw) {
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list
          .cast<String>()
          .map((s) =>
              PatternMatch.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error parsing cached patterns: $e');
      return [];
    }
  }

  /// Clear all cached data
  Future<void> clear() async {
    if (_box == null) await initialize();
    await _box!.delete(_latestPatternsKey);
    await _box!.delete(_allPatternsKey);
    await _box!.delete(_lastUpdateKey);
  }

  /// Clear only latest patterns cache
  Future<void> clearLatestPatterns() async {
    if (_box == null) await initialize();
    await _box!.delete(_latestPatternsKey);
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final lastUpdate = await getLastUpdateTime();
    final latestPatterns = await getCachedPatterns();
    final allPatterns = await getAllCachedPatterns();

    return {
      'lastUpdate': lastUpdate?.toIso8601String(),
      'latestPatternCount': latestPatterns.length,
      'totalPatternCount': allPatterns.length,
      'cacheAge': lastUpdate != null
          ? DateTime.now().difference(lastUpdate).inMinutes
          : null,
    };
  }
}
