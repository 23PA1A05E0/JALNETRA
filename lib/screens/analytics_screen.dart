import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/manual_data_provider.dart';
import '../providers/water_well_depth_provider.dart';
import '../widgets/water_level_chart_painter.dart';
import '../widgets/water_well_depth_chart.dart';

/// Analytics screen for detailed groundwater data analysis
class AnalyticsScreen extends ConsumerStatefulWidget {
  final String? selectedCity;
  final String? selectedDistrict;
  final String? selectedState;

  const AnalyticsScreen({
    super.key,
    this.selectedCity,
    this.selectedDistrict,
    this.selectedState,
  });

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _selectedTimeRange = '30 Days';
  String _selectedChartType = 'Line Chart';

  @override
  Widget build(BuildContext context) {
    final isTadepalligudem = widget.selectedCity == 'Tadepalligudem' && 
                           widget.selectedDistrict == 'West Godavari';

    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics - ${widget.selectedCity ?? 'Unknown'}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: GoRouter.of(context).canPop()
          ? IconButton(
              icon: Icon(
                Theme.of(context).platform == TargetPlatform.iOS
                  ? Icons.arrow_back_ios
                  : Icons.arrow_back,
              ),
              onPressed: () {
                context.pop();
              },
              tooltip: 'Back',
            )
          : null,
        actions: [
          IconButton(
            onPressed: () {
              ref.read(refreshDataProvider)();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
          IconButton(
            onPressed: () {
              context.push('/debug');
            },
            icon: const Icon(Icons.settings_applications),
            tooltip: 'Debug Tools',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Info Card
            _buildLocationInfoCard(),
            const SizedBox(height: 20),

            // Chart Controls
            _buildChartControls(),
            const SizedBox(height: 20),

            // Analytics Content
            if (isTadepalligudem) ...[
              _buildRealDataAnalytics(),
              const SizedBox(height: 20),
              _buildWaterWellDepthSection(),
            ] else ...[
              _buildMockAnalytics(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfoCard() {
    return Card(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.location_on,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.selectedCity ?? 'Unknown City'}, ${widget.selectedDistrict ?? 'Unknown District'}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.selectedState ?? 'Unknown State',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Real-time Data Available',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartControls() {
    return Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chart Controls',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedTimeRange,
                    decoration: const InputDecoration(
                      labelText: 'Time Range',
                      border: OutlineInputBorder(),
                    ),
                    items: ['7 Days', '30 Days']
                        .map((range) => DropdownMenuItem(
                              value: range,
                              child: Text(range),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTimeRange = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedChartType,
                    decoration: const InputDecoration(
                      labelText: 'Chart Type',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Line Chart', 'Bar Chart']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedChartType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealDataAnalytics() {
    return Consumer(
      builder: (context, ref, child) {
        final stationData = ref.watch(stationDataProvider);
        
        return stationData.when(
          data: (data) {
            if (data == null) {
              return _buildNoDataCard();
            }
            
            return Column(
              children: [
                // Main Data Cards
                _buildDataCards(data),
                const SizedBox(height: 20),
                
                // Historical Chart
                _buildHistoricalChart(data),
                const SizedBox(height: 20),
                
                // Statistics Section
                _buildStatisticsSection(data),
                const SizedBox(height: 20),
                
                // Station Information
                _buildStationInformation(data),
              ],
            );
          },
          loading: () => _buildLoadingCard(),
          error: (error, stack) => _buildErrorCard(error),
        );
      },
    );
  }

  Widget _buildMockAnalytics() {
    return Card(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Water Analytics for ${widget.selectedCity}, ${widget.selectedDistrict}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Mock Analytics Cards
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsCard(
                    'Average Water Level',
                    '12.5 m',
                    Icons.water_drop,
                    Colors.blue,
                    'Last 30 days',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnalyticsCard(
                    'Trend',
                    'Decreasing',
                    Icons.trending_down,
                    Colors.red,
                    '0.2m/month',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsCard(
                    'Water Quality',
                    'Good',
                    Icons.check_circle,
                    Colors.green,
                    'Safe for drinking',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnalyticsCard(
                    'Recharge Status',
                    'Moderate',
                    Icons.water,
                    Colors.teal,
                    'Seasonal variation',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Mock Chart Placeholder
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mock Chart Data',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Real-time data available for Tadepalligudem',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCards(Map<String, dynamic> data) {
    return Row(
      children: [
        Expanded(
          child: _buildAnalyticsCard(
            'Current Water Level',
            '${data['latestWaterLevel']?.toStringAsFixed(2) ?? 'N/A'} ${data['waterLevelUnit'] ?? 'm'}',
            Icons.water_drop,
            Colors.blue,
            'Last updated: ${data['lastUpdated'] ?? 'N/A'}',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAnalyticsCard(
            'Data Points',
            '${data['dataPoints'] ?? 0}',
            Icons.analytics,
            Colors.orange,
            'Total measurements',
          ),
        ),
      ],
    );
  }

  Widget _buildHistoricalChart(Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Historical Water Level Trend',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: Consumer(
                builder: (context, ref, child) {
                  final historicalData = ref.watch(historicalDataProvider({
                    'limit': _getLimitFromTimeRange(_selectedTimeRange),
                  }));
                  
                  return historicalData.when(
                    data: (chartData) {
                      if (chartData.isEmpty) {
                        return const Center(
                          child: Text('No historical data available'),
                        );
                      }
                      
                      return CustomPaint(
                        painter: WaterLevelChartPainter(chartData),
                        size: const Size(double.infinity, 300),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => Center(
                      child: Text('Chart error: $error'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Well Depth', '${data['wellDepth']?.toStringAsFixed(1) ?? 'N/A'} m', Colors.green),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard('Aquifer Type', data['aquiferType'] ?? 'N/A', Colors.teal),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Well Type', data['wellType'] ?? 'N/A', Colors.indigo),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard('Data Source', data['dataSource'] ?? 'N/A', Colors.purple),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationInformation(Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Station Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Station Code', data['stationCode'] ?? 'N/A'),
            _buildInfoRow('Station Name', data['stationName'] ?? 'N/A'),
            _buildInfoRow('District', data['district'] ?? 'N/A'),
            _buildInfoRow('State', data['state'] ?? 'N/A'),
            _buildInfoRow('Coordinates', '${data['latitude'] ?? 'N/A'}, ${data['longitude'] ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.surface,
      child: const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No data available'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.surface,
      child: const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading analytics data...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(Object error) {
    return Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load data'),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(refreshDataProvider)();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaterWellDepthSection() {
    return Column(
      children: [
        // Section Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.water_drop,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Water Well Depth Analysis',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'Historical trends and ML predictions for well depth monitoring',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Well Depth Chart
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.timeline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Well Depth Trends & ML Predictions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                WaterWellDepthChart(
                  historicalDays: _getDaysFromTimeRange(_selectedTimeRange),
                  predictionDays: 7,
                  chartType: _selectedChartType,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // ML Model Performance
        const MLModelPerformanceWidget(),
        const SizedBox(height: 16),
        
        // Data Summary Cards
        _buildWellDepthSummaryCards(),
      ],
    );
  }
  
  Widget _buildWellDepthSummaryCards() {
    return Consumer(
      builder: (context, ref, child) {
        final trend7Days = ref.watch(wellDepthTrendProvider(7));
        final trend30Days = ref.watch(wellDepthTrendProvider(30));
        
        return Row(
          children: [
            Expanded(
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: Colors.blue,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '7-Day Trend',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      trend7Days.when(
                        data: (trend) => Text(
                          '${trend['change']}m',
                          style: TextStyle(
                            color: trend['change'] > 0 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        loading: () => const Text('...'),
                        error: (error, stack) => const Text('Error'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '30-Day Trend',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      trend30Days.when(
                        data: (trend) => Text(
                          '${trend['change']}m',
                          style: TextStyle(
                            color: trend['change'] > 0 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        loading: () => const Text('...'),
                        error: (error, stack) => const Text('Error'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.psychology,
                        color: Colors.purple,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ML Accuracy',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Consumer(
                        builder: (context, ref, child) {
                          final performance = ref.watch(mlModelPerformanceProvider);
                          return performance.when(
                            data: (perf) => Text(
                              '${(perf['accuracy'] * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            loading: () => const Text('...'),
                            error: (error, stack) => const Text('Error'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  int _getDaysFromTimeRange(String timeRange) {
    switch (timeRange) {
      case '7 Days':
        return 7;
      case '30 Days':
        return 30;
      default:
        return 30;
    }
  }
  
  int _getLimitFromTimeRange(String timeRange) {
    switch (timeRange) {
      case '7 Days':
        return 7;
      case '30 Days':
        return 30;
      default:
        return 30;
    }
  }
}
