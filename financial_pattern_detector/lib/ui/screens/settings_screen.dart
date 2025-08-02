import 'package:flutter/material.dart';
import '../../managers/app_manager.dart';
import '../../models/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  final Function(AppSettings) onSettingsChanged;

  const SettingsScreen({super.key, required this.onSettingsChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppManager _appManager = AppManager();
  final TextEditingController _emailController = TextEditingController();

  AppSettings? _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _appManager.getSettings();
      setState(() {
        _settings = settings;
        _emailController.text = settings.emailAddress ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_settings == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: Text('Failed to load settings')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Analysis Settings',
              children: [
                _buildTrackingIntervalSetting(),
                const SizedBox(height: 16),
                _buildDataPeriodSetting(),
                const SizedBox(height: 16),
                _buildPatternThresholdSetting(),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Alert Settings',
              children: [
                _buildAlertMethodSetting(),
                const SizedBox(height: 16),
                _buildNotificationSettings(),
                const SizedBox(height: 16),
                _buildEmailSettings(),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Watchlist',
              children: [_buildWatchlistManagement()],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Data Management',
              children: [
                _buildDataCleanupButton(),
                const SizedBox(height: 16),
                _buildResetSettingsButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingIntervalSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tracking Interval',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        const Text(
          'How often to check for new patterns',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<DataPeriod>(
          value: _settings!.trackingInterval,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: DataPeriod.values.map((period) {
            return DropdownMenuItem(
              value: period,
              child: Text(period.displayName),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _settings = _settings!.copyWith(trackingInterval: value);
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildDataPeriodSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Period for Analysis',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        const Text(
          'Time frame of data to analyze for patterns',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<DataPeriod>(
          value: _settings!.dataPeriod,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: DataPeriod.values.map((period) {
            return DropdownMenuItem(
              value: period,
              child: Text(period.displayName),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _settings = _settings!.copyWith(dataPeriod: value);
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildPatternThresholdSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pattern Match Threshold: ${(_settings!.patternMatchThreshold * 100).toStringAsFixed(0)}%',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        const Text(
          'Minimum confidence score to trigger alerts',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _settings!.patternMatchThreshold,
          min: 0.5,
          max: 0.95,
          divisions: 9,
          label:
              '${(_settings!.patternMatchThreshold * 100).toStringAsFixed(0)}%',
          onChanged: (value) {
            setState(() {
              _settings = _settings!.copyWith(patternMatchThreshold: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildAlertMethodSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alert Method',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        ...AlertMethod.values.map((method) {
          return RadioListTile<AlertMethod>(
            title: Text(_getAlertMethodDisplayName(method)),
            value: method,
            groupValue: _settings!.alertMethod,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _settings = _settings!.copyWith(alertMethod: value);
                });
              }
            },
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Enable Notifications'),
          subtitle: const Text('Show macOS notifications for pattern alerts'),
          value: _settings!.enableNotifications,
          onChanged: (value) {
            setState(() {
              _settings = _settings!.copyWith(enableNotifications: value);
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildEmailSettings() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Enable Email Alerts'),
          subtitle: const Text('Send email notifications for pattern alerts'),
          value: _settings!.enableEmailAlerts,
          onChanged: (value) {
            setState(() {
              _settings = _settings!.copyWith(enableEmailAlerts: value);
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        if (_settings!.enableEmailAlerts) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              _settings = _settings!.copyWith(
                emailAddress: value.isEmpty ? null : value,
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildWatchlistManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Symbols (${_settings!.watchlist.length})',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            TextButton.icon(
              onPressed: _addSymbolToWatchlist,
              icon: const Icon(Icons.add),
              label: const Text('Add Symbol'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_settings!.watchlist.isEmpty)
          const Text(
            'No symbols in watchlist',
            style: TextStyle(color: Colors.grey),
          )
        else
          Wrap(
            spacing: 8,
            children: _settings!.watchlist.map((symbol) {
              return Chip(
                label: Text(symbol),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeSymbolFromWatchlist(symbol),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDataCleanupButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _cleanupOldData,
        icon: const Icon(Icons.cleaning_services),
        label: const Text('Cleanup Old Data'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildResetSettingsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _resetSettings,
        icon: const Icon(Icons.restore),
        label: const Text('Reset to Defaults'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  String _getAlertMethodDisplayName(AlertMethod method) {
    switch (method) {
      case AlertMethod.notification:
        return 'Notifications Only';
      case AlertMethod.email:
        return 'Email Only';
      case AlertMethod.both:
        return 'Both Notifications and Email';
    }
  }

  void _addSymbolToWatchlist() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Symbol'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter stock symbol (e.g., AAPL)',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final symbol = controller.text.trim().toUpperCase();
              if (symbol.isNotEmpty && !_settings!.watchlist.contains(symbol)) {
                setState(() {
                  final newWatchlist = [..._settings!.watchlist, symbol];
                  _settings = _settings!.copyWith(watchlist: newWatchlist);
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeSymbolFromWatchlist(String symbol) {
    setState(() {
      final newWatchlist = _settings!.watchlist
          .where((s) => s != symbol)
          .toList();
      _settings = _settings!.copyWith(watchlist: newWatchlist);
    });
  }

  Future<void> _cleanupOldData() async {
    try {
      await _appManager.cleanupOldData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Old data cleaned up successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cleanup data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to defaults?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _settings = AppSettings();
        _emailController.text = '';
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    try {
      await widget.onSettingsChanged(_settings!);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
