import 'package:financial_pattern_detector/managers/app_manager.dart';
import 'package:financial_pattern_detector/models/pattern_detection.dart';
import 'package:flutter/material.dart';
import '../../models/stock_data.dart';
import '../../utils/pattern_filter_service.dart';
import '../../services/supabase_auth_service.dart';
import 'settings_screen.dart';
import 'pattern_details_screen.dart';
import '../widgets/pattern_card.dart';
import '../widgets/watchlist_widget.dart';
import '../widgets/candlestick_chart.dart';
import '../widgets/status_indicator.dart';
import '../widgets/patterns_filter_widget.dart';

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
  String? _selectedChartSymbol;
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
        // Initialize or repair selected symbol when data changes
        if (_stockData.isEmpty) {
          _selectedChartSymbol = null;
        } else if (_selectedChartSymbol == null ||
            !_stockData.containsKey(_selectedChartSymbol)) {
          final syms = _stockData.keys.toList()..sort();
          _selectedChartSymbol = syms.first;
        }
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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'signOut') {
                _signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'signOut',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
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
        // Compact search and filter header
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Column(
            children: [
              // Compact search bar
              SizedBox(
                height: 36,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search patterns...',
                    hintStyle: const TextStyle(fontSize: 14),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    isDense: true,
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(height: 6),

              // Compact filter row
              Row(
                children: [
                  // Quick sort button
                  _buildCompactSortButton(),
                  const SizedBox(width: 6),

                  // Quick filter chips
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCompactDirectionFilter(),
                          const SizedBox(width: 6),
                          _buildCompactSymbolFilter(),
                          const SizedBox(width: 6),
                          _buildCompactConfidenceFilter(),
                          const SizedBox(width: 6),
                          _buildCompactTimeFilter(),
                          const SizedBox(width: 6),
                          _buildCompactDurationFilter(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Advanced filters button
                  _buildAdvancedFiltersButton(),
                ],
              ),
            ],
          ),
        ),

        // Compact results summary
        if (_patterns.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getCompactFilterSummary(),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 12),
                  ),
                ),
                if (_filteredPatterns.isNotEmpty) ...[
                  Text(
                    '${(_filteredPatterns.map((p) => p.matchScore).reduce((a, b) => a + b) / _filteredPatterns.length * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  if (_filterCriteria.hasActiveFilters)
                    TextButton(
                      onPressed: _clearAllFilters,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: const Size(0, 20),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child:
                          const Text('Clear', style: TextStyle(fontSize: 11)),
                    ),
                ],
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
    if (_stockData.isEmpty) {
      return const Center(
        child: Text('Add symbols to watchlist to see charts'),
      );
    }
    final symbols = _stockData.keys.toList()..sort();
    final selected = _selectedChartSymbol ?? symbols.first;
    final series = _stockData[selected];
    if (series == null) {
      return const Center(child: Text('No data available'));
    }
    final patternsForSymbol =
        _patterns.where((p) => p.symbol == selected).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              const Text('Symbol:'),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: selected,
                items: symbols
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null && _stockData.containsKey(val)) {
                    setState(() {
                      _selectedChartSymbol = val;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: CandlestickChart(series: series, patterns: patternsForSymbol),
        ),
      ],
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

  Future<void> _signOut() async {
    try {
      await SupabaseAuthService.instance.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  // Compact filter helper methods
  Widget _buildCompactSortButton() {
    return SizedBox(
      height: 28,
      child: OutlinedButton.icon(
        onPressed: _showSortMenu,
        icon: const Icon(Icons.sort, size: 14),
        label: Text(_getSortLabel(), style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildCompactDirectionFilter() {
    final hasSelection = _filterCriteria.selectedDirections.isNotEmpty;
    return SizedBox(
      height: 28,
      child: FilterChip(
        label: Text(
          hasSelection
              ? '${_filterCriteria.selectedDirections.length}D'
              : 'Dir',
          style: const TextStyle(fontSize: 11),
        ),
        selected: hasSelection,
        onSelected: (_) => _showDirectionFilter(),
        avatar: Icon(
          hasSelection ? Icons.trending_up : Icons.swap_vert,
          size: 14,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
    );
  }

  Widget _buildCompactSymbolFilter() {
    final hasSelection = _filterCriteria.selectedSymbols.isNotEmpty;
    return SizedBox(
      height: 28,
      child: FilterChip(
        label: Text(
          hasSelection ? '${_filterCriteria.selectedSymbols.length}S' : 'Sym',
          style: const TextStyle(fontSize: 11),
        ),
        selected: hasSelection,
        onSelected: (_) => _showSymbolFilter(),
        avatar: Icon(
          hasSelection ? Icons.star : Icons.business,
          size: 14,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
    );
  }

  Widget _buildCompactConfidenceFilter() {
    final hasFilter = _filterCriteria.minConfidence > 0.0;
    return SizedBox(
      height: 28,
      child: FilterChip(
        label: Text(
          hasFilter
              ? '${(_filterCriteria.minConfidence * 100).toStringAsFixed(0)}%'
              : 'Conf',
          style: const TextStyle(fontSize: 11),
        ),
        selected: hasFilter,
        onSelected: (_) => _showConfidenceFilter(),
        avatar: Icon(
          hasFilter ? Icons.star_rate : Icons.percent,
          size: 14,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
    );
  }

  Widget _buildCompactTimeFilter() {
    final hasSelection = _filterCriteria.timeRange != null;
    return SizedBox(
      height: 28,
      child: FilterChip(
        label: Text(
          hasSelection ? 'Custom' : 'Time',
          style: const TextStyle(fontSize: 11),
        ),
        selected: hasSelection,
        onSelected: (_) => _showTimeRangeFilter(),
        avatar: Icon(
          hasSelection ? Icons.date_range : Icons.access_time,
          size: 14,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
    );
  }

  Widget _buildCompactDurationFilter() {
    final hasFilter = _filterCriteria.minDurationMultiplier > 0;
    return SizedBox(
      height: 28,
      child: FilterChip(
        label: Text(
          hasFilter ? '${_filterCriteria.minDurationMultiplier}d+' : 'Dur',
          style: const TextStyle(fontSize: 11),
        ),
        selected: hasFilter,
        onSelected: (_) => _showDurationFilter(),
        avatar: Icon(
          hasFilter ? Icons.timelapse : Icons.schedule,
          size: 14,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
    );
  }

  Widget _buildAdvancedFiltersButton() {
    return SizedBox(
      height: 28,
      child: IconButton(
        onPressed: _showAdvancedFilters,
        icon: const Icon(Icons.tune, size: 16),
        tooltip: 'Advanced Filters',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  String _getSortLabel() {
    switch (_filterCriteria.sortOption) {
      case SortOption.newestFirst:
        return 'New';
      case SortOption.oldestFirst:
        return 'Old';
      case SortOption.highestConfidence:
        return 'High';
      case SortOption.lowestConfidence:
        return 'Low';
    }
  }

  String _getCompactFilterSummary() {
    if (_filteredPatterns.length == _patterns.length) {
      return '${_patterns.length} patterns';
    }
    return '${_filteredPatterns.length}/${_patterns.length} patterns';
  }

  void _clearAllFilters() {
    setState(() {
      _filterCriteria = const PatternFilterCriteria();
      _searchController.clear();
      _searchQuery = '';
      _applyFilters();
    });
  }

  // Filter dialog methods
  void _showSortMenu() {
    showMenu<SortOption>(
      context: context,
      position: const RelativeRect.fromLTRB(50, 100, 0, 0),
      items: SortOption.values.map((option) {
        return PopupMenuItem<SortOption>(
          value: option,
          child: Row(
            children: [
              Icon(
                _filterCriteria.sortOption == option
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(_getFullSortLabel(option)),
            ],
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null) {
        _onFiltersChanged(_filterCriteria.copyWith(sortOption: value));
      }
    });
  }

  String _getFullSortLabel(SortOption option) {
    switch (option) {
      case SortOption.newestFirst:
        return 'Newest First';
      case SortOption.oldestFirst:
        return 'Oldest First';
      case SortOption.highestConfidence:
        return 'Highest Confidence';
      case SortOption.lowestConfidence:
        return 'Lowest Confidence';
    }
  }

  void _showDirectionFilter() {
    showDialog(
      context: context,
      builder: (context) => _DirectionFilterDialog(
        selectedDirections: _filterCriteria.selectedDirections,
        onSelectionChanged: (directions) {
          _onFiltersChanged(
              _filterCriteria.copyWith(selectedDirections: directions));
        },
      ),
    );
  }

  void _showSymbolFilter() {
    final availableSymbols = PatternFilterService.getUniqueSymbols(_patterns);
    showDialog(
      context: context,
      builder: (context) => _SymbolFilterDialog(
        availableSymbols: availableSymbols,
        selectedSymbols: _filterCriteria.selectedSymbols,
        onSelectionChanged: (symbols) {
          _onFiltersChanged(_filterCriteria.copyWith(selectedSymbols: symbols));
        },
      ),
    );
  }

  void _showConfidenceFilter() {
    showDialog(
      context: context,
      builder: (context) => _ConfidenceFilterDialog(
        currentMinConfidence: _filterCriteria.minConfidence,
        onConfidenceChanged: (confidence) {
          _onFiltersChanged(
              _filterCriteria.copyWith(minConfidence: confidence));
        },
      ),
    );
  }

  void _showTimeRangeFilter() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _filterCriteria.timeRange,
    );

    if (picked != null) {
      _onFiltersChanged(_filterCriteria.copyWith(timeRange: picked));
    }
  }

  void _showDurationFilter() {
    showDialog(
      context: context,
      builder: (context) => _DurationFilterDialog(
        currentMinDuration: _filterCriteria.minDurationMultiplier,
        onDurationChanged: (duration) {
          _onFiltersChanged(
              _filterCriteria.copyWith(minDurationMultiplier: duration));
        },
      ),
    );
  }

  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => _AdvancedFiltersSheet(
          scrollController: scrollController,
          filterCriteria: _filterCriteria,
          patterns: _patterns,
          onFiltersChanged: (newCriteria) {
            _onFiltersChanged(newCriteria);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

class _DirectionFilterDialog extends StatefulWidget {
  final Set<PatternDirection> selectedDirections;
  final ValueChanged<Set<PatternDirection>> onSelectionChanged;

  const _DirectionFilterDialog({
    required this.selectedDirections,
    required this.onSelectionChanged,
  });

  @override
  State<_DirectionFilterDialog> createState() => _DirectionFilterDialogState();
}

class _DirectionFilterDialogState extends State<_DirectionFilterDialog> {
  late Set<PatternDirection> _selectedDirections;

  @override
  void initState() {
    super.initState();
    _selectedDirections = Set.from(widget.selectedDirections);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Direction(s)'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: PatternDirection.values.map((direction) {
          final isSelected = _selectedDirections.contains(direction);
          return CheckboxListTile(
            title: Text(_getDirectionLabel(direction)),
            value: isSelected,
            onChanged: (selected) {
              setState(() {
                if (selected == true) {
                  _selectedDirections.add(direction);
                } else {
                  _selectedDirections.remove(direction);
                }
              });
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onSelectionChanged(_selectedDirections);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  String _getDirectionLabel(PatternDirection direction) {
    switch (direction) {
      case PatternDirection.bullish:
        return 'Bullish ↗️';
      case PatternDirection.bearish:
        return 'Bearish ↘️';
      case PatternDirection.breakout:
        return 'Breakout ↔️';
    }
  }
}

class _SymbolFilterDialog extends StatefulWidget {
  final Set<String> availableSymbols;
  final Set<String> selectedSymbols;
  final ValueChanged<Set<String>> onSelectionChanged;

  const _SymbolFilterDialog({
    required this.availableSymbols,
    required this.selectedSymbols,
    required this.onSelectionChanged,
  });

  @override
  State<_SymbolFilterDialog> createState() => _SymbolFilterDialogState();
}

class _SymbolFilterDialogState extends State<_SymbolFilterDialog> {
  late Set<String> _selectedSymbols;

  @override
  void initState() {
    super.initState();
    _selectedSymbols = Set.from(widget.selectedSymbols);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Symbol(s)'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView(
          children: widget.availableSymbols.map((symbol) {
            final isSelected = _selectedSymbols.contains(symbol);
            return CheckboxListTile(
              title: Text(symbol),
              value: isSelected,
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedSymbols.add(symbol);
                  } else {
                    _selectedSymbols.remove(symbol);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onSelectionChanged(_selectedSymbols);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _ConfidenceFilterDialog extends StatefulWidget {
  final double currentMinConfidence;
  final ValueChanged<double> onConfidenceChanged;

  const _ConfidenceFilterDialog({
    required this.currentMinConfidence,
    required this.onConfidenceChanged,
  });

  @override
  State<_ConfidenceFilterDialog> createState() =>
      _ConfidenceFilterDialogState();
}

class _ConfidenceFilterDialogState extends State<_ConfidenceFilterDialog> {
  late double _minConfidence;

  @override
  void initState() {
    super.initState();
    _minConfidence = widget.currentMinConfidence;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Minimum Confidence'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${(_minConfidence * 100).toStringAsFixed(0)}%'),
          Slider(
            value: _minConfidence,
            onChanged: (value) {
              setState(() {
                _minConfidence = value;
              });
            },
            min: 0,
            max: 1,
            divisions: 10,
            label: '${(_minConfidence * 100).round()}%',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onConfidenceChanged(_minConfidence);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _DurationFilterDialog extends StatefulWidget {
  final int currentMinDuration;
  final ValueChanged<int> onDurationChanged;

  const _DurationFilterDialog({
    required this.currentMinDuration,
    required this.onDurationChanged,
  });

  @override
  State<_DurationFilterDialog> createState() => _DurationFilterDialogState();
}

class _DurationFilterDialogState extends State<_DurationFilterDialog> {
  late int _minDuration;

  @override
  void initState() {
    super.initState();
    _minDuration = widget.currentMinDuration;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Minimum Pattern Duration'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$_minDuration days minimum'),
          const SizedBox(height: 16),
          Slider(
            value: _minDuration.toDouble(),
            onChanged: (value) {
              setState(() {
                _minDuration = value.round();
              });
            },
            min: 0,
            max: 200,
            divisions: 20,
            label: '$_minDuration days',
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0 days',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('200 days',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _minDuration = 50;
                    });
                  },
                  child: const Text('50d'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _minDuration = 100;
                    });
                  },
                  child: const Text('100d'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onDurationChanged(_minDuration);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _AdvancedFiltersSheet extends StatefulWidget {
  final ScrollController scrollController;
  final PatternFilterCriteria filterCriteria;
  final List<PatternMatch> patterns;
  final ValueChanged<PatternFilterCriteria> onFiltersChanged;

  const _AdvancedFiltersSheet({
    required this.scrollController,
    required this.filterCriteria,
    required this.patterns,
    required this.onFiltersChanged,
  });

  @override
  State<_AdvancedFiltersSheet> createState() => _AdvancedFiltersSheetState();
}

class _AdvancedFiltersSheetState extends State<_AdvancedFiltersSheet> {
  late PatternFilterCriteria _criteria;

  @override
  void initState() {
    super.initState();
    _criteria = widget.filterCriteria;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Advanced Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Reset All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSortSection(),
                  const SizedBox(height: 24),
                  _buildDirectionSection(),
                  const SizedBox(height: 24),
                  _buildSymbolSection(),
                  const SizedBox(height: 24),
                  _buildConfidenceSection(),
                  const SizedBox(height: 24),
                  _buildTimeRangeSection(),
                  const SizedBox(height: 24),
                  _buildDurationSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Apply button
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onFiltersChanged(_criteria),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sort By',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: SortOption.values.map((option) {
            final isSelected = _criteria.sortOption == option;
            return ChoiceChip(
              label: Text(_getFullSortLabel(option)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _criteria = _criteria.copyWith(sortOption: option);
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDirectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pattern Direction',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...PatternDirection.values.map((direction) {
          final isSelected = _criteria.selectedDirections.contains(direction);
          return CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_getDirectionLabel(direction)),
            value: isSelected,
            onChanged: (selected) {
              setState(() {
                final newDirections =
                    Set<PatternDirection>.from(_criteria.selectedDirections);
                if (selected == true) {
                  newDirections.add(direction);
                } else {
                  newDirections.remove(direction);
                }
                _criteria =
                    _criteria.copyWith(selectedDirections: newDirections);
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildSymbolSection() {
    final availableSymbols =
        PatternFilterService.getUniqueSymbols(widget.patterns);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Symbols (${_criteria.selectedSymbols.length}/${availableSymbols.length} selected)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (availableSymbols.isNotEmpty) ...[
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _criteria = _criteria.copyWith(
                        selectedSymbols: availableSymbols.toSet());
                  });
                },
                child: const Text('Select All'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _criteria = _criteria.copyWith(selectedSymbols: <String>{});
                  });
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: availableSymbols.map((symbol) {
              final isSelected = _criteria.selectedSymbols.contains(symbol);
              return FilterChip(
                label: Text(symbol),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    final newSymbols =
                        Set<String>.from(_criteria.selectedSymbols);
                    if (selected) {
                      newSymbols.add(symbol);
                    } else {
                      newSymbols.remove(symbol);
                    }
                    _criteria = _criteria.copyWith(selectedSymbols: newSymbols);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildConfidenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum Confidence: ${(_criteria.minConfidence * 100).toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _criteria.minConfidence,
          onChanged: (value) {
            setState(() {
              _criteria = _criteria.copyWith(minConfidence: value);
            });
          },
          min: 0,
          max: 1,
          divisions: 20,
          label: '${(_criteria.minConfidence * 100).round()}%',
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0%', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('100%', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time Range',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            _criteria.timeRange != null
                ? '${_formatDate(_criteria.timeRange!.start)} - ${_formatDate(_criteria.timeRange!.end)}'
                : 'All time',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_criteria.timeRange != null)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _criteria = _criteria.copyWith(timeRange: null);
                    });
                  },
                  icon: const Icon(Icons.clear),
                ),
              IconButton(
                onPressed: _selectTimeRange,
                icon: const Icon(Icons.date_range),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pattern Duration: ${_criteria.minDurationMultiplier > 0 ? "${_criteria.minDurationMultiplier}+ days" : "Any length"}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _criteria.minDurationMultiplier.toDouble(),
          onChanged: (value) {
            setState(() {
              _criteria =
                  _criteria.copyWith(minDurationMultiplier: value.round());
            });
          },
          min: 0,
          max: 200,
          divisions: 20,
          label: _criteria.minDurationMultiplier > 0
              ? '${_criteria.minDurationMultiplier} days'
              : 'No filter',
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0 days', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('200 days',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _criteria = _criteria.copyWith(minDurationMultiplier: 50);
                });
              },
              child: const Text('50 Days (Recommended)'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _criteria = _criteria.copyWith(minDurationMultiplier: 0);
                });
              },
              child: const Text('Clear'),
            ),
          ],
        ),
        if (_criteria.minDurationMultiplier > 0)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              'Showing patterns that lasted ${_criteria.minDurationMultiplier}+ days',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
              ),
            ),
          ),
      ],
    );
  }

  void _selectTimeRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _criteria.timeRange,
    );

    if (picked != null) {
      setState(() {
        _criteria = _criteria.copyWith(timeRange: picked);
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _resetFilters() {
    setState(() {
      _criteria = const PatternFilterCriteria();
    });
  }

  String _getFullSortLabel(SortOption option) {
    switch (option) {
      case SortOption.newestFirst:
        return 'Newest First';
      case SortOption.oldestFirst:
        return 'Oldest First';
      case SortOption.highestConfidence:
        return 'Highest Confidence';
      case SortOption.lowestConfidence:
        return 'Lowest Confidence';
    }
  }

  String _getDirectionLabel(PatternDirection direction) {
    switch (direction) {
      case PatternDirection.bullish:
        return 'Bullish ↗️';
      case PatternDirection.bearish:
        return 'Bearish ↘️';
      case PatternDirection.breakout:
        return 'Breakout ↔️';
    }
  }
}
