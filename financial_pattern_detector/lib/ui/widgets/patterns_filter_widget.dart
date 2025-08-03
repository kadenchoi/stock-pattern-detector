import 'package:flutter/material.dart';
import '../../models/pattern_detection.dart';

enum SortOption {
  newestFirst,
  oldestFirst,
  highestConfidence,
  lowestConfidence,
}

class PatternFilterCriteria {
  final Set<String> selectedSymbols;
  final Set<PatternDirection> selectedDirections;
  final DateTimeRange? timeRange;
  final SortOption sortOption;
  final double minConfidence;
  final int
      minDurationMultiplier; // Minimum duration as multiple of interval (e.g., 50 for 50 days)

  const PatternFilterCriteria({
    this.selectedSymbols = const {},
    this.selectedDirections = const {},
    this.timeRange,
    this.sortOption = SortOption.newestFirst,
    this.minConfidence = 0.0,
    this.minDurationMultiplier = 0, // 0 means no duration filter
  });

  PatternFilterCriteria copyWith({
    Set<String>? selectedSymbols,
    Set<PatternDirection>? selectedDirections,
    DateTimeRange? timeRange,
    SortOption? sortOption,
    double? minConfidence,
    int? minDurationMultiplier,
  }) {
    return PatternFilterCriteria(
      selectedSymbols: selectedSymbols ?? this.selectedSymbols,
      selectedDirections: selectedDirections ?? this.selectedDirections,
      timeRange: timeRange ?? this.timeRange,
      sortOption: sortOption ?? this.sortOption,
      minConfidence: minConfidence ?? this.minConfidence,
      minDurationMultiplier:
          minDurationMultiplier ?? this.minDurationMultiplier,
    );
  }

  bool get hasActiveFilters =>
      selectedSymbols.isNotEmpty ||
      selectedDirections.isNotEmpty ||
      timeRange != null ||
      minConfidence > 0.0 ||
      minDurationMultiplier > 0;
}

class PatternsFilterWidget extends StatefulWidget {
  final PatternFilterCriteria criteria;
  final List<PatternMatch> allPatterns;
  final Function(PatternFilterCriteria) onFiltersChanged;

  const PatternsFilterWidget({
    super.key,
    required this.criteria,
    required this.allPatterns,
    required this.onFiltersChanged,
  });

  @override
  State<PatternsFilterWidget> createState() => _PatternsFilterWidgetState();
}

class _PatternsFilterWidgetState extends State<PatternsFilterWidget> {
  late PatternFilterCriteria _criteria;
  late Set<String> _availableSymbols;

  @override
  void initState() {
    super.initState();
    _criteria = widget.criteria;
    _updateAvailableSymbols();
  }

