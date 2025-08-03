import 'package:financial_pattern_detector/managers/app_manager.dart';
import 'package:financial_pattern_detector/models/pattern_detection.dart';
import 'package:flutter/material.dart';
import '../../models/stock_data.dart';
import '../../utils/pattern_filter_service.dart';
import 'settings_screen.dart';
import 'pattern_details_screen.dart';
import '../widgets/pattern_card.dart';
import '../widgets/watchlist_widget.dart';
import '../widgets/status_indicator.dart';
import '../widgets/patterns_filter_widget.dart';
import '../widgets/quick_filters_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final AppManager _appManager = AppManager();
  late TabController _tabController;

  List<PatternMatch> _patterns = [];
  List<PatternMatch> _filteredPatterns = [];
  Map<String, StockDataSeries?> _stockData = {};
  String _currentStatus = 'Initializing...';
  PatternFilterCriteria _filterCriteria = const PatternFilterCriteria();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
        _applyFilters();
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

    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search patterns, symbols, or descriptions...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: _onSearchChanged,
          ),
        ),

        // Filter widget
        PatternsFilterWidget(
          criteria: _filterCriteria,
          allPatterns: _patterns,
          onFiltersChanged: _onFiltersChanged,
        ),

        // Quick filters
        QuickFiltersWidget(
          currentCriteria: _filterCriteria,
          onFilterSelected: _onFiltersChanged,
        ),

        // Results summary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  PatternFilterService.getFilterSummary(
                    _filterCriteria,
                    _patterns.length,
                    _filteredPatterns.length,
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (_filteredPatterns.isNotEmpty)
                Text(
                  'Avg: ${(_filteredPatterns.map((p) => p.matchScore).reduce((a, b) => a + b) / _filteredPatterns.length * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
            ],
          ),
        ),

        // Patterns list
        Expanded(
          child: _filteredPatterns.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_list_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No patterns match your filters',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _filterCriteria = const PatternFilterCriteria();
                            _searchController.clear();
                            _searchQuery = '';
                            _applyFilters();
                          });
                        },
                        child: const Text('Clear All Filters'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _appManager.runManualAnalysis(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _filteredPatterns.length,
                    itemBuilder: (context, index) {
                      final pattern = _filteredPatterns[index];
                      return PatternCard(
                        pattern: pattern,
                        onTap: () => _openPatternDetails(pattern),
                      );
                    },
                  ),
                ),
        ),
      ],
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
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    var filtered =
        PatternFilterService.filterAndSort(_patterns, _filterCriteria);

    // Apply search query if present
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((pattern) =>
              PatternFilterService.matchesSearchQuery(pattern, _searchQuery))
          .toList();
    }

    _filteredPatterns = filtered;
  }

  void _onFiltersChanged(PatternFilterCriteria newCriteria) {
    setState(() {
      _filterCriteria = newCriteria;
      _applyFilters();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }
}
