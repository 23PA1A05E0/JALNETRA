import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as charts;
import '../providers/location_search_provider.dart';
import '../providers/groundwater_data_provider.dart' as groundwater;
import '../providers/prediction_forecast_provider.dart';
import '../providers/traffic_signal_provider.dart';
import '../services/api_service.dart';
import '../widgets/traffic_signal_widget.dart';
import 'package:logger/logger.dart';

final logger = Logger();

/// Data point class for chart
class ChartDataPoint {
  final String x;
  final double y;
  
  ChartDataPoint(this.x, this.y);
}

/// Researcher Dashboard with two main options
class ResearcherDashboard extends ConsumerStatefulWidget {
  const ResearcherDashboard({super.key});

  @override
  ConsumerState<ResearcherDashboard> createState() => _ResearcherDashboardState();
}

class _ResearcherDashboardState extends ConsumerState<ResearcherDashboard> {
  String? selectedOption;
  String? selectedState;
  String? selectedDistrict;
  String? selectedCity;
  bool showAnalytics = false;
  Position? _currentPosition;
  Placemark? _currentPlacemark;
  String _selectedPredictionPeriod = '1week';
  
  // API-related state variables
  Map<String, dynamic>? _apiAnalyticsData;
  bool _isLoadingApiData = false;
  String? _apiErrorMessage;

  // All Indian states and union territories
  final List<String> indianStates = const [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
    'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
    'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab',
    'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
    'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Lakshadweep', 'Puducherry',
  ];

