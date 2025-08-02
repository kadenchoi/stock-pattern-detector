import 'dart:async';
import '../models/app_settings.dart';
import '../models/pattern_detection.dart';
import '../models/stock_data.dart';
import '../services/yahoo_finance_service.dart';
import '../services/pattern_analyzer.dart';
import '../services/platform_database_service.dart';
import '../services/alert_manager_factory.dart';
import '../managers/settings_manager.dart';

class AppManager {
  static final AppManager _instance = AppManager._internal();
  factory AppManager() => _instance;
  AppManager._internal() {
    // Initialize platform-specific alert manager
    _alertManager = AlertManagerFactory.create();
  }

  final YahooFinanceService _yahooService = YahooFinanceService();
  final PatternAnalyzer _patternAnalyzer = PatternAnalyzer();
  final PlatformDatabaseService _databaseService =
      PlatformDatabaseService.instance;
  late final AlertManagerInterface _alertManager;
  final SettingsManager _settingsManager = SettingsManager();

  Timer? _analysisTimer;
  bool _isAnalyzing = false;
  bool _isInitialized = false;

  // Stream controllers for UI updates
  final StreamController<List<PatternMatch>> _patternStreamController =
      StreamController<List<PatternMatch>>.broadcast();
  final StreamController<Map<String, StockDataSeries?>>
      _stockDataStreamController =
      StreamController<Map<String, StockDataSeries?>>.broadcast();
  final StreamController<String> _statusStreamController =
      StreamController<String>.broadcast();

  // Public streams
  Stream<List<PatternMatch>> get patternStream =>
      _patternStreamController.stream;
  Stream<Map<String, StockDataSeries?>> get stockDataStream =>
      _stockDataStreamController.stream;
  Stream<String> get statusStream => _statusStreamController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _updateStatus('Initializing application...');

