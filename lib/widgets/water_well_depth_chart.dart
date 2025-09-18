import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../providers/water_well_depth_provider.dart';

/// Water Well Depth Chart Widget with ML Predictions
class WaterWellDepthChart extends ConsumerStatefulWidget {
  final int historicalDays;
  final int predictionDays;
  final String chartType;
  
  const WaterWellDepthChart({
    super.key,
    this.historicalDays = 30,
    this.predictionDays = 7,
    this.chartType = 'Line Chart',
  });

  @override
  ConsumerState<WaterWellDepthChart> createState() => _WaterWellDepthChartState();
}

class _WaterWellDepthChartState extends ConsumerState<WaterWellDepthChart> {
  @override
  Widget build(BuildContext context) {
    final wellDepthData = ref.watch(wellDepthDataProvider({
      'historicalDays': widget.historicalDays,
      'predictionDays': widget.predictionDays,
    }));
    
    final trendAnalysis = ref.watch(wellDepthTrendProvider(widget.historicalDays));
    
    return Column(
      children: [
        // Chart Header with Trend Info
        _buildChartHeader(trendAnalysis),
        const SizedBox(height: 16),
        
        // Main Chart
        SizedBox(
          height: 300,
          child: wellDepthData.when(
            data: (data) => _buildChart(data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Chart Error: $error'),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Chart Legend and Info
        _buildChartLegend(),
      ],
    );
  }
  
  Widget _buildChartHeader(AsyncValue<Map<String, dynamic>> trendAnalysis) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.water_drop,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Water Well Depth Trends',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                trendAnalysis.when(
                  data: (trend) => _buildTrendInfo(trend),
                  loading: () => const Text('Analyzing trends...'),
                  error: (error, stack) => Text('Trend analysis error: $error'),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(refreshWellDepthProvider)();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrendInfo(Map<String, dynamic> trend) {
    final change = trend['change'] as double;
    final changePercent = trend['changePercent'] as double;
    final trendDirection = trend['trendDirection'] as String;
    
    Color trendColor;
    IconData trendIcon;
    
    switch (trendDirection) {
      case 'increasing':
        trendColor = Colors.red;
        trendIcon = Icons.trending_up;
        break;
      case 'decreasing':
        trendColor = Colors.green;
        trendIcon = Icons.trending_down;
        break;
      default:
        trendColor = Colors.blue;
        trendIcon = Icons.trending_flat;
    }
    
    return Row(
      children: [
        Icon(trendIcon, color: trendColor, size: 16),
        const SizedBox(width: 4),
        Text(
          '${change.abs().toStringAsFixed(2)}m (${changePercent.abs().toStringAsFixed(1)}%)',
          style: TextStyle(
            color: trendColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'over ${trend['period']}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
  
  Widget _buildChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }
    
    // Separate historical and prediction data
    final historicalData = data.where((d) => d['dataType'] == 'historical').toList();
    final predictionData = data.where((d) => d['dataType'] == 'prediction').toList();
    
    return SfCartesianChart(
      title: ChartTitle(
        text: 'Well Depth: Historical vs ML Predictions',
        textStyle: Theme.of(context).textTheme.titleSmall,
      ),
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: 'point.x\nDepth: point.y m\nConfidence: point.confidence%',
      ),
      primaryXAxis: DateTimeAxis(
        title: AxisTitle(text: 'Date'),
        intervalType: DateTimeIntervalType.days,
        interval: widget.historicalDays > 7 ? 5 : 1,
        labelFormat: '{value:MMM dd}',
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Depth (m)'),
        minimum: _getMinDepth(data) - 2,
        maximum: _getMaxDepth(data) + 2,
        interval: 5,
        labelFormat: '{value}m',
      ),
      series: <CartesianSeries>[
        // Historical data line
        LineSeries<Map<String, dynamic>, DateTime>(
          name: 'Historical Data',
          dataSource: historicalData,
          xValueMapper: (data, index) => DateTime.parse(data['date']),
          yValueMapper: (data, index) => data['wellDepth'] as double,
          color: Colors.blue,
          width: 3,
          markerSettings: MarkerSettings(
            isVisible: true,
            height: 6,
            width: 6,
            color: Colors.blue,
          ),
          dataLabelSettings: DataLabelSettings(
            isVisible: false,
          ),
        ),
        
        // Prediction data line
        LineSeries<Map<String, dynamic>, DateTime>(
          name: 'ML Predictions',
          dataSource: predictionData,
          xValueMapper: (data, index) => DateTime.parse(data['date']),
          yValueMapper: (data, index) => data['wellDepth'] as double,
          color: Colors.orange,
          width: 3,
          dashArray: [5, 5], // Dashed line for predictions
          markerSettings: MarkerSettings(
            isVisible: true,
            height: 6,
            width: 6,
            color: Colors.orange,
            shape: DataMarkerType.circle,
          ),
          dataLabelSettings: DataLabelSettings(
            isVisible: false,
          ),
        ),
        
        // Specific ML Prediction series (highlighted)
        LineSeries<Map<String, dynamic>, DateTime>(
          name: 'Specific ML Output',
          dataSource: predictionData.where((d) => d['predictionType'] == 'specific_ml_output').toList(),
          xValueMapper: (data, index) => DateTime.parse(data['date']),
          yValueMapper: (data, index) => data['wellDepth'] as double,
          color: Colors.red,
          width: 4,
          markerSettings: MarkerSettings(
            isVisible: true,
            height: 8,
            width: 8,
            color: Colors.red,
            shape: DataMarkerType.diamond,
          ),
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
            labelAlignment: ChartDataLabelAlignment.top,
          ),
        ),
        
        // Confidence bands (if predictions exist)
        if (predictionData.isNotEmpty)
          AreaSeries<Map<String, dynamic>, DateTime>(
            name: 'Confidence Band',
            dataSource: predictionData,
            xValueMapper: (data, index) => DateTime.parse(data['date']),
            yValueMapper: (data, index) => data['wellDepth'] as double,
            color: Colors.orange.withOpacity(0.2),
            borderColor: Colors.transparent,
            borderWidth: 0,
          ),
      ],
    );
  }
  
  Widget _buildChartLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(
                'Historical',
                Colors.blue,
                Icons.timeline,
              ),
              _buildLegendItem(
                'ML Predictions',
                Colors.orange,
                Icons.psychology,
              ),
              _buildLegendItem(
                'Specific ML Output',
                Colors.red,
                Icons.diamond,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ML Model: v2.1.0 | Accuracy: 92% | Confidence: 60-95%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  double _getMinDepth(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 180.0;
    return data.map((d) => d['wellDepth'] as double).reduce((a, b) => a < b ? a : b);
  }
  
  double _getMaxDepth(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 220.0;
    return data.map((d) => d['wellDepth'] as double).reduce((a, b) => a > b ? a : b);
  }
}

/// ML Model Performance Widget
class MLModelPerformanceWidget extends ConsumerWidget {
  const MLModelPerformanceWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performance = ref.watch(mlModelPerformanceProvider);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'ML Model Performance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            performance.when(
              data: (perf) => _buildPerformanceMetrics(perf),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPerformanceMetrics(Map<String, dynamic> perf) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Accuracy',
                '${(perf['accuracy'] * 100).toStringAsFixed(1)}%',
                Colors.green,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'MAE',
                '${perf['mae']}m',
                Colors.blue,
                Icons.error_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'RMSE',
                '${perf['rmse']}m',
                Colors.orange,
                Icons.trending_up,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'F1 Score',
                '${(perf['f1Score'] * 100).toStringAsFixed(1)}%',
                Colors.purple,
                Icons.score,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Specific ML Prediction Display
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.diamond, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Specific ML Prediction',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Station: CGWHYD0511 | Date: 2025-09-18 | Predicted Level: -9.92m',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        Text(
          'Model: ${perf['modelVersion']} | Trained: ${perf['lastTrained']} | Data: ${perf['trainingDataSize']} days',
          style: const TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildMetricCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