  @override
  void didUpdateWidget(PatternsFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allPatterns != widget.allPatterns) {
      _updateAvailableSymbols();
    }
  }

  void _updateAvailableSymbols() {
    _availableSymbols = widget.allPatterns.map((p) => p.symbol).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters & Sort',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  if (_criteria.hasActiveFilters)
                    TextButton(
                      onPressed: _clearAllFilters,
                      child: const Text('Clear All'),
                    ),
                  IconButton(
                    onPressed: () => _showAdvancedFilters(context),
                    icon: const Icon(Icons.tune),
                    tooltip: 'Advanced Filters',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSortChip(),
                const SizedBox(width: 8),
                _buildDirectionFilter(),
                const SizedBox(width: 8),
                _buildSymbolFilter(),
                const SizedBox(width: 8),
                _buildTimeRangeFilter(),
                const SizedBox(width: 8),
                _buildConfidenceFilter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip() {
    return FilterChip(
      label: Text(_getSortLabel(_criteria.sortOption)),
      selected: true,
      onSelected: (_) => _showSortMenu(),
      avatar: const Icon(Icons.sort, size: 18),
    );
  }

  Widget _buildDirectionFilter() {
    final hasSelection = _criteria.selectedDirections.isNotEmpty;
    return FilterChip(
      label: Text(hasSelection
          ? 'Direction (${_criteria.selectedDirections.length})'
          : 'All Directions'),
      selected: hasSelection,
      onSelected: (_) => _showDirectionFilter(),
      avatar: Icon(
        hasSelection ? Icons.trending_up : Icons.swap_vert,
        size: 18,
      ),
    );
  }

  Widget _buildSymbolFilter() {
    final hasSelection = _criteria.selectedSymbols.isNotEmpty;
    return FilterChip(
      label: Text(hasSelection
          ? 'Symbols (${_criteria.selectedSymbols.length})'
          : 'All Symbols'),
      selected: hasSelection,
      onSelected: (_) => _showSymbolFilter(),
      avatar: Icon(
        hasSelection ? Icons.star : Icons.business,
        size: 18,
      ),
    );
  }

  Widget _buildTimeRangeFilter() {
    final hasSelection = _criteria.timeRange != null;
    return FilterChip(
      label: Text(hasSelection ? 'Custom Period' : 'All Time'),
      selected: hasSelection,
      onSelected: (_) => _showTimeRangeFilter(),
      avatar: Icon(
        hasSelection ? Icons.date_range : Icons.access_time,
        size: 18,
      ),
    );
  }

  Widget _buildConfidenceFilter() {
    final hasFilter = _criteria.minConfidence > 0.0;
    return FilterChip(
      label: Text(hasFilter
          ? 'Min ${(_criteria.minConfidence * 100).toStringAsFixed(0)}%'
          : 'All Confidence'),
      selected: hasFilter,
      onSelected: (_) => _showConfidenceFilter(),
      avatar: Icon(
        hasFilter ? Icons.star_rate : Icons.percent,
        size: 18,
      ),
    );
  }

  String _getSortLabel(SortOption option) {
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

  void _showSortMenu() {
    showMenu<SortOption>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: SortOption.values.map((option) {
        return PopupMenuItem<SortOption>(
          value: option,
          child: Row(
            children: [
              Icon(
                _criteria.sortOption == option
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(_getSortLabel(option)),
            ],
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null) {
        _updateCriteria(_criteria.copyWith(sortOption: value));
      }
    });
  }

  void _showDirectionFilter() {
    showDialog(
      context: context,
      builder: (context) => _DirectionFilterDialog(
        selectedDirections: _criteria.selectedDirections,
        onSelectionChanged: (directions) {
          _updateCriteria(_criteria.copyWith(selectedDirections: directions));
        },
      ),
    );
  }

  void _showSymbolFilter() {
    showDialog(
      context: context,
      builder: (context) => _SymbolFilterDialog(
        availableSymbols: _availableSymbols,
        selectedSymbols: _criteria.selectedSymbols,
        onSelectionChanged: (symbols) {
          _updateCriteria(_criteria.copyWith(selectedSymbols: symbols));
        },
      ),
    );
  }

  void _showTimeRangeFilter() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _criteria.timeRange,
    );

    if (picked != null) {
      _updateCriteria(_criteria.copyWith(timeRange: picked));
    } else if (_criteria.timeRange != null) {
      // If user cancels and there was a previous selection, offer to clear it
      final shouldClear = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear Time Filter?'),
          content: const Text('Do you want to remove the time range filter?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear Filter'),
            ),
          ],
        ),
      );

      if (shouldClear == true) {
        _updateCriteria(_criteria.copyWith(timeRange: null));
      }
    }
  }

  void _showConfidenceFilter() {
    showDialog(
      context: context,
      builder: (context) => _ConfidenceFilterDialog(
        currentMinConfidence: _criteria.minConfidence,
        onConfidenceChanged: (confidence) {
          _updateCriteria(_criteria.copyWith(minConfidence: confidence));
        },
      ),
    );
  }

  void _showAdvancedFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => _AdvancedFiltersSheet(
          criteria: _criteria,
          availableSymbols: _availableSymbols,
          onCriteriaChanged: (newCriteria) {
            _updateCriteria(newCriteria);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _clearAllFilters() {
    _updateCriteria(const PatternFilterCriteria());
  }

  void _updateCriteria(PatternFilterCriteria newCriteria) {
    setState(() {
      _criteria = newCriteria;
    });
    widget.onFiltersChanged(newCriteria);
  }
}

class _DirectionFilterDialog extends StatefulWidget {
  final Set<PatternDirection> selectedDirections;
  final Function(Set<PatternDirection>) onSelectionChanged;

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
      title: const Text('Filter by Direction'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: PatternDirection.values.map((direction) {
          return CheckboxListTile(
            title: Text(_getDirectionLabel(direction)),
            subtitle: Text(_getDirectionDescription(direction)),
            value: _selectedDirections.contains(direction),
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

  String _getDirectionDescription(PatternDirection direction) {
    switch (direction) {
      case PatternDirection.bullish:
        return 'Upward price movement expected';
      case PatternDirection.bearish:
        return 'Downward price movement expected';
      case PatternDirection.breakout:
        return 'Significant movement in either direction';
    }
  }
}

class _SymbolFilterDialog extends StatefulWidget {
  final Set<String> availableSymbols;
  final Set<String> selectedSymbols;
  final Function(Set<String>) onSelectionChanged;

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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedSymbols = Set.from(widget.selectedSymbols);
  }

  @override
  Widget build(BuildContext context) {
    final filteredSymbols = widget.availableSymbols
        .where((symbol) =>
            symbol.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList()
      ..sort();

    return AlertDialog(
      title: const Text('Filter by Symbols'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search symbols...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedSymbols.addAll(filteredSymbols);
                    });
                  },
                  child: const Text('Select All'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedSymbols.clear();
                    });
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: filteredSymbols.length,
                itemBuilder: (context, index) {
                  final symbol = filteredSymbols[index];
                  return CheckboxListTile(
                    title: Text(symbol),
                    value: _selectedSymbols.contains(symbol),
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
                },
              ),
            ),
          ],
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
  final Function(double) onConfidenceChanged;

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
      title: const Text('Minimum Confidence Filter'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Show patterns with at least ${(_minConfidence * 100).toStringAsFixed(0)}% confidence',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Slider(
            value: _minConfidence,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            label: '${(_minConfidence * 100).toStringAsFixed(0)}%',
            onChanged: (value) {
              setState(() {
                _minConfidence = value;
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _minConfidence = 0.0;
                  });
                },
                child: const Text('No Filter'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _minConfidence = 0.8;
                  });
                },
                child: const Text('High (80%+)'),
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
            widget.onConfidenceChanged(_minConfidence);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _AdvancedFiltersSheet extends StatefulWidget {
  final PatternFilterCriteria criteria;
  final Set<String> availableSymbols;
  final Function(PatternFilterCriteria) onCriteriaChanged;

  const _AdvancedFiltersSheet({
    required this.criteria,
    required this.availableSymbols,
    required this.onCriteriaChanged,
  });

  @override
  State<_AdvancedFiltersSheet> createState() => _AdvancedFiltersSheetState();
}

class _AdvancedFiltersSheetState extends State<_AdvancedFiltersSheet> {
  late PatternFilterCriteria _criteria;

  @override
  void initState() {
    super.initState();
    _criteria = widget.criteria;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Advanced Filters',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSortSection(),
                  const SizedBox(height: 24),
                  _buildDirectionSection(),
                  const SizedBox(height: 24),
                  _buildSymbolSection(),
                  const SizedBox(height: 24),
                  _buildTimeSection(),
                  const SizedBox(height: 24),
                  _buildConfidenceSection(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _criteria = const PatternFilterCriteria();
                    });
                  },
                  child: const Text('Reset All'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onCriteriaChanged(_criteria),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...SortOption.values.map((option) {
          return RadioListTile<SortOption>(
            title: Text(_getSortLabel(option)),
            value: option,
            groupValue: _criteria.sortOption,
            onChanged: (value) {
              setState(() {
                _criteria = _criteria.copyWith(sortOption: value);
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildDirectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pattern Direction',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...PatternDirection.values.map((direction) {
          return CheckboxListTile(
            title: Text(_getDirectionLabel(direction)),
            subtitle: Text(_getDirectionDescription(direction)),
            value: _criteria.selectedDirections.contains(direction),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Stock Symbols',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _criteria = _criteria.copyWith(selectedSymbols: <String>{});
                });
              },
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.availableSymbols.isEmpty)
          const Text(
            'No symbols available',
            style: TextStyle(color: Colors.grey),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.availableSymbols.map((symbol) {
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
    );
  }

  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time Period',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.date_range),
          title:
              Text(_criteria.timeRange == null ? 'All Time' : 'Custom Range'),
          subtitle: _criteria.timeRange == null
              ? const Text('No date filter applied')
              : Text(
                  '${_formatDate(_criteria.timeRange!.start)} - ${_formatDate(_criteria.timeRange!.end)}',
                ),
          trailing: _criteria.timeRange != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _criteria = _criteria.copyWith(timeRange: null);
                    });
                  },
                )
              : null,
          onTap: () async {
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
          },
        ),
      ],
    );
  }

  Widget _buildConfidenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confidence Filter',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.percent),
          title: Text(
              'Minimum Confidence: ${(_criteria.minConfidence * 100).toStringAsFixed(0)}%'),
          subtitle: Slider(
            value: _criteria.minConfidence,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            label: '${(_criteria.minConfidence * 100).toStringAsFixed(0)}%',
            onChanged: (value) {
              setState(() {
                _criteria = _criteria.copyWith(minConfidence: value);
              });
            },
          ),
        ),
      ],
    );
  }

  String _getSortLabel(SortOption option) {
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

  String _getDirectionDescription(PatternDirection direction) {
    switch (direction) {
      case PatternDirection.bullish:
        return 'Upward movement expected';
      case PatternDirection.bearish:
        return 'Downward movement expected';
      case PatternDirection.breakout:
        return 'Significant movement expected';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
