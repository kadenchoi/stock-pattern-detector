import 'package:financial_pattern_detector/managers/app_manager.dart';
import 'package:financial_pattern_detector/models/pattern_detection.dart';
import 'package:flutter/material.dart';
import '../../models/stock_data.dart';
import 'settings_screen.dart';
import 'pattern_details_screen.dart';
import '../widgets/pattern_card.dart';
import '../widgets/watchlist_widget.dart';
import '../widgets/status_indicator.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final AppManager _appManager = AppManager();
  late TabController _tabController;

  List<PatternMatch> _patterns = [];
  Map<String, StockDataSeries?> _stockData = {};
  String _currentStatus = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeApp();
    _setupStreamListeners();
  }

  Future<void> _initializeApp() async {
    await _appManager.initialize();
    // App initialized successfully
  }

  void _setupStreamListeners() {
    _appManager.patternStream.listen((patterns) {
      setState(() {
        _patterns = patterns;
      });
    });

    _appManager.stockDataStream.listen((stockData) {
      setState(() {
        _stockData = stockData;
      });
    });

    _appManager.statusStream.listen((status) {
      setState(() {
        _currentStatus = status;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Financial Pattern Detector',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _showAddSymbolDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Add Symbol to Watchlist',
          ),
          IconButton(
            onPressed: () => _appManager.runManualAnalysis(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Run Manual Analysis',
          ),
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.trending_up), text: 'Patterns'),
            Tab(icon: Icon(Icons.list), text: 'Watchlist'),
            Tab(icon: Icon(Icons.show_chart), text: 'Charts'),
          ],
        ),
      ),
      body: Column(
        children: [
          StatusIndicator(status: _currentStatus),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPatternsTab(),
                _buildWatchlistTab(),
                _buildChartsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternsTab() {
    if (_patterns.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No patterns detected yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Add symbols to your watchlist to start analysis',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _appManager.runManualAnalysis(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _patterns.length,
        itemBuilder: (context, index) {
          final pattern = _patterns[index];
          return PatternCard(
            pattern: pattern,
            onTap: () => _openPatternDetails(pattern),
          );
        },
      ),
    );
  }

  Widget _buildWatchlistTab() {
    return WatchlistWidget(
      stockData: _stockData,
      onAddSymbol: _showAddSymbolDialog,
      onRemoveSymbol: _removeSymbol,
    );
  }

  Widget _buildChartsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Charts Coming Soon',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Interactive candlestick charts with pattern overlays',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showAddSymbolDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Symbol to Watchlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter stock symbol (e.g., AAPL)',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.of(context).pop();
              _addSymbol(value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final symbol = controller.text.trim().toUpperCase();
              if (symbol.isNotEmpty) {
                Navigator.of(context).pop();
                _addSymbol(symbol);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addSymbol(String symbol) async {
    try {
      await _appManager.addSymbolToWatchlist(symbol);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $symbol to watchlist'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add $symbol: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeSymbol(String symbol) async {
    try {
      await _appManager.removeSymbolFromWatchlist(symbol);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed $symbol from watchlist'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove $symbol: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          onSettingsChanged: (settings) async {
            await _appManager.updateSettings(settings);
            // Settings updated successfully
          },
        ),
      ),
    );
  }

  void _openPatternDetails(PatternMatch pattern) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PatternDetailsScreen(pattern: pattern),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
