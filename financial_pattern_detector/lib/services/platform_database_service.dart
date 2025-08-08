import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/stock_data.dart';
import '../models/pattern_detection.dart';
import 'database_service.dart';
import 'database_service_web.dart';
import 'supabase_watchlist_service.dart';
import 'supabase_auth_service.dart';

// Contract for local database-like operations used by the app
abstract class DatabaseServiceInterface {
  Future<void> initialize();
  Future<void> insertStockData(List<StockData> stockDataList);
  Future<void> insertStockDataBatch(List<StockData> stockDataList);
  Future<List<StockData>> getStockData(
      {required String symbol,
      DateTime? startDate,
      DateTime? endDate,
      int? limit});
  Future<StockData?> getLatestStockData(String symbol);
  Future<void> insertPatternMatch(PatternMatch patternMatch);
  Future<List<PatternMatch>> getPatternMatches(
      {String? symbol,
      DateTime? startDate,
      DateTime? endDate,
      double? minScore,
      int? limit});
  Future<PatternMatch?> getPatternMatch(String id);
  Future<void> deletePatternMatch(String id);
  Future<void> deleteOldPatternMatches(DateTime before);
  Future<void> addToWatchlist(String symbol);
  Future<void> removeFromWatchlist(String symbol);
  Future<List<String>> getWatchlist();
  Future<bool> isInWatchlist(String symbol);
  Future<void> clearWatchlist();
  Future<void> deleteOldStockData(DateTime before);
  Future<int> getStockDataCount(String symbol);
  Future<int> getPatternMatchCount({String? symbol});
  Future<void> close();
  Future<void> deleteDatabase();
  Future<void> cleanupOldData({Duration? maxAge, int? maxRecords});
}

// Platform-aware facade that wraps the appropriate adapter (SQLite/Hive)
class PlatformDatabaseService implements DatabaseServiceInterface {
  static PlatformDatabaseService? _instance;
  static PlatformDatabaseService get instance =>
      _instance ??= PlatformDatabaseService._internal();

  final DatabaseServiceInterface _service;

  PlatformDatabaseService._internal()
      : _service =
            kIsWeb ? _DatabaseServiceWebAdapter() : _DatabaseServiceAdapter();

  @override
  Future<void> initialize() => _service.initialize();

  @override
  Future<void> insertStockData(List<StockData> stockDataList) =>
      _service.insertStockData(stockDataList);

  @override
  Future<void> insertStockDataBatch(List<StockData> stockDataList) =>
      _service.insertStockDataBatch(stockDataList);

  @override
  Future<List<StockData>> getStockData(
          {required String symbol,
          DateTime? startDate,
          DateTime? endDate,
          int? limit}) =>
      _service.getStockData(
          symbol: symbol, startDate: startDate, endDate: endDate, limit: limit);

  @override
  Future<StockData?> getLatestStockData(String symbol) =>
      _service.getLatestStockData(symbol);

  @override
  Future<void> insertPatternMatch(PatternMatch patternMatch) =>
      _service.insertPatternMatch(patternMatch);

  @override
  Future<List<PatternMatch>> getPatternMatches(
          {String? symbol,
          DateTime? startDate,
          DateTime? endDate,
          double? minScore,
          int? limit}) =>
      _service.getPatternMatches(
          symbol: symbol,
          startDate: startDate,
          endDate: endDate,
          minScore: minScore,
          limit: limit);

  @override
  Future<PatternMatch?> getPatternMatch(String id) =>
      _service.getPatternMatch(id);

  @override
  Future<void> deletePatternMatch(String id) => _service.deletePatternMatch(id);

  @override
  Future<void> deleteOldPatternMatches(DateTime before) =>
      _service.deleteOldPatternMatches(before);

  @override
  Future<void> addToWatchlist(String symbol) async {
    await _service.addToWatchlist(symbol);
    // Attempt Supabase sync if signed in
    if (SupabaseAuthService.instance.currentUser != null) {
      try {
        await SupabaseWatchlistService.instance.addSymbol(symbol);
      } catch (_) {}
    }
  }

  @override
  Future<void> removeFromWatchlist(String symbol) async {
    await _service.removeFromWatchlist(symbol);
    if (SupabaseAuthService.instance.currentUser != null) {
      try {
        await SupabaseWatchlistService.instance.removeSymbol(symbol);
      } catch (_) {}
    }
  }

