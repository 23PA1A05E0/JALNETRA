import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

/// Settings screen for app configuration
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  String _mapProvider = 'Google Maps';
  String _apiBaseUrl = 'https://api.jalnetra.com/v1';
  String _apiKey = 'your-api-key-here';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Settings Section
          _buildSectionHeader('App Settings'),
          Card(
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final themeMode = ref.watch(themeModeProvider);
                    final themeNotifier = ref.read(themeModeProvider.notifier);
                    
                    return SwitchListTile(
                      title: const Text('Dark Mode'),
                      subtitle: Text('Current: ${themeNotifier.themeModeName}'),
                      value: themeMode == ThemeMode.dark,
                      onChanged: (value) {
                        themeNotifier.toggleTheme();
                      },
                    );
                  },
                ),
                SwitchListTile(
                  title: const Text('Notifications'),
                  subtitle: const Text('Receive push notifications'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Location Services'),
                  subtitle: const Text('Allow location access for maps'),
                  value: _locationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _locationEnabled = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Map Settings Section
          _buildSectionHeader('Map Settings'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Map Provider'),
                  subtitle: Text(_mapProvider),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _showMapProviderDialog,
                ),
                ListTile(
                  title: const Text('Default Zoom Level'),
                  subtitle: const Text('12'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Implement zoom level settings
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // API Settings Section
          _buildSectionHeader('API Configuration'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Base URL'),
                  subtitle: Text(_apiBaseUrl),
                  trailing: const Icon(Icons.edit),
                  onTap: _showApiUrlDialog,
                ),
                ListTile(
                  title: const Text('API Key'),
                  subtitle: Text(_apiKey.length > 10 ? '${_apiKey.substring(0, 10)}...' : _apiKey),
                  trailing: const Icon(Icons.edit),
                  onTap: _showApiKeyDialog,
                ),
                ListTile(
                  title: const Text('Test Connection'),
                  subtitle: const Text('Verify API connectivity'),
                  trailing: const Icon(Icons.network_check),
                  onTap: _testApiConnection,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Data Management Section
          _buildSectionHeader('Data Management'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Clear Cache'),
                  subtitle: const Text('Remove cached data'),
                  trailing: const Icon(Icons.delete_outline),
                  onTap: _clearCache,
                ),
                ListTile(
                  title: const Text('Export Data'),
                  subtitle: const Text('Export station data'),
                  trailing: const Icon(Icons.download),
                  onTap: _exportData,
                ),
                ListTile(
                  title: const Text('Sync Data'),
                  subtitle: const Text('Force data synchronization'),
                  trailing: const Icon(Icons.sync),
                  onTap: _syncData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // About Section
          _buildSectionHeader('About'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  title: Text('App Version'),
                  subtitle: Text('1.0.0'),
                ),
                const ListTile(
                  title: Text('Build Number'),
                  subtitle: Text('1'),
                ),
                ListTile(
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Open privacy policy
                  },
                ),
                ListTile(
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Open terms of service
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Reset Button
          Center(
            child: ElevatedButton.icon(
              onPressed: _resetSettings,
              icon: const Icon(Icons.restore),
              label: const Text('Reset to Defaults'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// Show map provider selection dialog
  void _showMapProviderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Map Provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Google Maps'),
              subtitle: const Text('Default Google Maps'),
              value: 'Google Maps',
              groupValue: _mapProvider,
              onChanged: (value) {
                setState(() {
                  _mapProvider = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('OpenStreetMap'),
              subtitle: const Text('Open source alternative'),
              value: 'OpenStreetMap',
              groupValue: _mapProvider,
              onChanged: (value) {
                setState(() {
                  _mapProvider = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show API URL dialog
  void _showApiUrlDialog() {
    final controller = TextEditingController(text: _apiBaseUrl);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Base URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Base URL',
            hintText: 'https://api.jalnetra.com/v1',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _apiBaseUrl = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Show API key dialog
  void _showApiKeyDialog() {
    final controller = TextEditingController(text: _apiKey);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Key'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'API Key',
            hintText: 'Enter your API key',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _apiKey = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Test API connection
  void _testApiConnection() {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Testing connection...'),
          ],
        ),
      ),
    );

    // TODO: Implement actual API connection test
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection test completed'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  /// Clear cache
  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear all cached data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement cache clearing
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  /// Export data
  void _exportData() {
    // TODO: Implement data export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export started'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Sync data
  void _syncData() {
    // TODO: Implement data sync
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data sync started'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Reset settings
  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to defaults?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _notificationsEnabled = true;
                _locationEnabled = true;
                _mapProvider = 'Google Maps';
                _apiBaseUrl = 'https://api.jalnetra.com/v1';
                _apiKey = 'your-api-key-here';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}