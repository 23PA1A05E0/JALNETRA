import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../providers/location_search_provider.dart';
import '../providers/manual_data_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/water_level_chart_painter.dart';

/// Citizen Dashboard - Dark theme with location detection and analytics
class CitizenDashboard extends ConsumerStatefulWidget {
  const CitizenDashboard({super.key});

  @override
  ConsumerState<CitizenDashboard> createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends ConsumerState<CitizenDashboard> {
  String? selectedState;
  String? selectedDistrict;
  String? selectedCity;
  bool showAnalytics = false;
  bool isDetectingLocation = false;
  bool locationPermissionGranted = false;
  Position? _currentPosition;
  Placemark? _currentPlacemark;

  // All Indian states and union territories (canonical display names)
  final List<String> indianStates = const [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    // Union Territories
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  // Common aliases to canonical names (lowercased keys)
  final Map<String, String> stateAliases = const {
    'nct of delhi': 'Delhi',
    'national capital territory of delhi': 'Delhi',
    'pondicherry': 'Puducherry',
    'orissa': 'Odisha',
    'uttaranchal': 'Uttarakhand',
    'daman and diu': 'Dadra and Nagar Haveli and Daman and Diu',
    'dadra and nagar haveli': 'Dadra and Nagar Haveli and Daman and Diu',
    'jammu & kashmir': 'Jammu and Kashmir',
  };

  // State -> Districts map (sample districts for a few states, others left empty by default)
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

  String? _normalizeStateName(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    if (stateAliases.containsKey(lower)) {
      return stateAliases[lower];
    }
    // Direct case-insensitive match
    for (final s in indianStates) {
      if (s.toLowerCase() == lower) return s;
    }
    // Contains/partial match
    for (final s in indianStates) {
      if (lower.contains(s.toLowerCase()) || s.toLowerCase().contains(lower)) {
        return s;
      }
    }
    return trimmed;
  }

  String? _normalizeDistrictName(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    
    // Remove common suffixes
    String cleaned = lower
        .replaceAll(' district', '')
        .replaceAll(' dist', '')
        .replaceAll(' district', '')
        .trim();
    
    // Direct case-insensitive match with all districts in Andhra Pradesh
    final apDistricts = stateDistrictsBase['Andhra Pradesh'] ?? [];
    for (final district in apDistricts) {
      if (district.toLowerCase() == cleaned) return district;
    }
    
    // Contains/partial match
    for (final district in apDistricts) {
      if (cleaned.contains(district.toLowerCase()) || district.toLowerCase().contains(cleaned)) {
        return district;
      }
    }
    
    return trimmed;
  }

  final Map<String, List<String>> districtCities = {
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
    // Load states from service
    ref.read(locationSearchProvider.notifier).loadStates();
    _checkLocationPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark theme background
      appBar: AppBar(
        title: const Text(
          'Citizen Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final themeMode = ref.watch(themeModeProvider);
              final themeNotifier = ref.read(themeModeProvider.notifier);
              
              return IconButton(
                onPressed: () {
                  themeNotifier.toggleTheme();
                },
                icon: Icon(
                  themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                ),
                tooltip: 'Toggle Theme (Current: ${themeNotifier.themeModeName})',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
          IconButton(
            onPressed: () {
              context.go('/debug');
            },
            icon: const Icon(Icons.settings_applications),
            tooltip: 'Open Debug Screen',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.green[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome, Citizen',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select your location to get personalized water insights and analytics',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Location Selection Section
            _buildLocationSelectionSection(),

            const SizedBox(height: 24),

            // Analytics Button
            if (selectedState != null &&
                selectedDistrict != null &&
                selectedCity != null)
              _buildAnalyticsButton(),

            const SizedBox(height: 24),

            // Analytics now redirects to separate screen
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSelectionSection() {
    return Card(
      elevation: 8,
      color: Colors.white, // White background for contrast
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
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Select Your Location',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Detect My Location Button
            _buildDetectLocationButton(),
            if (_currentPosition != null || _currentPlacemark != null) ...[
              const SizedBox(height: 12),
              _buildDetectedDetailsCard(),
            ],

            const SizedBox(height: 20),

            // Divider
            Container(
              height: 1,
              color: Colors.grey[300],
              child: Row(
                children: [
                  Expanded(
                    child: Container(height: 1, color: Colors.grey[300]),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(height: 1, color: Colors.grey[300]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Manual Selection Dropdowns
            _buildManualSelectionDropdowns(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectedDetailsCard() {
    final pos = _currentPosition;
    final p = _currentPlacemark;
    final subtitle = p == null
        ? 'Fetching address...'
        : [
            p.name,
            p.subLocality,
            p.locality,
            p.subAdministrativeArea,
            p.administrativeArea,
            p.postalCode,
          ].where((e) => (e ?? '').isNotEmpty).join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.06),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.my_location, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Detected Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (pos != null)
            Text(
              'Lat: ${pos.latitude.toStringAsFixed(6)}, Lng: ${pos.longitude.toStringAsFixed(6)}',
              style: const TextStyle(color: Colors.black87),
            ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.black87)),
          ],
        ],
      ),
    );
  }

  Widget _buildDetectLocationButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isDetectingLocation ? null : _detectCurrentLocation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        icon: isDetectingLocation
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.my_location, size: 24),
        label: Text(
          isDetectingLocation ? 'Detecting Location...' : 'Detect My Location',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildManualSelectionDropdowns() {
    final searchState = ref.watch(locationSearchProvider);
    final List<String> stateItems =
        searchState.states.isNotEmpty ? searchState.states : indianStates;
    final List<String> districtItems = (selectedState == 'Andhra Pradesh')
        ? stateDistricts['Andhra Pradesh']!
        : (searchState.selectedState == selectedState &&
                searchState.districts.isNotEmpty)
            ? searchState.districts
            : (selectedState != null ? stateDistricts[selectedState]! : <String>[]);
    
    // Debug print to help identify issues
    if (selectedState == 'Andhra Pradesh') {
      print('DEBUG: Andhra Pradesh districts: $districtItems');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manual Selection',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        const SizedBox(height: 16),
        _buildDropdown('State', selectedState, stateItems, (
          value,
        ) {
          setState(() {
            selectedState = value;
            selectedDistrict = null;
            selectedCity = null;
          });
          if (value != null && value.isNotEmpty && value != 'Andhra Pradesh') {
            ref.read(locationSearchProvider.notifier).loadDistricts(value);
          }
        }),
        const SizedBox(height: 16),
        _buildDropdown(
          'District',
          selectedDistrict,
          districtItems,
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
        const SizedBox(height: 16),
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

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                'Select $label',
                style: const TextStyle(color: Colors.black54),
              ),
              isExpanded: true,
              style: const TextStyle(color: Colors.black),
              dropdownColor: Colors.white,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Container(
                    color: Colors.white,
                    child: Text(
                      item,
                      style: const TextStyle(color: Colors.black),
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Navigate to analytics screen with location data
          context.go('/analytics', extra: {
            'selectedCity': selectedCity,
            'selectedDistrict': selectedDistrict,
            'selectedState': selectedState,
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Show Analytics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }

  /// Build real data analytics for Tadepalligudem
  Widget _buildRealDataAnalytics() {
    return Consumer(
      builder: (context, ref, child) {
        final stationData = ref.watch(stationDataProvider);
        
        return Card(
          elevation: 8,
          color: Colors.white,
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
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.water_drop,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Real-Time Groundwater Data',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          Text(
                            'Tadepalligudem Station (CGWHYD0514)',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ref.read(refreshDataProvider)();
                      },
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh Data',
                    ),
                    IconButton(
                      onPressed: () {
                        context.go('/debug');
                      },
                      icon: const Icon(Icons.settings_applications),
                      tooltip: 'Open Debug Screen',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                stationData.when(
                  data: (data) {
                    if (data == null) {
                      return const Center(
                        child: Text('No data available'),
                      );
                    }
                    
                    return Column(
                      children: [
                        // Real data cards
                        // Main data cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildRealDataCard(
                                'Current Water Level',
                                '${data['latestWaterLevel']?.toStringAsFixed(2) ?? 'N/A'} ${data['waterLevelUnit'] ?? 'm'}',
                                Icons.water_drop,
                                Colors.blue,
                                'Last updated: ${data['lastUpdated'] ?? 'N/A'}',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildRealDataCard(
                                'Well Depth',
                                '${data['wellDepth']?.toStringAsFixed(1) ?? 'N/A'} m',
                                Icons.height,
                                Colors.green,
                                'Aquifer: ${data['aquiferType'] ?? 'N/A'}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Additional data cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildRealDataCard(
                                'Data Points',
                                '${data['dataPoints'] ?? 0}',
                                Icons.analytics,
                                Colors.orange,
                                'Total measurements',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildRealDataCard(
                                'Station Code',
                                '${data['stationCode'] ?? 'N/A'}',
                                Icons.location_on,
                                Colors.purple,
                                '${data['stationName'] ?? 'N/A'}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Data source and quality info
                        Row(
                          children: [
                            Expanded(
                              child: _buildRealDataCard(
                                'Data Source',
                                '${data['dataSource'] ?? 'Unknown'}',
                                Icons.cloud_download,
                                Colors.teal,
                                '${data['parsingStrategy'] ?? 'Unknown parsing'}',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildRealDataCard(
                                'Well Type',
                                '${data['wellType'] ?? 'N/A'}',
                                Icons.water,
                                Colors.indigo,
                                '${data['aquiferType'] ?? 'N/A'} aquifer',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Historical data chart section
                        if (data['dataPoints'] != null && data['dataPoints'] > 0) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.timeline, color: Colors.blue.shade700),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Historical Data Trend',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 200,
                                  child: _buildHistoricalChart(data),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // Navigate to detailed charts screen
                                      context.go('/station/CGWHYD0514');
                                    },
                                    icon: const Icon(Icons.timeline),
                                    label: const Text('View Detailed Charts'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Data quality and metadata
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Station Information',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildStationInfo(data),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data Source Information',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Source: ${data['dataSource'] ?? 'National Water Informatics Centre (NWIC)'}',
                                style: const TextStyle(color: Colors.black87),
                              ),
                              Text(
                                'Agency: Central Ground Water Board (CGWB)',
                                style: const TextStyle(color: Colors.black87),
                              ),
                              Text(
                                'Data Period: 2013-2025',
                                style: const TextStyle(color: Colors.black87),
                              ),
                              if (data['parsingStrategy'] != null)
                                Text(
                                  'Parsing: ${data['parsingStrategy']}',
                                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load data',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
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
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build historical chart for groundwater data
  Widget _buildHistoricalChart(Map<String, dynamic> data) {
    return Consumer(
      builder: (context, ref, child) {
        final historicalData = ref.watch(historicalDataProvider({
          'limit': 30, // Show last 30 data points
        }));
        
        return historicalData.when(
          data: (chartData) {
            if (chartData.isEmpty) {
              return const Center(
                child: Text('No historical data available for chart'),
              );
            }
            
            // Create a simple line chart using basic widgets
            return CustomPaint(
              painter: WaterLevelChartPainter(chartData),
              size: const Size(double.infinity, 200),
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
    );
  }
  
  /// Build station information display
  Widget _buildStationInfo(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Station Code', data['stationCode'] ?? 'N/A'),
        _buildInfoRow('Station Name', data['stationName'] ?? 'N/A'),
        _buildInfoRow('District', data['district'] ?? 'N/A'),
        _buildInfoRow('State', data['state'] ?? 'N/A'),
        _buildInfoRow('Coordinates', '${data['latitude'] ?? 'N/A'}, ${data['longitude'] ?? 'N/A'}'),
        _buildInfoRow('Well Type', data['wellType'] ?? 'N/A'),
        _buildInfoRow('Aquifer Type', data['aquiferType'] ?? 'N/A'),
        _buildInfoRow('Well Depth', '${data['wellDepth']?.toStringAsFixed(1) ?? 'N/A'} m'),
      ],
    );
  }
  
  /// Build info row widget
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
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealDataCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String description,
  ) {
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
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String description,
  ) {
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(
    String title,
    String description,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Location detection methods
  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    setState(() {
      locationPermissionGranted =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    });
  }

  Future<void> _detectCurrentLocation() async {
    setState(() {
      isDetectingLocation = true;
    });

    try {
      // Ensure location services are enabled (redirect to settings if not)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _showLocationServiceDialog();
          return;
        }
      }

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

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 20),
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentPosition = position;
          _currentPlacemark = place;
        });
        _updateLocationFromPlacemark(place);
      }
    } catch (e) {
      _showErrorDialog('Failed to detect location: ${e.toString()}');
    } finally {
      setState(() {
        isDetectingLocation = false;
      });
    }
  }

  void _updateLocationFromPlacemark(Placemark place) {
    String? state = _normalizeStateName(place.administrativeArea);
    String? district = _normalizeDistrictName(place.subAdministrativeArea);
    String? city = place.locality ?? place.subLocality;

    // Map to our dropdown values
    String? mappedState = _mapToDropdownValue(
      state,
      stateDistricts.keys.toList(),
    );
    String? mappedDistrict;
    String? mappedCity;

    if (mappedState != null) {
      List<String> districts = stateDistricts[mappedState]!;
      mappedDistrict = _mapToDropdownValue(district, districts);

      if (mappedDistrict != null) {
        List<String> cities = districtCities[mappedDistrict] ?? [];
        mappedCity = _mapToDropdownValue(city, cities);
      }
    }

    setState(() {
      selectedState = mappedState;
      selectedDistrict = mappedDistrict;
      selectedCity = mappedCity;
    });

    if (mappedState != null && mappedState.isNotEmpty) {
      ref.read(locationSearchProvider.notifier).loadDistricts(mappedState);
    }

    if (mappedState != null && mappedDistrict != null && mappedCity != null) {
      _showSuccessDialog('Location detected successfully!');
    } else {
      _showPartialLocationDialog(place);
    }
  }

  String? _mapToDropdownValue(String? value, List<String> options) {
    if (value == null) return null;

    // Try exact match first
    for (String option in options) {
      if (option.toLowerCase().contains(value.toLowerCase()) ||
          value.toLowerCase().contains(option.toLowerCase())) {
        return option;
      }
    }

    // Try partial match
    for (String option in options) {
      if (option
          .toLowerCase()
          .split(' ')
          .any(
            (word) =>
                value.toLowerCase().contains(word) ||
                word.contains(value.toLowerCase()),
          )) {
        return option;
      }
    }

    return null;
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Location Services Disabled',
          style: TextStyle(color: Colors.black),
        ),
        content: const Text(
          'Please enable location services to auto-detect your location.',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await Geolocator.openLocationSettings();
              if (mounted) Navigator.pop(context);
              // Retry detection after returning from settings
              _detectCurrentLocation();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Location Permission Required',
          style: TextStyle(color: Colors.black),
        ),
        content: const Text(
          'Allow location access to auto-detect your area?',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Deny', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Success', style: TextStyle(color: Colors.black)),
        content: Text(message, style: const TextStyle(color: Colors.black)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPartialLocationDialog(Placemark place) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Location Partially Detected',
          style: TextStyle(color: Colors.black),
        ),
        content: Text(
          'We detected your location as:\n'
          '${place.locality ?? place.subLocality}, '
          '${place.subAdministrativeArea}, '
          '${place.administrativeArea}\n\n'
          'Please select the exact location from the dropdowns below.',
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Error', style: TextStyle(color: Colors.black)),
        content: Text(message, style: const TextStyle(color: Colors.black)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
