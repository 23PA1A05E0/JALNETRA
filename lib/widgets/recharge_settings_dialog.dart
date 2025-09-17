import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/station.dart';
import '../models/recharge_estimate.dart';
import '../providers/stations_provider.dart';

/// Dialog for configuring recharge settings
class RechargeSettingsDialog extends ConsumerStatefulWidget {
  final Station station;

  const RechargeSettingsDialog({
    Key? key,
    required this.station,
  }) : super(key: key);

  @override
  ConsumerState<RechargeSettingsDialog> createState() => _RechargeSettingsDialogState();
}

class _RechargeSettingsDialogState extends ConsumerState<RechargeSettingsDialog> {
  late double _targetYield;
  late RechargeMethod _preferredMethod;
  late bool _autoAdjust;
  late bool _notificationsEnabled;
  late double _minYieldThreshold;
  late double _maxYieldThreshold;
  late double _temperatureThreshold;
  late double _phThreshold;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _targetYield = widget.station.targetYield;
    _preferredMethod = RechargeMethod.waterLevelChange;
    _autoAdjust = true;
    _notificationsEnabled = true;
    _minYieldThreshold = 50.0;
    _maxYieldThreshold = 200.0;
    _temperatureThreshold = 30.0;
    _phThreshold = 6.5;
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Recharge Settings - ${widget.station.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target yield
            Text(
              'Target Yield (L/h)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Slider(
              value: _targetYield,
              min: 0.0,
              max: 500.0,
              divisions: 50,
              label: _targetYield.toStringAsFixed(0),
              onChanged: (value) {
                setState(() {
                  _targetYield = value;
                });
              },
            ),
            Text(
              '${_targetYield.toStringAsFixed(0)} L/h',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Preferred method
            Text(
              'Preferred Method',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            DropdownButton<RechargeMethod>(
              value: _preferredMethod,
              isExpanded: true,
              items: RechargeMethod.values.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(_getMethodDisplayName(method)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _preferredMethod = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Auto adjust
            SwitchListTile(
              title: const Text('Auto Adjust'),
              subtitle: const Text('Automatically adjust based on conditions'),
              value: _autoAdjust,
              onChanged: (value) {
                setState(() {
                  _autoAdjust = value;
                });
              },
            ),

            // Notifications
            SwitchListTile(
              title: const Text('Notifications'),
              subtitle: const Text('Receive alerts for this station'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Thresholds section
            Text(
              'Alert Thresholds',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),

            // Min yield threshold
            Text('Minimum Yield Threshold (L/h)'),
            Slider(
              value: _minYieldThreshold,
              min: 0.0,
              max: 100.0,
              divisions: 20,
              label: _minYieldThreshold.toStringAsFixed(0),
              onChanged: (value) {
                setState(() {
                  _minYieldThreshold = value;
                });
              },
            ),

            // Max yield threshold
            Text('Maximum Yield Threshold (L/h)'),
            Slider(
              value: _maxYieldThreshold,
              min: 100.0,
              max: 500.0,
              divisions: 20,
              label: _maxYieldThreshold.toStringAsFixed(0),
              onChanged: (value) {
                setState(() {
                  _maxYieldThreshold = value;
                });
              },
            ),

            // Temperature threshold
            Text('Temperature Threshold (°C)'),
            Slider(
              value: _temperatureThreshold,
              min: 0.0,
              max: 50.0,
              divisions: 25,
              label: _temperatureThreshold.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _temperatureThreshold = value;
                });
              },
            ),

            // pH threshold
            Text('pH Threshold'),
            Slider(
              value: _phThreshold,
              min: 4.0,
              max: 10.0,
              divisions: 30,
              label: _phThreshold.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _phThreshold = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Notes
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add notes about this station...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          child: const Text('Save'),
        ),
      ],
    );
  }

  /// Get display name for recharge method
  String _getMethodDisplayName(RechargeMethod method) {
    switch (method) {
      case RechargeMethod.waterLevelChange:
        return 'Water Level Change';
      case RechargeMethod.temperatureCorrelation:
        return 'Temperature Correlation';
      case RechargeMethod.phVariation:
        return 'pH Variation';
      case RechargeMethod.machineLearning:
        return 'Machine Learning';
      case RechargeMethod.manualInput:
        return 'Manual Input';
    }
  }

  /// Save settings
  void _saveSettings() {
    // TODO: Implement actual save logic
    // This would typically involve:
    // 1. Creating a RechargeConfig object
    // 2. Calling the API service to update the station config
    // 3. Updating the local state
    
    final config = RechargeConfig(
      stationId: widget.station.id,
      targetYield: _targetYield,
      preferredMethod: _preferredMethod,
      thresholds: {
        'min_yield': _minYieldThreshold,
        'max_yield': _maxYieldThreshold,
        'temperature': _temperatureThreshold,
        'ph': _phThreshold,
      },
      autoAdjust: _autoAdjust,
      notificationsEnabled: _notificationsEnabled,
      minYieldThreshold: _minYieldThreshold,
      maxYieldThreshold: _maxYieldThreshold,
      temperatureThreshold: _temperatureThreshold,
      phThreshold: _phThreshold,
      notes: _notesController.text,
    );

    // Update the station in the provider
    ref.read(stationsProvider.notifier).updateStationStatus(
      widget.station.id,
      widget.station.status,
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }
}