  @override
  Future<List<String>> getWatchlist() async {
    final local = await _service.getWatchlist();
    final user = SupabaseAuthService.instance.currentUser;
    if (user == null) return local;
    try {
      final remote = await SupabaseWatchlistService.instance.fetchWatchlist();
      // Treat local as the source of truth on read to avoid re-adding recently removed items
      final localUpper = local.map((s) => s.toUpperCase()).toSet();
      final remoteUpper = remote.map((s) => s.toUpperCase()).toSet();

      // Push local-only to remote
      final toAddRemote = localUpper.difference(remoteUpper).toList();
      if (toAddRemote.isNotEmpty) {
        await SupabaseWatchlistService.instance.addSymbolsBulk(toAddRemote);
      }

      // Do NOT pull remote-only into local here
      return local;
    } catch (_) {
      return local;
    }
  }

  @override
  Future<bool> isInWatchlist(String symbol) => _service.isInWatchlist(symbol);

  @override
  Future<void> clearWatchlist() async {
    await _service.clearWatchlist();
    if (SupabaseAuthService.instance.currentUser != null) {
      try {
        await SupabaseWatchlistService.instance.clearAll();
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteOldStockData(DateTime before) =>
      _service.deleteOldStockData(before);

  @override
  Future<int> getStockDataCount(String symbol) =>
      _service.getStockDataCount(symbol);

  @override
  Future<int> getPatternMatchCount({String? symbol}) =>
      _service.getPatternMatchCount(symbol: symbol);

  @override
  Future<void> close() => _service.close();

  @override
  Future<void> deleteDatabase() => _service.deleteDatabase();

  @override
  Future<void> cleanupOldData({Duration? maxAge, int? maxRecords}) =>
      _service.cleanupOldData(maxAge: maxAge, maxRecords: maxRecords);
}

// Adapter for the original SQLite service
class _DatabaseServiceAdapter implements DatabaseServiceInterface {
  final DatabaseService _service = DatabaseService();

  @override
  Future<void> initialize() async {
    // SQLite service initializes on first use
  }

  @override
  Future<void> insertStockData(List<StockData> stockDataList) =>
      _service.insertStockData(stockDataList);

  @override
  Future<void> insertStockDataBatch(List<StockData> stockDataList) =>
      _service.insertStockData(stockDataList);

  @override
  Future<List<StockData>> getStockData(
          {required String symbol,
          DateTime? startDate,
          DateTime? endDate,
          int? limit}) =>
      _service.getStockData(
          symbol: symbol, startDate: startDate, endDate: endDate, limit: limit);

  @override
  Future<StockData?> getLatestStockData(String symbol) async {
    final data = await _service.getStockData(symbol: symbol, limit: 1);
    return data.isNotEmpty ? data.last : null;
  }

  @override
  Future<void> insertPatternMatch(PatternMatch patternMatch) =>
      _service.insertPatternMatch(patternMatch);

  @override
  Future<List<PatternMatch>> getPatternMatches(
          {String? symbol,
          DateTime? startDate,
          DateTime? endDate,
          double? minScore,
          int? limit}) =>
      _service.getPatternMatches(
          symbol: symbol,
          startDate: startDate,
          endDate: endDate,
          minScore: minScore,
          limit: limit);

  @override
  Future<PatternMatch?> getPatternMatch(String id) async {
    final patterns = await _service.getPatternMatches(limit: 1000);
    try {
      return patterns.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deletePatternMatch(String id) async {
    // Not implemented in original service - would need to add to DatabaseService
    print('deletePatternMatch not implemented in SQLite service');
  }

  @override
  Future<void> deleteOldPatternMatches(DateTime before) async {
    await _service.cleanupOldData(maxAge: DateTime.now().difference(before));
  }

  @override
  Future<void> addToWatchlist(String symbol) => _service.addToWatchlist(symbol);

  @override
  Future<void> removeFromWatchlist(String symbol) =>
      _service.removeFromWatchlist(symbol);

  @override
  Future<List<String>> getWatchlist() => _service.getWatchlist();

  @override
  Future<bool> isInWatchlist(String symbol) async {
    final watchlist = await _service.getWatchlist();
    return watchlist.contains(symbol.toUpperCase());
  }

  @override
  Future<void> clearWatchlist() async {
    final watchlist = await _service.getWatchlist();
    for (final symbol in watchlist) {
      await _service.removeFromWatchlist(symbol);
    }
  }

  @override
  Future<void> deleteOldStockData(DateTime before) async {
    await _service.cleanupOldData(maxAge: DateTime.now().difference(before));
  }

  @override
  Future<int> getStockDataCount(String symbol) async {
    final data = await _service.getStockData(symbol: symbol);
    return data.length;
  }

  @override
  Future<int> getPatternMatchCount({String? symbol}) async {
    final patterns = await _service.getPatternMatches(symbol: symbol);
    return patterns.length;
  }

  @override
  Future<void> close() => _service.close();

  @override
  Future<void> deleteDatabase() async {
    // Not implemented in original service
    print('deleteDatabase not implemented in SQLite service');
  }

  @override
  Future<void> cleanupOldData({Duration? maxAge, int? maxRecords}) =>
      _service.cleanupOldData(maxAge: maxAge, maxRecords: maxRecords);
}

// Adapter for the web Hive service
class _DatabaseServiceWebAdapter implements DatabaseServiceInterface {
  final DatabaseServiceWeb _service = DatabaseServiceWeb();

  @override
  Future<void> initialize() => _service.initialize();

  @override
  Future<void> insertStockData(List<StockData> stockDataList) =>
      _service.insertStockDataBatch(stockDataList);

  @override
  Future<void> insertStockDataBatch(List<StockData> stockDataList) =>
      _service.insertStockDataBatch(stockDataList);

  @override
  Future<List<StockData>> getStockData(
          {required String symbol,
          DateTime? startDate,
          DateTime? endDate,
          int? limit}) =>
      _service.getStockData(symbol,
          startDate: startDate, endDate: endDate, limit: limit);

  @override
  Future<StockData?> getLatestStockData(String symbol) =>
      _service.getLatestStockData(symbol);

  @override
  Future<void> insertPatternMatch(PatternMatch patternMatch) =>
      _service.insertPatternMatch(patternMatch);

  @override
  Future<List<PatternMatch>> getPatternMatches(
      {String? symbol,
      DateTime? startDate,
      DateTime? endDate,
      double? minScore,
      int? limit}) async {
    // Convert minScore to not supported - just filter afterward if needed
    final patterns = await _service.getPatternMatches(
        symbol: symbol, startDate: startDate, endDate: endDate, limit: limit);
    if (minScore != null) {
      return patterns.where((p) => p.matchScore >= minScore).toList();
    }
    return patterns;
  }

  @override
  Future<PatternMatch?> getPatternMatch(String id) =>
      _service.getPatternMatch(id);

  @override
  Future<void> deletePatternMatch(String id) => _service.deletePatternMatch(id);

  @override
  Future<void> deleteOldPatternMatches(DateTime before) =>
      _service.deleteOldPatternMatches(before);

  @override
  Future<void> addToWatchlist(String symbol) => _service.addToWatchlist(symbol);

  @override
  Future<void> removeFromWatchlist(String symbol) =>
      _service.removeFromWatchlist(symbol);

  @override
  Future<List<String>> getWatchlist() => _service.getWatchlist();

  @override
  Future<bool> isInWatchlist(String symbol) => _service.isInWatchlist(symbol);

  @override
  Future<void> clearWatchlist() => _service.clearWatchlist();

  @override
  Future<void> deleteOldStockData(DateTime before) =>
      _service.deleteOldStockData(before);

  @override
  Future<int> getStockDataCount(String symbol) =>
      _service.getStockDataCount(symbol);

  @override
  Future<int> getPatternMatchCount({String? symbol}) =>
      _service.getPatternMatchCount(symbol: symbol);

  @override
  Future<void> close() => _service.close();

  @override
  Future<void> deleteDatabase() => _service.deleteDatabase();

  @override
  Future<void> cleanupOldData({Duration? maxAge, int? maxRecords}) async {
    if (maxAge != null) {
      final cutoffDate = DateTime.now().subtract(maxAge);
      await _service.deleteOldStockData(cutoffDate);
      await _service.deleteOldPatternMatches(cutoffDate);
    }
    // Note: maxRecords not implemented for web service
  }
}