    try {
      // Initialize all services
      await _alertManager.initialize();
      await _alertManager.requestPermissions();

      _updateStatus('Application initialized successfully');
      _isInitialized = true;

      // Test core functionality
      await _testCoreFunctionality();

      // Start the analysis cycle
      await startAnalysis();
    } catch (e) {
      _updateStatus('Initialization failed: $e');
      print('AppManager initialization error: $e');
    }
  }

  Future<void> startAnalysis() async {
    if (_analysisTimer?.isActive == true) {
      _analysisTimer?.cancel();
    }

    final settings = await _settingsManager.getSettings();

    if (settings.watchlist.isEmpty) {
      _updateStatus('No symbols in watchlist');
      return;
    }

    _updateStatus('Starting pattern analysis...');

    // Run initial analysis
    await _runAnalysisCycle();

    // Set up periodic analysis based on tracking interval
    final intervalDuration = _getIntervalDuration(settings.trackingInterval);
    _analysisTimer = Timer.periodic(
      intervalDuration,
      (_) => _runAnalysisCycle(),
    );

    _updateStatus(
      'Analysis started - checking every ${settings.trackingInterval.displayName}',
    );
  }

  Future<void> stopAnalysis() async {
    _analysisTimer?.cancel();
    _analysisTimer = null;
    _updateStatus('Analysis stopped');
  }

  Future<void> _runAnalysisCycle() async {
    if (_isAnalyzing) {
      print('Analysis already in progress, skipping...');
      return;
    }

    _isAnalyzing = true;

    try {
      final settings = await _settingsManager.getSettings();

      if (settings.watchlist.isEmpty) {
        _updateStatus('No symbols in watchlist');
        return;
      }

      _updateStatus(
        'Fetching data for ${settings.watchlist.length} symbols...',
      );

      // Fetch fresh data for all watchlist symbols
      final stockDataMap = await _yahooService.fetchMultipleStocks(
        symbols: settings.watchlist,
        period: settings.dataPeriod,
        range: _getRangeForPeriod(settings.dataPeriod),
      );

      _stockDataStreamController.add(stockDataMap);

      // Store data in database and analyze patterns
      final allPatterns = <PatternMatch>[];

      for (final entry in stockDataMap.entries) {
        final symbol = entry.key;
        final stockSeries = entry.value;

        if (stockSeries == null) {
          print('No data available for $symbol');
          continue;
        }

        _updateStatus('Analyzing patterns for $symbol...');

        // Store in database
        await _databaseService.insertStockDataBatch(stockSeries.data);

        // Analyze patterns
        final patterns = await _patternAnalyzer.analyzePatterns(
          stockSeries,
          minConfidence: settings.patternMatchThreshold,
        );

        // Filter new patterns (not already in database)
        final newPatterns = await _filterNewPatterns(patterns);

        // Store new patterns and send alerts
        for (final pattern in newPatterns) {
          await _databaseService.insertPatternMatch(pattern);
          await _alertManager.sendPatternAlert(
            pattern: pattern,
            settings: settings,
          );
        }

        allPatterns.addAll(patterns);
      }

      _patternStreamController.add(allPatterns);

      final patternCount = allPatterns.length;
      final newPatternCount = allPatterns
          .where(
            (p) => p.detectedAt.isAfter(
              DateTime.now().subtract(const Duration(hours: 1)),
            ),
          )
          .length;

      _updateStatus(
        'Analysis complete - Found $patternCount patterns ($newPatternCount new)',
      );
    } catch (e) {
      _updateStatus('Analysis failed: $e');
      print('Analysis cycle error: $e');
    } finally {
      _isAnalyzing = false;
    }
  }

  Future<List<PatternMatch>> _filterNewPatterns(
    List<PatternMatch> patterns,
  ) async {
    final newPatterns = <PatternMatch>[];

    for (final pattern in patterns) {
      // Check if similar pattern already exists in database
      final existingPatterns = await _databaseService.getPatternMatches(
        symbol: pattern.symbol,
        startDate: pattern.startTime.subtract(const Duration(hours: 1)),
        endDate: pattern.endTime.add(const Duration(hours: 1)),
      );

      final isDuplicate = existingPatterns.any(
        (existing) =>
            existing.patternType == pattern.patternType &&
            existing.direction == pattern.direction &&
            (existing.matchScore - pattern.matchScore).abs() < 0.1,
      );

      if (!isDuplicate) {
        newPatterns.add(pattern);
      }
    }

    return newPatterns;
  }

  Duration _getIntervalDuration(DataPeriod period) {
    switch (period) {
      case DataPeriod.oneMinute:
        return const Duration(minutes: 1);
      case DataPeriod.twoMinutes:
        return const Duration(minutes: 2);
      case DataPeriod.fiveMinutes:
        return const Duration(minutes: 5);
      case DataPeriod.fifteenMinutes:
        return const Duration(minutes: 15);
      case DataPeriod.thirtyMinutes:
        return const Duration(minutes: 30);
      case DataPeriod.sixtyMinutes:
      case DataPeriod.ninetyMinutes:
      case DataPeriod.oneHour:
        return const Duration(hours: 1);
      case DataPeriod.oneDay:
        return const Duration(hours: 4); // Check 4 times per day
      case DataPeriod.fiveDays:
      case DataPeriod.oneWeek:
        return const Duration(hours: 24); // Check once per day
      case DataPeriod.oneMonth:
      case DataPeriod.threeMonths:
        return const Duration(days: 7); // Check once per week
    }
  }

  String _getRangeForPeriod(DataPeriod period) {
    switch (period) {
      case DataPeriod.oneMinute:
      case DataPeriod.twoMinutes:
      case DataPeriod.fiveMinutes:
      case DataPeriod.fifteenMinutes:
      case DataPeriod.thirtyMinutes:
        return '1d';
      case DataPeriod.sixtyMinutes:
      case DataPeriod.ninetyMinutes:
      case DataPeriod.oneHour:
        return '5d';
      case DataPeriod.oneDay:
        return '6mo';
      case DataPeriod.fiveDays:
        return '6mo';
      case DataPeriod.oneWeek:
        return '6mo';
      case DataPeriod.oneMonth:
        return '1y';
      case DataPeriod.threeMonths:
        return '2y';
    }
  }

  void _updateStatus(String status) {
    _statusStreamController.add(status);
    print('AppManager: $status');
  }

  Future<void> _testCoreFunctionality() async {
    print('Testing core functionality...');

    // Test 1: Add a test symbol to watchlist
    try {
      await addSymbolToWatchlist('AAPL');
      print('✓ Successfully added AAPL to watchlist');
    } catch (e) {
      print('✗ Failed to add to watchlist: $e');
    }

    // Test 2: Test Yahoo Finance API
    try {
      final stockData = await _yahooService.fetchStockData(
        symbol: 'AAPL',
        period: DataPeriod.oneWeek,
      );
      if (stockData != null && stockData.data.isNotEmpty) {
        print(
            '✓ Successfully fetched ${stockData.data.length} data points for AAPL');
        print(
            '  Latest price: \$${stockData.data.last.close.toStringAsFixed(2)}');

        // Test 3: Test pattern analysis
        final patterns = await _patternAnalyzer.analyzePatterns(stockData);
        print(
            '✓ Pattern analysis completed - found ${patterns.length} potential patterns');

        for (final pattern in patterns.take(3)) {
          print(
              '  - ${pattern.patternType}: ${pattern.matchScore.toStringAsFixed(3)} match score');
        }
      } else {
        print('✗ No data received from Yahoo Finance');
      }
    } catch (e) {
      print('✗ Yahoo Finance test failed: $e');
    }

    print('Core functionality test completed');
  }

  // Public methods for UI interaction
  Future<void> addSymbolToWatchlist(String symbol) async {
    await _settingsManager.addToWatchlist(symbol);
    // Restart analysis to include new symbol
    if (_analysisTimer?.isActive == true) {
      await startAnalysis();
    }
  }

  Future<void> removeSymbolFromWatchlist(String symbol) async {
    await _settingsManager.removeFromWatchlist(symbol);
  }

  Future<void> updateSettings(AppSettings settings) async {
    await _settingsManager.saveSettings(settings);
    // Restart analysis with new settings
    if (_analysisTimer?.isActive == true) {
      await startAnalysis();
    }
  }

  Future<AppSettings> getSettings() async {
    return await _settingsManager.getSettings();
  }

  Future<List<PatternMatch>> getHistoricalPatterns({
    String? symbol,
    DateTime? startDate,
    DateTime? endDate,
    double? minScore,
    int? limit,
  }) async {
    return await _databaseService.getPatternMatches(
      symbol: symbol,
      startDate: startDate,
      endDate: endDate,
      minScore: minScore,
      limit: limit,
    );
  }

  Future<StockDataSeries?> getStockData(
    String symbol, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final stockDataList = await _databaseService.getStockData(
      symbol: symbol,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );

    if (stockDataList.isEmpty) return null;

    return StockDataSeries(
      symbol: symbol,
      data: stockDataList,
      lastUpdated: DateTime.now(),
    );
  }

  Future<void> runManualAnalysis() async {
    await _runAnalysisCycle();
  }

  Future<void> cleanupOldData() async {
    await _databaseService.cleanupOldData(
      maxAge: const Duration(days: 30),
      maxRecords: 1000,
    );
  }

  void dispose() {
    _analysisTimer?.cancel();
    _patternStreamController.close();
    _stockDataStreamController.close();
    _statusStreamController.close();
    _yahooService.dispose();
    _databaseService.close();
    _alertManager.dispose();
    _settingsManager.dispose();
  }
}
