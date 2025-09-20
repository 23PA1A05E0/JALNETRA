import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Citizen Features Display Screen
/// Shows all available features for citizens in the JalNetra app
class CitizenFeaturesScreen extends ConsumerWidget {
  const CitizenFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Citizen Features'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue.shade600, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Citizen Dashboard Features',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Comprehensive groundwater monitoring and analysis tools for citizens',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Location Detection Features
            _buildFeatureSection(
              context,
              '📍 Location Detection & Analysis',
              'Advanced location-based groundwater monitoring',
              [
                _buildFeatureCard(
                  context,
                  'GPS Location Detection',
                  'Automatically detect your current location using GPS',
                  Icons.my_location,
                  Colors.green,
                  'Real-time GPS tracking with high accuracy',
                ),
                _buildFeatureCard(
                  context,
                  'Address Resolution',
                  'Convert GPS coordinates to readable addresses',
                  Icons.location_on,
                  Colors.blue,
                  'Reverse geocoding for better location understanding',
                ),
                _buildFeatureCard(
                  context,
                  'State/District/City Selection',
                  'Manual location selection with comprehensive Indian database',
                  Icons.map,
                  Colors.orange,
                  'All Indian states, districts, and cities available',
                ),
                _buildFeatureCard(
                  context,
                  'Location Permission Management',
                  'Smart permission handling for location access',
                  Icons.security,
                  Colors.purple,
                  'Secure and privacy-focused location handling',
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Groundwater Monitoring Features
            _buildFeatureSection(
              context,
              '🌊 Groundwater Monitoring',
              'Real-time groundwater level tracking and analysis',
              [
                _buildFeatureCard(
                  context,
                  'Average Depth Tracking',
                  'Monitor average groundwater depth in your area',
                  Icons.water_drop,
                  Colors.cyan,
                  'Real-time depth measurements with historical data',
                ),
                _buildFeatureCard(
                  context,
                  'Min/Max Depth Analysis',
                  'Track minimum and maximum depth variations',
                  Icons.trending_up,
                  Colors.red,
                  'Comprehensive depth range analysis',
                ),
                _buildFeatureCard(
                  context,
                  'Yearly Change Monitoring',
                  'Track groundwater level changes over time',
                  Icons.timeline,
                  Colors.amber,
                  'Long-term trend analysis and predictions',
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Forecasting Features
            _buildFeatureSection(
              context,
              '🔮 Forecasting & Predictions',
              'AI-powered groundwater level predictions',
              [
                _buildFeatureCard(
                  context,
                  'Monthly Forecast',
                  'Predict groundwater levels for the next month',
                  Icons.calendar_month,
                  Colors.indigo,
                  'Machine learning-based monthly predictions',
                ),
                _buildFeatureCard(
                  context,
                  'Daily Forecast',
                  'Get daily groundwater level predictions',
                  Icons.today,
                  Colors.pink,
                  'Short-term forecasting with high accuracy',
                ),
                _buildFeatureCard(
                  context,
                  'Trend Analysis',
                  'Analyze groundwater level trends and patterns',
                  Icons.analytics,
                  Colors.deepOrange,
                  'Advanced trend analysis with visualizations',
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Alert & Notification Features
            _buildFeatureSection(
              context,
              '🚨 Alerts & Notifications',
              'Stay informed about critical groundwater conditions',
              [
                _buildFeatureCard(
                  context,
                  'Critical Level Alerts',
                  'Get notified when groundwater levels are critically low',
                  Icons.warning,
                  Colors.red,
                  'Real-time alerts for critical conditions',
                ),
                _buildFeatureCard(
                  context,
                  'Trend Alerts',
                  'Notifications about declining groundwater trends',
                  Icons.notifications,
                  Colors.orange,
                  'Proactive alerts for trend changes',
                ),
                _buildFeatureCard(
                  context,
                  'Location-based Alerts',
                  'Alerts specific to your selected location',
                  Icons.location_city,
                  Colors.purple,
                  'Personalized alerts for your area',
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Data Management Features
            _buildFeatureSection(
              context,
              '📊 Data Management',
              'Manage and analyze your groundwater data',
              [
                _buildFeatureCard(
                  context,
                  'Manual Data Entry',
                  'Enter your own groundwater measurements',
                  Icons.edit,
                  Colors.green,
                  'Custom data entry with validation',
                ),
                _buildFeatureCard(
                  context,
                  'Data Export',
                  'Export your data in various formats',
                  Icons.download,
                  Colors.blue,
                  'CSV, JSON, and PDF export options',
                ),
                _buildFeatureCard(
                  context,
                  'Historical Data',
                  'Access historical groundwater data',
                  Icons.history,
                  Colors.brown,
                  'Comprehensive historical data access',
                ),
                _buildFeatureCard(
                  context,
                  'Data Visualization',
                  'Visual charts and graphs for data analysis',
                  Icons.bar_chart,
                  Colors.purple,
                  'Interactive charts and visualizations',
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Traffic Light System
            _buildFeatureSection(
              context,
              '🚦 Traffic Light System',
              'Easy-to-understand groundwater status indicators',
              [
                _buildFeatureCard(
                  context,
                  'Green Status',
                  'Good groundwater levels - safe to use',
                  Icons.circle,
                  Colors.green,
                  'Optimal groundwater conditions',
                ),
                _buildFeatureCard(
                  context,
                  'Yellow Status',
                  'Moderate groundwater levels - use with caution',
                  Icons.circle,
                  Colors.yellow,
                  'Moderate groundwater conditions',
                ),
                _buildFeatureCard(
                  context,
                  'Red Status',
                  'Critical groundwater levels - immediate attention needed',
                  Icons.circle,
                  Colors.red,
                  'Critical groundwater conditions',
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Ready to Use Citizen Features?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.go('/citizen-dashboard'),
                            icon: const Icon(Icons.dashboard),
                            label: const Text('Open Citizen Dashboard'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.go('/groundwater-data'),
                            icon: const Icon(Icons.water_drop),
                            label: const Text('Groundwater Data'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.go('/api-test'),
                            icon: const Icon(Icons.api),
                            label: const Text('Test API'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.go('/groundwater-test'),
                            icon: const Icon(Icons.bug_report),
                            label: const Text('Test Features'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Summary
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Citizen Features Summary',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('✅ Real-time groundwater monitoring'),
                    const Text('✅ Location-based analysis'),
                    const Text('✅ AI-powered forecasting'),
                    const Text('✅ Smart alerts and notifications'),
                    const Text('✅ Data management and export'),
                    const Text('✅ Traffic light status system'),
                    const Text('✅ Manual data entry'),
                    const Text('✅ Historical data access'),
                    const Text('✅ Interactive visualizations'),
                    const Text('✅ Privacy-focused design'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureSection(
    BuildContext context,
    String title,
    String subtitle,
    List<Widget> features,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        ...features,
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    String details,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontStyle: FontStyle.italic,
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
}
