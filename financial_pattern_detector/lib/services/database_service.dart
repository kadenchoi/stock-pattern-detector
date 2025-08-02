import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/stock_data.dart';
import '../models/pattern_detection.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'financial_patterns.db';
  static const int _dbVersion = 1;

  // Table names
  static const String _stockDataTable = 'stock_data';
  static const String _patternMatchTable = 'pattern_matches';
  static const String _watchlistTable = 'watchlist';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Stock data table
    await db.execute('''
      CREATE TABLE $_stockDataTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        symbol TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        open REAL NOT NULL,
        high REAL NOT NULL,
        low REAL NOT NULL,
        close REAL NOT NULL,
        volume INTEGER NOT NULL,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        UNIQUE(symbol, timestamp)
      )
    ''');

    // Pattern matches table
    await db.execute('''
      CREATE TABLE $_patternMatchTable (
        id TEXT PRIMARY KEY,
        symbol TEXT NOT NULL,
        pattern_type TEXT NOT NULL,
        direction TEXT NOT NULL,
        match_score REAL NOT NULL,
        detected_at INTEGER NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER NOT NULL,
        price_target REAL,
        description TEXT NOT NULL,
        metadata TEXT,
        created_at INTEGER DEFAULT (strftime('%s', 'now'))
      )
    ''');

    // Watchlist table
    await db.execute('''
      CREATE TABLE $_watchlistTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        symbol TEXT UNIQUE NOT NULL,
        added_at INTEGER DEFAULT (strftime('%s', 'now')),
        is_active INTEGER DEFAULT 1
      )
    ''');

    // Create indexes for better performance
    await db.execute(
      'CREATE INDEX idx_stock_symbol_timestamp ON $_stockDataTable(symbol, timestamp)',
    );
    await db.execute(
      'CREATE INDEX idx_pattern_symbol_detected ON $_patternMatchTable(symbol, detected_at)',
    );
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Handle database schema upgrades here
    if (oldVersion < 2) {
      // Future schema changes
    }
  }

  // Stock data operations
  Future<void> insertStockData(List<StockData> stockDataList) async {
    final db = await database;
    final batch = db.batch();

    for (final stockData in stockDataList) {
      batch.insert(
          _stockDataTable,
          {
            'symbol': stockData.symbol,
            'timestamp': stockData.timestamp.millisecondsSinceEpoch,
            'open': stockData.open,
            'high': stockData.high,
            'low': stockData.low,
            'close': stockData.close,
            'volume': stockData.volume,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<List<StockData>> getStockData({
    required String symbol,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final db = await database;
    String whereClause = 'symbol = ?';
    List<dynamic> whereArgs = [symbol];

    if (startDate != null) {
      whereClause += ' AND timestamp >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      whereClause += ' AND timestamp <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final result = await db.query(
      _stockDataTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp ASC',
      limit: limit,
    );

    return result
        .map(
          (row) => StockData(
            symbol: row['symbol'] as String,
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              row['timestamp'] as int,
            ),
            open: row['open'] as double,
            high: row['high'] as double,
            low: row['low'] as double,
            close: row['close'] as double,
            volume: row['volume'] as int,
          ),
        )
        .toList();
  }

  Future<DateTime?> getLastUpdateTime(String symbol) async {
    final db = await database;
    final result = await db.query(
      _stockDataTable,
      columns: ['MAX(timestamp) as last_timestamp'],
      where: 'symbol = ?',
      whereArgs: [symbol],
    );

    if (result.isNotEmpty && result.first['last_timestamp'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        result.first['last_timestamp'] as int,
      );
    }
    return null;
  }

  // Pattern match operations
  Future<void> insertPatternMatch(PatternMatch pattern) async {
    final db = await database;

    await db.insert(
        _patternMatchTable,
        {
          'id': pattern.id,
          'symbol': pattern.symbol,
          'pattern_type': pattern.patternType.name,
          'direction': pattern.direction.name,
          'match_score': pattern.matchScore,
          'detected_at': pattern.detectedAt.millisecondsSinceEpoch,
          'start_time': pattern.startTime.millisecondsSinceEpoch,
          'end_time': pattern.endTime.millisecondsSinceEpoch,
          'price_target': pattern.priceTarget,
          'description': pattern.description,
          'metadata':
              pattern.metadata.isNotEmpty ? pattern.metadata.toString() : null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<PatternMatch>> getPatternMatches({
    String? symbol,
    DateTime? startDate,
    DateTime? endDate,
    double? minScore,
    int? limit,
  }) async {
    final db = await database;
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (symbol != null) {
      whereClause += ' AND symbol = ?';
      whereArgs.add(symbol);
    }

    if (startDate != null) {
      whereClause += ' AND detected_at >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      whereClause += ' AND detected_at <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    if (minScore != null) {
      whereClause += ' AND match_score >= ?';
      whereArgs.add(minScore);
    }

    final result = await db.query(
      _patternMatchTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'detected_at DESC, match_score DESC',
      limit: limit,
    );

    return result
        .map(
          (row) => PatternMatch(
            id: row['id'] as String,
            symbol: row['symbol'] as String,
            patternType: PatternType.values.firstWhere(
              (type) => type.name == row['pattern_type'],
            ),
            direction: PatternDirection.values.firstWhere(
              (dir) => dir.name == row['direction'],
            ),
            matchScore: row['match_score'] as double,
            detectedAt: DateTime.fromMillisecondsSinceEpoch(
              row['detected_at'] as int,
            ),
            startTime: DateTime.fromMillisecondsSinceEpoch(
              row['start_time'] as int,
            ),
            endTime: DateTime.fromMillisecondsSinceEpoch(
              row['end_time'] as int,
            ),
            priceTarget: row['price_target'] as double?,
            description: row['description'] as String,
            metadata: {}, // Could parse metadata JSON here if needed
          ),
        )
        .toList();
  }

  // Watchlist operations
  Future<void> addToWatchlist(String symbol) async {
    final db = await database;
    await db.insert(
        _watchlistTable,
        {
          'symbol': symbol.toUpperCase(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeFromWatchlist(String symbol) async {
    final db = await database;
    await db.delete(
      _watchlistTable,
      where: 'symbol = ?',
      whereArgs: [symbol.toUpperCase()],
    );
  }

  Future<List<String>> getWatchlist() async {
    final db = await database;
    final result = await db.query(
      _watchlistTable,
      columns: ['symbol'],
      where: 'is_active = 1',
      orderBy: 'added_at ASC',
    );

    return result.map((row) => row['symbol'] as String).toList();
  }

  // Cleanup operations
  Future<void> cleanupOldData({Duration? maxAge, int? maxRecords}) async {
    final db = await database;

    if (maxAge != null) {
      final cutoffTime = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;

      await db.delete(
        _stockDataTable,
        where: 'timestamp < ?',
        whereArgs: [cutoffTime],
      );

      await db.delete(
        _patternMatchTable,
        where: 'detected_at < ?',
        whereArgs: [cutoffTime],
      );
    }

    if (maxRecords != null) {
      // Keep only the most recent records for each symbol
      final symbols = await db.query(
        _stockDataTable,
        columns: ['DISTINCT symbol'],
      );

      for (final symbolRow in symbols) {
        final symbol = symbolRow['symbol'] as String;
        final oldRecords = await db.query(
          _stockDataTable,
          columns: ['id'],
          where: 'symbol = ?',
          whereArgs: [symbol],
          orderBy: 'timestamp DESC',
          offset: maxRecords,
        );

        if (oldRecords.isNotEmpty) {
          final idsToDelete = oldRecords.map((row) => row['id']).join(',');
          await db.delete(_stockDataTable, where: 'id IN ($idsToDelete)');
        }
      }
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
