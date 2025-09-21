import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/traffic_signal.dart';
import '../providers/traffic_signal_provider.dart';

/// Traffic Signal Widget for displaying regional groundwater status
class TrafficSignalWidget extends ConsumerWidget {
  final String? regionId;
  final bool showDetails;
  final bool showRecommendations;
  final VoidCallback? onTap;

  const TrafficSignalWidget({
    super.key,
    this.regionId,
    this.showDetails = true,
    this.showRecommendations = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (regionId != null) {
      return _buildRegionSpecificSignal(context, ref);
    } else {
      return _buildGeneralSignal(context, ref);
    }
  }

  Widget _buildRegionSpecificSignal(BuildContext context, WidgetRef ref) {
    final trafficSignalAsync = ref.watch(trafficSignalForRegionProvider(regionId!));

    return trafficSignalAsync.when(
      data: (signal) {
        if (signal == null) {
          return _buildNoDataWidget(context);
        }
        return _buildTrafficSignalCard(context, signal);
      },
      loading: () => _buildLoadingWidget(context),
      error: (error, stack) => _buildErrorWidget(context, error.toString()),
    );
  }

  Widget _buildGeneralSignal(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(trafficSignalSummaryProvider);

    return _buildSummaryTrafficSignalCard(context, summaryAsync);
  }

  Widget _buildTrafficSignalCard(BuildContext context, TrafficSignal signal) {
    return Card(
      elevation: 6,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, signal),
              const SizedBox(height: 16),
              _buildTrafficLight(context, signal),
              if (showDetails) ...[
                const SizedBox(height: 16),
                _buildDetails(context, signal),
              ],
              if (showRecommendations && signal.recommendations.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildRecommendations(context, signal),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTrafficSignalCard(BuildContext context, Map<String, dynamic> summary) {
    final criticalRegions = summary['criticalRegions'] as int;
    final monitoringRegions = summary['monitoringRegions'] as int;

    // Determine overall status based on critical regions
    TrafficSignalLevel overallLevel;
    if (criticalRegions > 0) {
      overallLevel = TrafficSignalLevel.critical;
    } else if (monitoringRegions > 0) {
      overallLevel = TrafficSignalLevel.warning;
    } else {
      overallLevel = TrafficSignalLevel.good;
    }

    return Card(
      elevation: 6,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryHeader(context, overallLevel),
              const SizedBox(height: 16),
              _buildTrafficLight(context, null, level: overallLevel),
              const SizedBox(height: 16),
              _buildSummaryDetails(context, summary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TrafficSignal signal) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: signal.level.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.traffic,
            color: signal.level.color,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                signal.regionName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: signal.level.color,
                ),
              ),
              Text(
                '${signal.district}, ${signal.state}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: signal.level.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: signal.level.color.withOpacity(0.3)),
          ),
          child: Text(
            signal.level.status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: signal.level.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader(BuildContext context, TrafficSignalLevel level) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: level.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.traffic,
            color: level.color,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Regional Water Status Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: level.color,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: level.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: level.color.withOpacity(0.3)),
          ),
          child: Text(
            level.status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: level.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrafficLight(BuildContext context, TrafficSignal? signal, {TrafficSignalLevel? level}) {
    final signalLevel = level ?? signal?.level ?? TrafficSignalLevel.good;
    
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.grey[600]!, width: 3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTrafficLightBulb(Colors.red, signalLevel == TrafficSignalLevel.critical),
                _buildTrafficLightBulb(Colors.orange, signalLevel == TrafficSignalLevel.warning),
                _buildTrafficLightBulb(const Color(0xFF33B864), signalLevel == TrafficSignalLevel.good),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            signalLevel.status,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: signalLevel.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            signalLevel.description,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficLightBulb(Color color, bool isActive) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isActive ? color : Colors.grey[400],
        shape: BoxShape.circle,
        boxShadow: isActive ? [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ] : null,
      ),
    );
  }

  Widget _buildDetails(BuildContext context, TrafficSignal signal) {
    return Column(
      children: [
        _buildDetailRow(context, 'Average Depth', signal.formattedDepth, Icons.trending_down),
        _buildDetailRow(context, 'Yearly Change', signal.formattedYearlyChange, Icons.trending_up),
        _buildDetailRow(context, 'Station Coverage', signal.formattedStationCoverage, Icons.location_on),
        _buildDetailRow(context, 'Risk Score', '${(signal.riskScore * 100).toStringAsFixed(1)}%', Icons.warning),
        _buildDetailRow(context, 'Last Updated', _formatDateTime(signal.lastUpdated), Icons.access_time),
      ],
    );
  }

  Widget _buildSummaryDetails(BuildContext context, Map<String, dynamic> summary) {
    return Column(
      children: [
        _buildSummaryRow(context, 'Total Regions', '${summary['totalRegions']}', Icons.location_city),
        _buildSummaryRow(context, 'Critical Regions', '${summary['criticalRegions']}', Icons.warning, Colors.red),
        _buildSummaryRow(context, 'Warning Regions', '${summary['warningRegions']}', Icons.trending_up, Colors.orange),
        _buildSummaryRow(context, 'Good Regions', '${summary['goodRegions']}', Icons.check_circle, const Color(0xFF33B864)),
        _buildSummaryRow(context, 'Active Stations', '${summary['activeStations']}/${summary['totalStations']}', Icons.sensors),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, IconData icon, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context, TrafficSignal signal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...signal.recommendations.map((recommendation) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return Card(
      elevation: 6,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    return Card(
      elevation: 6,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Traffic Signal',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget(BuildContext context) {
    return Card(
      elevation: 6,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.grey[600],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No Traffic Signal Data',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Traffic signal data is not available for this region.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

/// Traffic Signal List Widget for displaying multiple traffic signals
class TrafficSignalListWidget extends ConsumerWidget {
  final List<TrafficSignal>? signals;
  final bool showFilters;
  final Function(TrafficSignal)? onSignalTap;

  const TrafficSignalListWidget({
    super.key,
    this.signals,
    this.showFilters = true,
    this.onSignalTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signalsAsync = signals != null 
        ? AsyncValue.data(signals!)
        : ref.watch(filteredTrafficSignalsProvider);

    return Column(
      children: [
        if (showFilters) _buildFilterSection(context, ref),
        Expanded(
          child: signalsAsync.when(
            data: (signalsList) => _buildSignalsList(context, signalsList),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorWidget(context, error.toString()),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(trafficSignalFilterStateProvider);
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Traffic Signals',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip(context, ref, 'All Levels', null, filterState.level == null),
                _buildFilterChip(context, ref, 'Good', TrafficSignalLevel.good, filterState.level == TrafficSignalLevel.good),
                _buildFilterChip(context, ref, 'Warning', TrafficSignalLevel.warning, filterState.level == TrafficSignalLevel.warning),
                _buildFilterChip(context, ref, 'Critical', TrafficSignalLevel.critical, filterState.level == TrafficSignalLevel.critical),
                _buildFilterChip(context, ref, 'Requires Action', null, filterState.requiresAction == true),
                _buildFilterChip(context, ref, 'Requires Monitoring', null, filterState.requiresMonitoring == true),
              ],
            ),
            if (filterState.hasActiveFilters) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(trafficSignalFilterStateProvider.notifier).state = filterState.clearFilters();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, String label, TrafficSignalLevel? level, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        final currentState = ref.read(trafficSignalFilterStateProvider);
        
        if (level != null) {
          ref.read(trafficSignalFilterStateProvider.notifier).state = currentState.copyWith(
            level: selected ? level : null,
          );
        } else if (label == 'Requires Action') {
          ref.read(trafficSignalFilterStateProvider.notifier).state = currentState.copyWith(
            requiresAction: selected ? true : null,
          );
        } else if (label == 'Requires Monitoring') {
          ref.read(trafficSignalFilterStateProvider.notifier).state = currentState.copyWith(
            requiresMonitoring: selected ? true : null,
          );
        } else if (label == 'All Levels') {
          ref.read(trafficSignalFilterStateProvider.notifier).state = currentState.copyWith(
            level: null,
          );
        }
      },
    );
  }

  Widget _buildSignalsList(BuildContext context, List<TrafficSignal> signals) {
    if (signals.isEmpty) {
      return const Center(
        child: Text('No traffic signals found'),
      );
    }

    return ListView.builder(
      itemCount: signals.length,
      itemBuilder: (context, index) {
        final signal = signals[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TrafficSignalWidget(
            regionId: signal.regionId,
            showDetails: true,
            showRecommendations: false,
            onTap: () => onSignalTap?.call(signal),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Traffic Signals',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
