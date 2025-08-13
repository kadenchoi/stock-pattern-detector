import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/firebase_ai_service.dart';

class AiResponseCacheService {
  static const String _boxName = 'ai_responses';
  static Box<String>? _box;

  static final AiResponseCacheService instance = AiResponseCacheService._();
  AiResponseCacheService._();

  Future<void> initialize() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  /// Clear cached strategy for a specific pattern
  Future<void> clearCachedStrategy(String patternId) async {
    final key = _getCacheKey(patternId);
    await _box?.delete(key);
  }

  /// Clear all cached strategies
  Future<void> clearAllCachedStrategies() async {
    await _box?.clear();
  }

  /// Get cache key for a pattern
  String _getCacheKey(String patternId) => 'strategy_$patternId';

  /// Cache an AI trading strategy response
  Future<void> cacheStrategy(String patternId, TradingStrategy strategy) async {
    if (_box == null) await initialize();

    try {
      final jsonString = jsonEncode(strategy.toJson());
      await _box!.put(_getCacheKey(patternId), jsonString);

      // Also store timestamp for cache expiration
      await _box!.put('${_getCacheKey(patternId)}_timestamp',
          DateTime.now().millisecondsSinceEpoch.toString());
    } catch (e) {
      print('Error caching AI strategy: $e');
    }
  }

  /// Retrieve cached AI trading strategy
  Future<TradingStrategy?> getCachedStrategy(String patternId) async {
    if (_box == null) await initialize();

    try {
      final cacheKey = _getCacheKey(patternId);
      final jsonString = _box!.get(cacheKey);

      if (jsonString == null) return null;

      // Check if cache is expired (24 hours)
      final timestampKey = '${cacheKey}_timestamp';
      final timestampString = _box!.get(timestampKey);

      if (timestampString != null) {
        final timestamp = int.tryParse(timestampString);
        if (timestamp != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final now = DateTime.now();
          final difference = now.difference(cacheTime);

          // Cache expires after 24 hours
          if (difference.inHours > 24) {
            await _box!.delete(cacheKey);
            await _box!.delete(timestampKey);
            return null;
          }
        }
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return TradingStrategy.fromJson(json);
    } catch (e) {
      print('Error retrieving cached AI strategy: $e');
      return null;
    }
  }

  /// Check if a strategy is cached and not expired
  Future<bool> hasValidCache(String patternId) async {
    final strategy = await getCachedStrategy(patternId);
    return strategy != null;
  }

  /// Clear all cached AI responses
  Future<void> clearCache() async {
    if (_box == null) await initialize();

    try {
      await _box!.clear();
    } catch (e) {
      print('Error clearing AI cache: $e');
    }
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    if (_box == null) await initialize();

    try {
      final now = DateTime.now();
      final keysToDelete = <String>[];

      for (final key in _box!.keys) {
        if (key.toString().endsWith('_timestamp')) {
          final timestampString = _box!.get(key);
          if (timestampString != null) {
            final timestamp = int.tryParse(timestampString.toString());
            if (timestamp != null) {
              final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
              final difference = now.difference(cacheTime);

              if (difference.inHours > 24) {
                // Mark both the strategy and timestamp for deletion
                keysToDelete.add(key.toString());
                keysToDelete.add(key.toString().replaceAll('_timestamp', ''));
              }
            }
          }
        }
      }

      for (final key in keysToDelete) {
        await _box!.delete(key);
      }
    } catch (e) {
      print('Error clearing expired AI cache: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    if (_box == null) await initialize();

    int totalEntries = 0;
    int validEntries = 0;
    int expiredEntries = 0;

    final now = DateTime.now();

    for (final key in _box!.keys) {
      if (key.toString().startsWith('ai_strategy_') &&
          !key.toString().endsWith('_timestamp')) {
        totalEntries++;

        final timestampKey = '${key}_timestamp';
        final timestampString = _box!.get(timestampKey);

        if (timestampString != null) {
          final timestamp = int.tryParse(timestampString.toString());
          if (timestamp != null) {
            final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
            final difference = now.difference(cacheTime);

            if (difference.inHours > 24) {
              expiredEntries++;
            } else {
              validEntries++;
            }
          }
        }
      }
    }

    return {
      'totalEntries': totalEntries,
      'validEntries': validEntries,
      'expiredEntries': expiredEntries,
      'cacheHitRate': totalEntries > 0
          ? (validEntries / totalEntries * 100).toStringAsFixed(1)
          : '0.0',
    };
  }
}
