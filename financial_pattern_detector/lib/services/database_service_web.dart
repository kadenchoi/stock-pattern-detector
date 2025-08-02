import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/stock_data.dart';
import '../models/pattern_detection.dart';

class DatabaseServiceWeb {
  static Box<String>? _stockDataBox;
  static Box<String>? _patternMatchBox;
  static Box<String>? _watchlistBox;

  // Box names
  static const String _stockDataBoxName = 'stock_data';
  static const String _patternMatchBoxName = 'pattern_matches';
  static const String _watchlistBoxName = 'watchlist';

  Future<void> initialize() async {
    await Hive.initFlutter();
    
    _stockDataBox = await Hive.openBox<String>(_stockDataBoxName);
    _patternMatchBox = await Hive.openBox<String>(_patternMatchBoxName);
    _watchlistBox = await Hive.openBox<String>(_watchlistBoxName);
  }

  Box<String> get stockDataBox {
    if (_stockDataBox == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }
    return _stockDataBox!;
  }

  Box<String> get patternMatchBox {
    if (_patternMatchBox == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }
    return _patternMatchBox!;
  }

  Box<String> get watchlistBox {
    if (_watchlistBox == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }
    return _watchlistBox!;
  }

  // Stock data operations
  Future<void> insertStockData(StockData stockData) async {
    final key = '${stockData.symbol}_${stockData.timestamp.millisecondsSinceEpoch}';
    final jsonData = jsonEncode(stockData.toJson());
    await stockDataBox.put(key, jsonData);
  }

  Future<void> insertStockDataBatch(List<StockData> stockDataList) async {
    final Map<String, String> batch = {};
    for (final stockData in stockDataList) {
      final key = '${stockData.symbol}_${stockData.timestamp.millisecondsSinceEpoch}';
      batch[key] = jsonEncode(stockData.toJson());
    }
    await stockDataBox.putAll(batch);
  }

  Future<List<StockData>> getStockData(
    String symbol, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final allKeys = stockDataBox.keys.where((key) => key.toString().startsWith(symbol)).toList();
    
    List<StockData> stockDataList = [];
    
    for (final key in allKeys) {
      final jsonData = stockDataBox.get(key);
      if (jsonData != null) {
        final data = StockData.fromJson(jsonDecode(jsonData));
        
        // Apply date filters
        if (startDate != null && data.timestamp.isBefore(startDate)) continue;
        if (endDate != null && data.timestamp.isAfter(endDate)) continue;
        
        stockDataList.add(data);
      }
    }
    
    // Sort by timestamp
    stockDataList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // Apply limit
    if (limit != null && stockDataList.length > limit) {
      stockDataList = stockDataList.sublist(stockDataList.length - limit);
    }
    
    return stockDataList;
  }

  Future<StockData?> getLatestStockData(String symbol) async {
    final stockDataList = await getStockData(symbol, limit: 1);
    return stockDataList.isNotEmpty ? stockDataList.last : null;
  }

  // Pattern match operations
  Future<void> insertPatternMatch(PatternMatch patternMatch) async {
    final key = patternMatch.id;
    final jsonData = jsonEncode(patternMatch.toJson());
    await patternMatchBox.put(key, jsonData);
  }

  Future<List<PatternMatch>> getPatternMatches({
    String? symbol,
    PatternType? patternType,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    List<PatternMatch> patternMatches = [];
    
    for (final key in patternMatchBox.keys) {
      final jsonData = patternMatchBox.get(key);
      if (jsonData != null) {
        final pattern = PatternMatch.fromJson(jsonDecode(jsonData));
        
        // Apply filters
        if (symbol != null && pattern.symbol != symbol) continue;
        if (patternType != null && pattern.patternType != patternType) continue;
        if (startDate != null && pattern.detectedAt.isBefore(startDate)) continue;
        if (endDate != null && pattern.detectedAt.isAfter(endDate)) continue;
        
        patternMatches.add(pattern);
      }
    }
    
    // Sort by detection time (newest first)
    patternMatches.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    
    // Apply limit
    if (limit != null && patternMatches.length > limit) {
      patternMatches = patternMatches.sublist(0, limit);
    }
    
    return patternMatches;
  }

  Future<PatternMatch?> getPatternMatch(String id) async {
    final jsonData = patternMatchBox.get(id);
    if (jsonData != null) {
      return PatternMatch.fromJson(jsonDecode(jsonData));
    }
    return null;
  }

  Future<void> deletePatternMatch(String id) async {
    await patternMatchBox.delete(id);
  }

  Future<void> deleteOldPatternMatches(DateTime before) async {
    final keysToDelete = <String>[];
    
    for (final key in patternMatchBox.keys) {
      final jsonData = patternMatchBox.get(key);
      if (jsonData != null) {
        final pattern = PatternMatch.fromJson(jsonDecode(jsonData));
        if (pattern.detectedAt.isBefore(before)) {
          keysToDelete.add(key.toString());
        }
      }
    }
    
    await patternMatchBox.deleteAll(keysToDelete);
  }

  // Watchlist operations
  Future<void> addToWatchlist(String symbol) async {
    await watchlistBox.put(symbol, jsonEncode({'symbol': symbol, 'addedAt': DateTime.now().toIso8601String()}));
  }

  Future<void> removeFromWatchlist(String symbol) async {
    await watchlistBox.delete(symbol);
  }

  Future<List<String>> getWatchlist() async {
    return watchlistBox.keys.map((key) => key.toString()).toList();
  }

  Future<bool> isInWatchlist(String symbol) async {
    return watchlistBox.containsKey(symbol);
  }

  Future<void> clearWatchlist() async {
    await watchlistBox.clear();
  }

  // Cleanup operations
  Future<void> deleteOldStockData(DateTime before) async {
    final keysToDelete = <String>[];
    
    for (final key in stockDataBox.keys) {
      final jsonData = stockDataBox.get(key);
      if (jsonData != null) {
        final data = StockData.fromJson(jsonDecode(jsonData));
        if (data.timestamp.isBefore(before)) {
          keysToDelete.add(key.toString());
        }
      }
    }
    
    await stockDataBox.deleteAll(keysToDelete);
  }

  Future<int> getStockDataCount(String symbol) async {
    return stockDataBox.keys.where((key) => key.toString().startsWith(symbol)).length;
  }

  Future<int> getPatternMatchCount({String? symbol}) async {
    if (symbol == null) {
      return patternMatchBox.length;
    }
    
    int count = 0;
    for (final key in patternMatchBox.keys) {
      final jsonData = patternMatchBox.get(key);
      if (jsonData != null) {
        final pattern = PatternMatch.fromJson(jsonDecode(jsonData));
        if (pattern.symbol == symbol) {
          count++;
        }
      }
    }
    return count;
  }

  Future<void> close() async {
    await _stockDataBox?.close();
    await _patternMatchBox?.close();
    await _watchlistBox?.close();
  }

  Future<void> deleteDatabase() async {
    await stockDataBox.clear();
    await patternMatchBox.clear();
    await watchlistBox.clear();
  }

  Future<void> cleanupOldData({Duration? maxAge, int? maxRecords}) async {
    if (maxAge != null) {
      final cutoffDate = DateTime.now().subtract(maxAge);
      await deleteOldStockData(cutoffDate);
      await deleteOldPatternMatches(cutoffDate);
    }
    // Note: maxRecords cleanup not implemented for web service as it would be complex
    // and the web storage is generally more limited anyway
  }
}