  // State -> Districts map (same as citizen dashboard)
  late final Map<String, List<String>> stateDistrictsBase = {
    // Sample filled states
    'Delhi': [
      'Central Delhi',
      'East Delhi',
      'New Delhi',
      'North Delhi',
      'South Delhi',
      'West Delhi',
    ],
    'Maharashtra': [
      'Mumbai',
      'Pune',
      'Nagpur',
      'Nashik',
      'Aurangabad',
      'Solapur',
    ],
    'Karnataka': [
      'Bangalore',
      'Mysore',
      'Hubli',
      'Mangalore',
      'Belgaum',
      'Gulbarga',
    ],
    'Tamil Nadu': [
      'Chennai',
      'Coimbatore',
      'Madurai',
      'Tiruchirappalli',
      'Salem',
      'Tirunelveli',
    ],
    'Gujarat': [
      'Ahmedabad',
      'Surat',
      'Vadodara',
      'Rajkot',
      'Bhavnagar',
      'Jamnagar',
    ],
    'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Ajmer', 'Bikaner'],
    'Uttar Pradesh': [
      'Lucknow',
      'Kanpur',
      'Agra',
      'Varanasi',
      'Meerut',
      'Allahabad',
    ],
    'Andhra Pradesh': [
      'Nellore',
      'Prakasam',
      'Anantapur',
      'Krishna',
      'Chittoor',
      'East Godavari',
      'West Godavari',
      'Guntur',
    ],
  };

  late final Map<String, List<String>> stateDistricts;

  // District -> Cities map (same as citizen dashboard)
  late final Map<String, List<String>> districtCities = {
    'Central Delhi': ['Connaught Place', 'Karol Bagh', 'Paharganj'],
    'East Delhi': ['Shahdara', 'Seelampur', 'Gokulpuri'],
    'New Delhi': ['India Gate', 'Rashtrapati Bhavan', 'Connaught Place'],
    'North Delhi': ['Civil Lines', 'Kashmere Gate', 'Timarpur'],
    'South Delhi': ['Hauz Khas', 'Saket', 'Vasant Kunj'],
    'West Delhi': ['Rajouri Garden', 'Punjabi Bagh', 'Janakpuri'],
    'Mumbai': ['Andheri', 'Bandra', 'Borivali', 'Chembur', 'Dadar'],
    'Pune': ['Hinjewadi', 'Koregaon Park', 'Baner', 'Aundh', 'Viman Nagar'],
    'Bangalore': [
      'Koramangala',
      'Indiranagar',
      'Whitefield',
      'Electronic City',
      'Marathahalli',
    ],
    'Chennai': ['Anna Nagar', 'T. Nagar', 'Adyar', 'Velachery', 'Tambaram'],
    'Ahmedabad': [
      'Navrangpura',
      'Bodakdev',
      'Vastrapur',
      'Satellite',
      'Maninagar',
    ],
    'Jaipur': ['Pink City', 'Vaishali Nagar', 'C-Scheme', 'Malviya Nagar'],
    'Lucknow': ['Gomti Nagar', 'Hazratganj', 'Alambagh', 'Indira Nagar'],
    // Andhra Pradesh cities
    'Nellore': ['Gudur'],
    'Prakasam': ['Addanki', 'Akkireddypalem'],
    'Anantapur': ['Anantapur'],
    'Krishna': ['Bapulapadu'],
    'Chittoor': ['Chittoor'],
    'East Godavari': ['Kakinada', 'Sulthanagaram'],
    'West Godavari': ['Tadepalligudem'],
    'Guntur': ['Tenali'],
  };

  @override
  void initState() {
    super.initState();
    // Build full state->districts map including empty lists for states not predefined
    final Map<String, List<String>> map = {
      for (final entry in stateDistrictsBase.entries)
        entry.key: List<String>.from(entry.value),
    };
    for (final s in indianStates) {
      map.putIfAbsent(s, () => <String>[]);
    }
    stateDistricts = map;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load states from service after ref is available
    ref.read(locationSearchProvider.notifier).loadStates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Researcher Dashboard'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: GoRouter.of(context).canPop()
          ? IconButton(
              icon: Icon(
                Theme.of(context).platform == TargetPlatform.iOS
                  ? Icons.arrow_back_ios
                  : Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () {
                context.pop();
              },
              tooltip: 'Back',
            )
          : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.traffic),
            onPressed: () => context.push('/traffic-signals'),
            tooltip: 'View Traffic Signals',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(refreshTrafficSignalsProvider)();
              // Refresh other data as well
              ref.invalidate(groundwater.groundwaterDataProvider);
            },
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
            // Welcome Section
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            
            // Main Options
            _buildMainOptions(),
            const SizedBox(height: 24),
            
            // Content based on selected option
            if (selectedOption == 'information')
              _buildInformationContent(),
            if (selectedOption == 'analytics')
              _buildAnalyticsContent(),
            if (selectedOption == 'data')
              _buildDataDownloadContent(),
          ],
                  ),
                ),
    );
  }

  /// Fetch analytics data from API
  Future<void> _fetchApiAnalyticsData() async {
    if (selectedCity == null) {
      _apiErrorMessage = 'Please select a location first';
      return;
    }

    setState(() {
      _isLoadingApiData = true;
      _apiErrorMessage = null;
    });

    try {
      final apiService = ApiService();
      final apiData = await apiService.getFeaturesForLocation(selectedCity!);
      
      if (apiData != null && apiData.isNotEmpty) {
        final analyticsData = apiService.extractAnalyticsData(apiData);
        setState(() {
          _apiAnalyticsData = analyticsData;
          _isLoadingApiData = false;
        });
        logger.i('✅ API analytics data loaded for $selectedCity');
      } else {
        setState(() {
          _apiErrorMessage = 'No data available for $selectedCity from API';
          _isLoadingApiData = false;
        });
      }
    } catch (e) {
      setState(() {
        _apiErrorMessage = 'Error loading data from API: $e';
        _isLoadingApiData = false;
      });
      logger.e('❌ Error fetching API analytics: $e');
    }
  }

  /// Get analytics data (API data if available, otherwise mock data)
  Map<String, dynamic> _getAnalyticsData() {
    if (_apiAnalyticsData != null && _apiAnalyticsData!.isNotEmpty) {
      return _apiAnalyticsData!;
    }
    
    // Fallback to mock data
    return {
      'stationCode': 'MOCK',
      'stationName': selectedCity ?? 'Unknown',
      'averageDepth': _getMockAverageDepth(),
      'minDepth': _getMockMinDepth(),
      'maxDepth': _getMockMaxDepth(),
      'currentLevel': _getMockCurrentLevel(),
      'yearlyChange': _getMockYearlyChange(),
      'lastUpdated': DateTime.now().toIso8601String(),
      'dataPoints': 365,
      'aquiferType': 'Alluvial',
      'wellType': 'Bore Well',
      'dataSource': 'Mock Data',
    };
  }

  /// Mock data generation methods
  double _getMockAverageDepth() {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    return -5.0 - (random / 20);
  }

  double _getMockMinDepth() {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    return -5.0 - (random / 20); // More realistic range
  }

  double _getMockMaxDepth() {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    return -2.0 - (random / 25);
  }

  double _getMockCurrentLevel() {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    return -6.0 - (random / 20);
  }

  double _getMockYearlyChange() {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    return -0.5 - (random / 200);
  }

  /// Build API error message widget
  Widget _buildApiErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'API Data Unavailable',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _apiErrorMessage ?? 'Unknown error',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Showing mock data instead',
                  style: TextStyle(
                    color: Colors.orange[600],
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build welcome section
  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6A1B9A).withOpacity(0.7),
            const Color(0xFF8E24AA).withOpacity(0.6),
            const Color(0xFFAB47BC).withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A1B9A).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(
          children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.science,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
            Expanded(
                child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                    const Text(
                      'Welcome, Researcher',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
            fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose your research approach and access groundwater data',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        height: 1.4,
              ),
            ),
          ],
        ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build main options section
  Widget _buildMainOptions() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6A1B9A).withOpacity(0.1),
            const Color(0xFF6A1B9A).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6A1B9A).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A1B9A).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            ),
          ],
        ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(
          children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6A1B9A).withOpacity(0.2),
                        const Color(0xFF6A1B9A).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Color(0xFF6A1B9A),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
            Expanded(
                  child: Text(
                    'Choose Your Research Approach',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6A1B9A),
                    ),
              ),
            ),
          ],
        ),
            const SizedBox(height: 24),
            
            // Option 1: Analytics
            _buildOptionCard(
              title: 'I want analytics',
              description: 'Access the same features as citizens with detailed analytics',
              icon: Icons.analytics,
              onTap: () => setState(() => selectedOption = 'analytics'),
              isSelected: selectedOption == 'analytics',
            ),
            
            const SizedBox(height: 16),
            
            // Option 2: Data Download
            _buildOptionCard(
              title: 'I want data',
              description: 'Download raw data for your research and analysis',
              icon: Icons.download,
              onTap: () => setState(() => selectedOption = 'data'),
              isSelected: selectedOption == 'data',
            ),
          ],
        ),
      ),
    );
  }

  /// Build option card
  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return Card(
      elevation: isSelected ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? const Color(0xFF6A1B9A).withOpacity(0.6) : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: isSelected 
                ? [
                    const Color(0xFF6A1B9A).withOpacity(0.03),
                    const Color(0xFF6A1B9A).withOpacity(0.01),
                  ]
                : [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
            ),
          ),
          child: Row(
              children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? const Color(0xFF6A1B9A).withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? const Color(0xFF6A1B9A) : Colors.grey[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
                    Expanded(
                      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
            fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFF6A1B9A) : Colors.grey[800],
                            ),
                          ),
                    const SizedBox(height: 4),
                          Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? const Color(0xFF6A1B9A).withOpacity(0.8) : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? const Color(0xFF6A1B9A) : Colors.grey[400],
                size: 24,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Build analytics content (same as citizen dashboard)
  Widget _buildAnalyticsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location Selection Section
        _buildLocationSelectionSection(),
        const SizedBox(height: 24),
        
        // Analytics Button
        if (selectedState != null && selectedDistrict != null && selectedCity != null)
          _buildAnalyticsButton(),
        
        const SizedBox(height: 24),
        
        // Analytics Features (same as citizen dashboard)
        if (showAnalytics && selectedState != null && selectedDistrict != null && selectedCity != null)
          _buildAnalyticsFeatures(),
      ],
    );
  }

  /// Build information content (same as citizen dashboard)
  Widget _buildInformationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location Selection Section
        _buildLocationSelectionSection(),
        const SizedBox(height: 24),
        
        // Analytics Button
        if (selectedState != null && selectedDistrict != null && selectedCity != null)
          _buildAnalyticsButton(),
        
        const SizedBox(height: 24),
        
        // Analytics Features (same as citizen dashboard)
        if (showAnalytics && selectedState != null && selectedDistrict != null && selectedCity != null)
          _buildAnalyticsFeatures(),
      ],
    );
  }

  /// Build data download content
  Widget _buildDataDownloadContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6A1B9A).withOpacity(0.05),
            const Color(0xFF6A1B9A).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6A1B9A).withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6A1B9A).withOpacity(0.1),
                        const Color(0xFF6A1B9A).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.download,
                    color: Color(0xFF6A1B9A),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
            Expanded(
              child: Text(
                    'Data Download Center',
                    style: TextStyle(
                      fontSize: 20,
                  fontWeight: FontWeight.bold,
                      color: const Color(0xFF6A1B9A),
                ),
              ),
            ),
          ],
        ),
            const SizedBox(height: 24),
            
            // Location Selection
            _buildLocationSelection(),
            const SizedBox(height: 24),
            
            // Show analytics for selected location
            if (selectedCity != null) ...[
              // Download button for selected location
              _buildDownloadButton(),
            ] else ...[
              // Show message when no location is selected
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Please select a location to download Excel data',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build location selection for data download
  Widget _buildLocationSelection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Location for Data Download',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6A1B9A),
              ),
            ),
            const SizedBox(height: 16),
            
            // State dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'State',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.location_city),
              ),
              value: selectedState,
              isExpanded: true,
              items: indianStates.map((String state) {
                return DropdownMenuItem<String>(
                  value: state,
                  child: Text(
                    state,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedState = newValue;
                  selectedDistrict = null;
                  selectedCity = null;
                });
              },
            ),
            
            if (selectedState != null) ...[
            const SizedBox(height: 16),
            
              // District dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'District',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.location_on),
                ),
                value: selectedDistrict,
                isExpanded: true,
                items: (stateDistrictsBase[selectedState!] ?? []).map((String district) {
                  return DropdownMenuItem<String>(
                    value: district,
                    child: Text(
                      district,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedDistrict = newValue;
                    selectedCity = null;
                  });
                },
              ),
            ],
            
            if (selectedDistrict != null) ...[
              const SizedBox(height: 16),
              
              // City dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.home),
                ),
                value: selectedCity,
                isExpanded: true,
                items: _getCitiesForDistrict(selectedDistrict!).map((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Text(
                      city,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCity = newValue;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build analytics for selected location
  Widget _buildLocationAnalytics() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: const Color(0xFF6A1B9A),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Analytics for $selectedCity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  color: const Color(0xFF6A1B9A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Analytics cards (same as information content)
            Row(
              children: [
                Expanded(child: _buildAverageDepthCard()),
                    const SizedBox(width: 12),
                Expanded(child: _buildMinMaxDepthCard()),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: _buildYearlyChangeCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildDayForecastCard()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build download button for selected location
  Widget _buildDownloadButton() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6A1B9A).withOpacity(0.7),
              const Color(0xFF8E24AA).withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
                      child: Column(
                        children: [
            Icon(
              Icons.download,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 12),
                          Text(
              'Download Excel Data for $selectedCity',
              style: TextStyle(
                fontSize: 18,
                              fontWeight: FontWeight.bold,
                color: Colors.white,
                            ),
                          ),
            const SizedBox(height: 8),
                          Text(
              'Download comprehensive groundwater data in Excel format including historical records, predictions, and analytics',
                style: TextStyle(
                        fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Download format options - Only Excel
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _downloadData('Excel'),
                icon: const Icon(Icons.description, color: Colors.white),
                label: const Text('Download Excel', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  /// Download data for selected location
  void _downloadData(String format) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Download $format Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.download,
              size: 48,
              color: const Color(0xFF6A1B9A),
            ),
            const SizedBox(height: 16),
            Text(
              'Downloading groundwater data for $selectedCity in $format format...',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    
    // Simulate download process
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close loading dialog
      
      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Download Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 48,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              Text(
                'Data for $selectedCity has been downloaded successfully in $format format!',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  /// Get cities for a district
  List<String> _getCitiesForDistrict(String district) {
    return districtCities[district] ?? [];
  }

  /// Show download dialog
  void _showDownloadDialog(String dataType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Download $dataType'),
        content: Text('This will download $dataType for your research. Choose your preferred format:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$dataType download started'),
                  backgroundColor: const Color(0xFF6A1B9A),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
            ),
            child: const Text('Download CSV'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$dataType download started'),
                  backgroundColor: const Color(0xFF6A1B9A),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
            ),
            child: const Text('Download JSON'),
          ),
        ],
      ),
    );
  }

  // Location selection section (same as citizen dashboard)
  Widget _buildLocationSelectionSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode 
            ? [
                const Color(0xFF1a1a1a).withOpacity(0.9),
                const Color(0xFF2a2a2a).withOpacity(0.8),
                const Color(0xFF1a1a1a).withOpacity(0.9),
              ]
            : [
                const Color(0xFFFAFAFA), // Very light gray
                const Color(0xFFF5F5F5), // Light gray
                const Color(0xFFFAFAFA), // Very light gray
              ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode 
            ? const Color(0xFF6A1B9A).withOpacity(0.3)
            : const Color(0xFF6A1B9A).withOpacity(0.15), // Softer border
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
              ? const Color(0xFF6A1B9A).withOpacity(0.1)
              : const Color(0xFF6A1B9A).withOpacity(0.08), // Very subtle shadow
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: isDarkMode 
              ? Colors.black.withOpacity(0.3)
              : Colors.grey.withOpacity(0.05), // Very light shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDarkMode 
                        ? [
                            const Color(0xFF6A1B9A).withOpacity(0.2),
                            const Color(0xFF6A1B9A).withOpacity(0.1),
                          ]
                        : [
                            const Color(0xFF6A1B9A).withOpacity(0.1), // Softer purple
                            const Color(0xFF6A1B9A).withOpacity(0.05), // Very light purple
                          ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode 
                          ? const Color(0xFF6A1B9A).withOpacity(0.2)
                          : const Color(0xFF6A1B9A).withOpacity(0.1), // Softer shadow
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: isDarkMode ? const Color(0xFF6A1B9A) : const Color(0xFF6A1B9A), // Purple
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Select Your Location',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                      color: isDarkMode ? const Color(0xFF6A1B9A) : const Color(0xFF6A1B9A), // Purple for better contrast
                      fontSize: 22,
                      letterSpacing: 0.5,
              ),
            ),
            ),
          ],
        ),
            const SizedBox(height: 24),

            // Detect My Location Button
            _buildDetectLocationButton(),
            if (_currentPosition != null || _currentPlacemark != null) ...[
        const SizedBox(height: 16),
              _buildDetectedDetailsCard(),
            ],

            const SizedBox(height: 24),

            // Divider
            Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            isDarkMode 
                              ? const Color(0xFF6A1B9A).withOpacity(0.3)
                              : const Color(0xFF6A1B9A).withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkMode 
                          ? [
                              const Color(0xFF6A1B9A).withOpacity(0.1),
                              const Color(0xFF6A1B9A).withOpacity(0.05),
                            ]
                          : [
                              const Color(0xFF6A1B9A).withOpacity(0.1),
                              const Color(0xFF6A1B9A).withOpacity(0.05),
                            ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDarkMode 
                          ? const Color(0xFF6A1B9A).withOpacity(0.3)
                          : const Color(0xFF6A1B9A).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
              child: Text(
                      'OR',
                      style: TextStyle(
                        color: isDarkMode 
                          ? const Color(0xFF6A1B9A)
                          : const Color(0xFF6A1B9A),
                  fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.0,
                ),
              ),
            ),
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            isDarkMode 
                              ? const Color(0xFF6A1B9A).withOpacity(0.3)
                              : const Color(0xFF6A1B9A).withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Manual Selection Dropdowns
            _buildManualSelectionDropdowns(),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6A1B9A),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 45, // Fixed smaller height
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode 
                ? [
                    const Color(0xFF2a2a2a),
                    const Color(0xFF1a1a1a),
                  ]
                : [
                    const Color(0xFFFAFAFA), // Very light background
                    const Color(0xFFF0F0F0), // Slightly darker for subtle contrast
                  ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isDarkMode 
                ? const Color(0xFF6A1B9A).withOpacity(0.4)
                : const Color(0xFF6A1B9A).withOpacity(0.2), // Softer border
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10), // Smaller border radius
            boxShadow: [
              BoxShadow(
                color: isDarkMode 
                  ? const Color(0xFF6A1B9A).withOpacity(0.1)
                  : const Color(0xFF6A1B9A).withOpacity(0.05), // Very subtle shadow
                blurRadius: 6, // Smaller blur radius
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Select $label',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : const Color(0xFF666666), // Softer gray
                    fontSize: 14, // Smaller font size
                  ),
                ),
              ),
              isExpanded: true,
              style: TextStyle(
                color: isDarkMode ? Colors.white : const Color(0xFF333333), // Darker text for better contrast
                fontSize: 14, // Smaller font size
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: isDarkMode 
                ? const Color(0xFF2a2a2a)
                : const Color(0xFFFAFAFA), // Light background
              icon: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: isDarkMode ? const Color(0xFF6A1B9A) : const Color(0xFF6A1B9A), // Purple
                  size: 20, // Smaller icon size
                ),
              ),
              menuMaxHeight: 200, // Limit dropdown popup height
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // Even smaller padding
                    child: Text(
                      item,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : const Color(0xFF333333),
                        fontSize: 13, // Smaller font size for dropdown items
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: items.isEmpty ? null : onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          if (!showAnalytics) {
            // Fetch API data when showing analytics
            await _fetchApiAnalyticsData();
          }
          setState(() => showAnalytics = !showAnalytics);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6A1B9A),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoadingApiData
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Loading Analytics...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Text(
                showAnalytics ? 'Hide Analytics' : 'Show Analytics',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildAnalyticsFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show API error message if any
        if (_apiErrorMessage != null)
          _buildApiErrorMessage(),
        
        // Section Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF6A1B9A), const Color(0xFF8E24AA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.analytics, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Water Analytics & Insights',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Individual Location Traffic Signal Status (same as citizen dashboard)
        _buildLocationTrafficSignalCard(),
        
        const SizedBox(height: 16),
        
        // Depth Analytics Row
        Row(
          children: [
            Expanded(child: _buildAverageDepthCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildMinMaxDepthCard()),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Yearly Change Row
        Row(
          children: [
            Expanded(child: _buildYearlyChangeCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildDayForecastCard()),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Prediction Chart Row
        _buildPredictionChartRow(),
      ],
    );
  }

  /// Build Individual Location Traffic Signal Card (like citizen dashboard)
  Widget _buildLocationTrafficSignalCard() {
    return Card(
      elevation: 6,
      color: Theme.of(context).cardColor,
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
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.traffic,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${selectedCity ?? 'Selected Location'} Water Status',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                      if (selectedState != null && selectedDistrict != null)
                        Text(
                          '$selectedDistrict, $selectedState',
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
                    color: _getTrafficSignalColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getTrafficSignalColor().withOpacity(0.3)),
                  ),
                  child: Text(
                    _getTrafficSignalStatus(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getTrafficSignalColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Traffic Signal Display
            Center(
              child: Column(
                children: [
                  _buildTrafficLight(),
                  const SizedBox(height: 12),
                  Text(
                    _getTrafficSignalStatus(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getTrafficSignalColor(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getTrafficSignalDescription(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Traffic Signal Methods for Individual Location (like citizen dashboard)
  String _getTrafficSignalLevel() {
    // Use API data to determine traffic signal level
    final analyticsData = _getAnalyticsData();
    final avgDepth = analyticsData['averageDepth'] as double? ?? 0.0;
    
    // Convert to positive value for easier comparison
    final depthValue = avgDepth.abs();
    
    if (depthValue >= 0 && depthValue <= 5) {
      return 'good'; // Green: 0 to -5 meters
    } else if (depthValue >= 6 && depthValue <= 16) {
      return 'warning'; // Orange: -6 to -16 meters
    } else {
      return 'critical'; // Red: beyond -16 meters
    }
  }

  String _getTrafficSignalStatus() {
    switch (_getTrafficSignalLevel()) {
      case 'good': return 'GOOD';
      case 'warning': return 'CAUTION';
      case 'critical': return 'CRITICAL';
      default: return 'GOOD';
    }
  }

  Color _getTrafficSignalColor() {
    switch (_getTrafficSignalLevel()) {
      case 'good': return const Color(0xFF33B864);
      case 'warning': return Colors.orange;
      case 'critical': return Colors.red;
      default: return const Color(0xFF33B864);
    }
  }

  String _getTrafficSignalDescription() {
    switch (_getTrafficSignalLevel()) {
      case 'good': return 'Water levels are healthy and sustainable';
      case 'warning': return 'Water levels are declining, monitor closely';
      case 'critical': return 'Water levels critically low, immediate action needed';
      default: return 'Water levels are healthy and sustainable';
    }
  }

  Widget _buildTrafficLight() {
    final status = _getTrafficSignalLevel();
    return Container(
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
          _buildTrafficLightBulb(Colors.red, status == 'critical'),
          _buildTrafficLightBulb(Colors.orange, status == 'warning'),
          _buildTrafficLightBulb(const Color(0xFF33B864), status == 'good'),
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

  /// Build Regional Traffic Signal Card
  Widget _buildRegionalTrafficSignalCard() {
    return Consumer(
      builder: (context, ref, child) {
        final isLoading = ref.watch(trafficSignalLoadingProvider);
        final error = ref.watch(trafficSignalErrorProvider);
        
        if (isLoading) {
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
        
        if (error != null) {
          return Card(
            elevation: 6,
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading Traffic Signals',
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
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.read(refreshTrafficSignalsProvider)(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        
        return TrafficSignalWidget(
          showDetails: true,
          showRecommendations: false,
          onTap: () => _showTrafficSignalDetails(context),
        );
      },
    );
  }

  /// Build Traffic Signal Analytics
  Widget _buildTrafficSignalAnalytics() {
    return Consumer(
      builder: (context, ref, child) {
        final statisticsAsync = ref.watch(trafficSignalStatisticsProvider);
        
        return statisticsAsync.when(
          data: (statistics) {
            return Column(
              children: [
                // Statistics Row
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Total Regions',
                        '${statistics['totalRegions'] ?? 0}',
                        Icons.location_city,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Critical Regions',
                        '${statistics['criticalRegions'] ?? 0}',
                        Icons.warning,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Warning Regions',
                        '${statistics['warningRegions'] ?? 0}',
                        Icons.trending_up,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Good Regions',
                        '${statistics['goodRegions'] ?? 0}',
                        Icons.check_circle,
                        const Color(0xFF33B864),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Active Stations',
                        '${statistics['activeStations'] ?? 0}',
                        Icons.sensors,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Avg Risk Score',
                        '${((statistics['averageRiskScore'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                        Icons.analytics,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorCard('Error loading analytics: $error'),
        );
      },
    );
  }

  /// Build Analytics Card
  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
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
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build Error Card
  Widget _buildErrorCard(String error) {
    return Card(
      elevation: 4,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 4),
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

  /// Show Traffic Signal Details Dialog
  void _showTrafficSignalDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regional Traffic Signal Details'),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer(
            builder: (context, ref, child) {
              final criticalRegionsAsync = ref.watch(criticalRegionsProvider);
              final monitoringRegionsAsync = ref.watch(regionsRequiringMonitoringProvider);
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Overall Status
                  TrafficSignalWidget(
                    showDetails: true,
                    showRecommendations: false,
                  ),
                  const SizedBox(height: 16),
                  
                  // Critical Regions
                  if (criticalRegionsAsync.hasValue && criticalRegionsAsync.value!.isNotEmpty) ...[
                    Text(
                      'Critical Regions (${criticalRegionsAsync.value!.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...criticalRegionsAsync.value!.take(3).map((signal) => 
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: signal.level.color,
                          child: Text(
                            signal.level.status.substring(0, 1),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(signal.regionName),
                        subtitle: Text('${signal.formattedDepth} • ${signal.district}'),
                        trailing: Text(
                          '${(signal.riskScore * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: signal.level.color,
                          ),
                        ),
                      ),
                    ),
                    if (criticalRegionsAsync.value!.length > 3)
                      Text(
                        '... and ${criticalRegionsAsync.value!.length - 3} more',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Monitoring Regions
                  if (monitoringRegionsAsync.hasValue && monitoringRegionsAsync.value!.isNotEmpty) ...[
                    Text(
                      'Regions Requiring Monitoring (${monitoringRegionsAsync.value!.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...monitoringRegionsAsync.value!.take(3).map((signal) => 
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: signal.level.color,
                          child: Text(
                            signal.level.status.substring(0, 1),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(signal.regionName),
                        subtitle: Text('${signal.formattedDepth} • ${signal.district}'),
                        trailing: Text(
                          '${(signal.riskScore * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: signal.level.color,
                          ),
                        ),
                      ),
                    ),
                    if (monitoringRegionsAsync.value!.length > 3)
                      Text(
                        '... and ${monitoringRegionsAsync.value!.length - 3} more',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/traffic-signals');
            },
            child: const Text('View All'),
          ),
        ],
      ),
    );
  }

  /// Build Average Depth Card
  Widget _buildAverageDepthCard() {
    return Card(
      elevation: 4,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.trending_down, color: Colors.blue[600], size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Average Depth',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final analyticsData = _getAnalyticsData();
                final avgDepth = analyticsData['averageDepth'] as double? ?? 0.0;
                final dataSource = analyticsData['dataSource'] as String? ?? 'Mock Data';
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${avgDepth.toStringAsFixed(1)} m',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          dataSource == 'API Data' ? Icons.cloud_done : Icons.sim_card,
                          size: 12,
                          color: dataSource == 'API Data' ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dataSource,
                          style: TextStyle(
                            fontSize: 10,
                            color: dataSource == 'API Data' ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              'Current groundwater level',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Min Max Depth Card
  Widget _buildMinMaxDepthCard() {
    return Card(
      elevation: 4,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.height, color: Colors.purple[600], size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Depth Range',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.purple[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final analyticsData = _getAnalyticsData();
                final minDepth = analyticsData['minDepth'] as double? ?? 0.0;
                final maxDepth = analyticsData['maxDepth'] as double? ?? 0.0;
                final dataSource = analyticsData['dataSource'] as String? ?? 'Mock Data';
                
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Min: ${minDepth.toStringAsFixed(1)} m',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Shallowest',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Max: ${maxDepth.toStringAsFixed(1)} m',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Deepest',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          dataSource == 'API Data' ? Icons.cloud_done : Icons.sim_card,
                          size: 12,
                          color: dataSource == 'API Data' ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dataSource,
                          style: TextStyle(
                            fontSize: 10,
                            color: dataSource == 'API Data' ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Detect location button
  Widget _buildDetectLocationButton() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode 
            ? [
                const Color(0xFF6A1B9A).withOpacity(0.1),
                const Color(0xFF6A1B9A).withOpacity(0.05),
              ]
            : [
                const Color(0xFF6A1B9A).withOpacity(0.1),
                const Color(0xFF6A1B9A).withOpacity(0.05),
              ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode 
            ? const Color(0xFF6A1B9A).withOpacity(0.3)
            : const Color(0xFF6A1B9A).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
              ? const Color(0xFF6A1B9A).withOpacity(0.1)
              : const Color(0xFF6A1B9A).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _detectLocation,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
          children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDarkMode 
                        ? [
                            const Color(0xFF6A1B9A).withOpacity(0.2),
                            const Color(0xFF6A1B9A).withOpacity(0.1),
                          ]
                        : [
                            const Color(0xFF6A1B9A).withOpacity(0.2),
                            const Color(0xFF6A1B9A).withOpacity(0.1),
                          ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode 
                          ? const Color(0xFF6A1B9A).withOpacity(0.2)
                          : const Color(0xFF6A1B9A).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
            ),
          ],
        ),
                  child: Icon(
                    Icons.my_location,
                    color: isDarkMode ? const Color(0xFF6A1B9A) : const Color(0xFF6A1B9A),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detect My Location',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? const Color(0xFF6A1B9A) : const Color(0xFF6A1B9A),
                          fontSize: 18,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Automatically detect your current location',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode 
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: isDarkMode ? const Color(0xFF6A1B9A) : const Color(0xFF6A1B9A),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Detected details card
  Widget _buildDetectedDetailsCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode 
            ? [
                const Color(0xFF6A1B9A).withOpacity(0.1),
                const Color(0xFF6A1B9A).withOpacity(0.05),
              ]
            : [
                const Color(0xFF6A1B9A).withOpacity(0.1),
                const Color(0xFF6A1B9A).withOpacity(0.05),
              ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode 
            ? const Color(0xFF6A1B9A).withOpacity(0.3)
            : const Color(0xFF6A1B9A).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
              ? const Color(0xFF6A1B9A).withOpacity(0.1)
              : const Color(0xFF6A1B9A).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                    gradient: LinearGradient(
                      colors: isDarkMode 
                        ? [
                            const Color(0xFF6A1B9A).withOpacity(0.2),
                            const Color(0xFF6A1B9A).withOpacity(0.1),
                          ]
                        : [
                            const Color(0xFF6A1B9A).withOpacity(0.2),
                            const Color(0xFF6A1B9A).withOpacity(0.1),
                          ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: isDarkMode ? const Color(0xFF6A1B9A) : const Color(0xFF6A1B9A),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Location Detected',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? const Color(0xFF6A1B9A) : const Color(0xFF6A1B9A),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_currentPlacemark != null) ...[
              _buildDetailRow('City', _currentPlacemark!.locality ?? 'Unknown'),
              _buildDetailRow('District', _currentPlacemark!.subAdministrativeArea ?? 'Unknown'),
              _buildDetailRow('State', _currentPlacemark!.administrativeArea ?? 'Unknown'),
              if (_currentPosition != null) ...[
                _buildDetailRow('Latitude', '${_currentPosition!.latitude.toStringAsFixed(6)}'),
                _buildDetailRow('Longitude', '${_currentPosition!.longitude.toStringAsFixed(6)}'),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // Detail row helper
  Widget _buildDetailRow(String label, String value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode 
                  ? const Color(0xFF6A1B9A)
                  : const Color(0xFF6A1B9A),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode 
                  ? Colors.white.withOpacity(0.8)
                  : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Manual selection dropdowns (same as citizen dashboard)
  Widget _buildManualSelectionDropdowns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdown('State', selectedState, indianStates, (value) {
          setState(() {
            selectedState = value;
            selectedDistrict = null;
            selectedCity = null;
          });
          if (value != null && value.isNotEmpty && value != 'Andhra Pradesh') {
            ref.read(locationSearchProvider.notifier).loadDistricts(value);
          }
        }),
        const SizedBox(height: 12), // Reduced spacing
        _buildDropdown(
          'District',
          selectedDistrict,
          selectedState != null ? stateDistricts[selectedState] ?? [] : [],
          (value) {
            setState(() {
              selectedDistrict = value;
              selectedCity = null;
            });
            // Debug print for cities
            if (value != null) {
              final cities = districtCities[value] ?? [];
              print('DEBUG: Cities for $value: $cities');
            }
          },
        ),
        const SizedBox(height: 12), // Reduced spacing
        _buildDropdown(
          'City/Village',
          selectedCity,
          selectedDistrict != null
              ? districtCities[selectedDistrict] ?? []
              : [],
          (value) {
            setState(() {
              selectedCity = value;
            });
          },
        ),
      ],
    );
  }

  // Detect location method
  Future<void> _detectLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationPermissionDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationPermissionDialog();
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get placemark from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentPosition = position;
        _currentPlacemark = placemarks.isNotEmpty ? placemarks.first : null;
      });

      // Auto-select state and district if found
      if (_currentPlacemark != null) {
        final state = _currentPlacemark!.administrativeArea;
        final district = _currentPlacemark!.subAdministrativeArea;
        
        if (state != null && indianStates.contains(state)) {
          setState(() {
            selectedState = state;
            selectedDistrict = district;
            selectedCity = _currentPlacemark!.locality;
          });
        }
      }

    } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error detecting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show location permission dialog
  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs location permission to detect your current location. Please grant permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // Show location service dialog
  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Location services are disabled. Please enable them to detect your current location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Build Yearly Change Card
  Widget _buildYearlyChangeCard() {
    final yearlyChange = _getMockYearlyChange();
    final isPositive = yearlyChange > 0;
    return Card(
      elevation: 4,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPositive 
                      ? Colors.red.withOpacity(0.2)
                      : const Color(0xFF6A1B9A).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: isPositive ? Colors.red[600] : const Color(0xFF6A1B9A),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Yearly Change',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isPositive ? Colors.red[700] : const Color(0xFF6A1B9A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${isPositive ? '+' : ''}${yearlyChange.toStringAsFixed(1)} m',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.red[600] : const Color(0xFF6A1B9A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isPositive ? 'Water level rising' : 'Water level declining',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }


  /// Build Monthly Forecast Card
  Widget _buildMonthlyForecastCard() {
    final forecast = _getMockMonthlyForecast();
    return Card(
      elevation: 4,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_month, color: Colors.indigo[600], size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Monthly Forecast',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.indigo[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${forecast['level'].toStringAsFixed(1)} m',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getForecastTrendColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getForecastTrendColor().withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                forecast['trend'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getForecastTrendColor(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Day Forecast Card
  Widget _buildDayForecastCard() {
    final forecast = _getMockDayForecast();
    return Card(
      elevation: 4,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.today, color: Colors.cyan[600], size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Day Forecast',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.cyan[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${forecast['level'].toStringAsFixed(1)} m',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.cyan[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getDayForecastTrendColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getDayForecastTrendColor().withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                forecast['trend'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getDayForecastTrendColor(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Alerts and Notifications Card
  Widget _buildAlertsNotificationsCard() {
    final alerts = _getMockAlerts();
    return Card(
      elevation: 4,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.notifications, color: Colors.red[600], size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Alerts & Notifications',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (alerts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6A1B9A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF6A1B9A).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: const Color(0xFF6A1B9A),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'No active alerts',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6A1B9A),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...alerts.map((alert) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.red[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  // Mock data methods and helper functions

  /// Build Prediction Chart Row
  Widget _buildPredictionChartRow() {
    return Consumer(
      builder: (context, ref, child) {
        return Card(
          elevation: 4,
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Prediction Options
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.show_chart, color: Colors.purple[600], size: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Prediction Chart',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.purple[700],
                        ),
                      ),
                    ),
                    // Prediction Period Selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.purple.withOpacity(0.3)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPredictionPeriod,
                          items: const [
                            DropdownMenuItem(value: '1week', child: Text('1 Week')),
                            DropdownMenuItem(value: '1month', child: Text('1 Month')),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedPredictionPeriod = newValue ?? '1week';
                            });
                          },
                          style: TextStyle(
                            color: Colors.purple[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Chart Container
                SizedBox(
                  height: 300,
                  child: _buildPredictionChart(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build Prediction Chart
  Widget _buildPredictionChart() {
    return Consumer(
      builder: (context, ref, child) {
        final availableLocations = ref.watch(groundwater.availableLocationsProvider);
        
        if (availableLocations.isEmpty) {
          return const Center(
            child: Text('No locations available'),
          );
        }
        
        // Use first available location as default
        final selectedLocation = availableLocations.first;
        final groundwaterData = ref.watch(groundwater.groundwaterDataProvider(selectedLocation));
        final predictionData = ref.watch(predictionDataProvider(selectedLocation));
        final forecastData = ref.watch(forecastDataProvider(selectedLocation));
        
        return groundwaterData.when(
          data: (data) {
            if (data == null) {
              return const Center(child: Text('No data available'));
            }
            
            // Generate chart data based on selected period
            final chartData = _generatePredictionChartData(
              data,
              predictionData.value,
              forecastData.value,
              _selectedPredictionPeriod,
            );
            
            return charts.SfCartesianChart(
              primaryXAxis: const charts.CategoryAxis(
                title: charts.AxisTitle(text: 'Time Period'),
                labelRotation: -45,
              ),
              primaryYAxis: const charts.NumericAxis(
                title: charts.AxisTitle(text: 'Depth (meters)'),
                isInversed: true,
              ),
              title: charts.ChartTitle(
                text: 'Groundwater Forecast - ${_selectedPredictionPeriod == '1week' ? '1 Week' : '1 Month'}',
                textStyle: Theme.of(context).textTheme.titleSmall,
              ),
              legend: const charts.Legend(
                isVisible: true,
                position: charts.LegendPosition.bottom,
              ),
              tooltipBehavior: charts.TooltipBehavior(
                enable: true,
                format: 'point.x: point.y m',
              ),
              series: <charts.CartesianSeries<ChartDataPoint, String>>[
                charts.LineSeries<ChartDataPoint, String>(
                  dataSource: chartData['forecast'] ?? [],
                  xValueMapper: (ChartDataPoint data, _) => data.x,
                  yValueMapper: (ChartDataPoint data, _) => data.y,
                  name: 'Forecast',
                  color: Colors.blue,
                  width: 2,
                  markerSettings: const charts.MarkerSettings(
                    isVisible: true,
                    height: 4,
                    width: 4,
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
    );
  }

  /// Generate forecast chart data based on selected period
  Map<String, List<ChartDataPoint>> _generatePredictionChartData(
    Map<String, dynamic> groundwaterData,
    Map<String, dynamic>? predictionData,
    Map<String, dynamic>? forecastData,
    String period,
  ) {
    final chartData = <String, List<ChartDataPoint>>{};
    
    // No historical data - only show forecast data
    chartData['historical'] = <ChartDataPoint>[];
    chartData['prediction'] = <ChartDataPoint>[];
    
    // Forecast data only
    final forecastDataPoints = <ChartDataPoint>[];
    final forecastDataList = forecastData?['forecastData'] as List<Map<String, dynamic>>? ?? [];
    
    if (forecastDataList.isNotEmpty) {
      final limit = period == '1week' ? 7 : 15;
      for (final forecastPoint in forecastDataList.take(limit)) {
        final date = forecastPoint['date'] as String? ?? '';
        final depth = forecastPoint['forecast'] as double? ?? -5.0; // Use 'forecast' field and realistic fallback
        
        forecastDataPoints.add(ChartDataPoint(date, depth));
      }
    }
    chartData['forecast'] = forecastDataPoints;
    
    return chartData;
  }



  Map<String, dynamic> _getMockMonthlyForecast() {
    final trends = ['RISING', 'STABLE', 'DECLINING'];
    return {
      'level': 16.8 + (DateTime.now().millisecond % 40) / 10,
      'trend': trends[DateTime.now().millisecond % 3],
    };
  }


  Map<String, dynamic> _getMockDayForecast() {
    final trends = ['RISING', 'STABLE', 'DECLINING'];
    return {
      'level': 15.9 + (DateTime.now().millisecond % 30) / 10,
      'trend': trends[DateTime.now().millisecond % 3],
    };
  }

  List<String> _getMockAlerts() {
    return [];
  }


  Color _getForecastTrendColor() {
    final forecast = _getMockMonthlyForecast();
    switch (forecast['trend']) {
      case 'RISING': return const Color(0xFF6A1B9A);
      case 'STABLE': return Colors.orange;
      case 'DECLINING': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getDayForecastTrendColor() {
    final forecast = _getMockDayForecast();
    switch (forecast['trend']) {
      case 'RISING': return const Color(0xFF6A1B9A);
      case 'STABLE': return Colors.orange;
      case 'DECLINING': return Colors.red;
      default: return Colors.grey;
    }
  }
}
