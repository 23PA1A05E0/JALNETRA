import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../providers/location_search_provider.dart';
import '../providers/manual_data_provider.dart';

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
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: const Text(
          'Citizen Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF33B864).withOpacity(0.4),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: Navigator.of(context).canPop() 
          ? IconButton(
                icon: Icon(
                Theme.of(context).platform == TargetPlatform.iOS 
                  ? Icons.arrow_back_ios 
                  : Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              tooltip: 'Back',
            )
          : null,
        actions: [
          // Settings navigation button
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.dark 
                    ? [
                        const Color(0xFF33B864).withOpacity(0.4),
                        const Color(0xFF33B864).withOpacity(0.4),
                        const Color(0xFF33B864).withOpacity(0.4),
                      ]
                    : [
                        const Color(0xFF33B864).withOpacity(0.4), // Softer green
                        const Color(0xFF33B864).withOpacity(0.4), // Lighter green
                        const Color(0xFF33B864).withOpacity(0.4), // Even lighter green
                      ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.waving_hand,
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
                    'Welcome, Citizen',
                    style: TextStyle(
                      color: Colors.white,
                                fontSize: 26,
                      fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select your location to get personalized water insights and analytics',
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

            // New Features Section - Show after analytics button is clicked
            if (showAnalytics &&
                selectedState != null &&
                selectedDistrict != null &&
                selectedCity != null)
              _buildNewFeaturesSection(),

            const SizedBox(height: 24),

            // Analytics now redirects to separate screen
          ],
        ),
      ),
    );
  }

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
            ? const Color(0xFF33B864).withOpacity(0.2)
            : const Color(0xFF33B864).withOpacity(0.1), // Softer border
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
                      colors: isDarkMode 
                        ? [
                            const Color(0xFF33B864).withOpacity(0.4),
                            const Color(0xFF33B864).withOpacity(0.4),
                          ]
                        : [
                            const Color(0xFF33B864).withOpacity(0.4), // Softer green
                            const Color(0xFF33B864).withOpacity(0.4), // Very light green
                          ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: isDarkMode ? const Color(0xFF33B864).withOpacity(0.4) : const Color(0xFF33B864).withOpacity(0.4), // Softer green
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                  'Select Your Location',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                      color: isDarkMode ? const Color(0xFF33B864) : const Color(0xFF33B864), // Darker green for better contrast
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
                              ? const Color(0xFF33B864).withOpacity(0.4)
                              : const Color(0xFF33B864).withOpacity(0.4),
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
                              const Color(0xFF33B864).withOpacity(0.1),
                              const Color(0xFF33B864).withOpacity(0.05),
                            ]
                          : [
                              const Color(0xFF33B864).withOpacity(0.1),
                              const Color(0xFF33B864).withOpacity(0.05),
                            ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDarkMode 
                          ? const Color(0xFF33B864).withOpacity(0.2)
                          : const Color(0xFF33B864).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: isDarkMode 
                          ? const Color(0xFF33B864)
                          : const Color(0xFF33B864),
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
                              ? const Color(0xFF33B864).withOpacity(0.4)
                              : const Color(0xFF33B864).withOpacity(0.4),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark 
            ? [
                const Color(0xFF1a1a1a).withOpacity(0.8),
                const Color(0xFF2a2a2a).withOpacity(0.6),
              ]
            : [
                const Color(0xFFFAFAFA).withOpacity(0.9), // Very light background
                const Color(0xFFF0F0F0).withOpacity(0.8), // Subtle contrast
              ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF33B864).withOpacity(0.2)
            : const Color(0xFF33B864).withOpacity(0.1), // Very subtle border
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: Theme.of(context).brightness == Brightness.dark 
                        ? [
                            const Color(0xFF33B864).withOpacity(0.4),
                            const Color(0xFF33B864).withOpacity(0.4),
                          ]
                        : [
                            const Color(0xFF33B864).withOpacity(0.4), // Very subtle green
                            const Color(0xFF33B864).withOpacity(0.4), // Even more subtle
                          ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.my_location,
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? const Color(0xFF33B864).withOpacity(0.4) 
                      : const Color(0xFF33B864).withOpacity(0.4), // Softer green
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
              Text(
                'Detected Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? const Color(0xFF33B864).withOpacity(0.4) 
                      : const Color(0xFF33B864).withOpacity(0.4), // Darker green for better contrast
                    fontSize: 18,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (pos != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF2a2a2a).withOpacity(0.5)
                  : const Color(0xFFF5F5F5).withOpacity(0.6), // Softer light background
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF33B864).withOpacity(0.05)
                    : const Color(0xFF33B864).withOpacity(0.05), // Very subtle border
                ),
              ),
              child: Text(
              'Lat: ${pos.latitude.toStringAsFixed(6)}, Lng: ${pos.longitude.toStringAsFixed(6)}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF2a2a2a).withOpacity(0.5)
                  : const Color(0xFFF5F5F5).withOpacity(0.6), // Softer light background
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF33B864).withOpacity(0.05)
                    : const Color(0xFF33B864).withOpacity(0.05), // Very subtle border
                ),
              ),
              child: Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 14,
                ),
              ),
            ),
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
          backgroundColor: const Color(0xFF33B864),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode 
            ? [
                const Color(0xFF1a1a1a).withOpacity(0.8),
                const Color(0xFF2a2a2a).withOpacity(0.6),
              ]
            : [
                const Color(0xFFFAFAFA).withOpacity(0.9), // Very light background
                const Color(0xFFF0F0F0).withOpacity(0.8), // Subtle contrast
              ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode 
            ? const Color(0xFF33B864).withOpacity(0.2)
            : const Color(0xFF33B864).withOpacity(0.1), // Very subtle border
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
              ? const Color(0xFF33B864).withOpacity(0.05)
              : const Color(0xFF33B864).withOpacity(0.03), // Very subtle shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                          const Color(0xFF33B864).withOpacity(0.2),
                          const Color(0xFF33B864).withOpacity(0.1),
                        ]
                      : [
                          const Color(0xFF33B864).withOpacity(0.08), // Very subtle green
                          const Color(0xFF33B864).withOpacity(0.04), // Even more subtle
                        ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_on,
                  color: isDarkMode ? const Color(0xFF33B864) : const Color(0xFF33B864), // Softer green
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
        Text(
          'Manual Selection',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
                  color: isDarkMode ? const Color(0xFF33B864) : const Color(0xFF33B864), // Darker green for better contrast
                  fontSize: 18,
          ),
        ),
            ],
          ),
          const SizedBox(height: 20),
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
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF33B864).withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 45, // Fixed smaller height
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode 
                ? [
                    const Color(0xFF1a1a1a),
                    const Color(0xFF2a2a2a),
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
                ? const Color(0xFF33B864).withOpacity(0.2)
                : const Color(0xFF33B864).withOpacity(0.2), // Softer border
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10), // Smaller border radius
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
                  color: isDarkMode ? const Color(0xFF33B864) : const Color(0xFF33B864), // Green
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

  /// Build new features section with all requested features
  Widget _buildNewFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Container(
      width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.blue[800]!],
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
        
        // Traffic Signal Status
        _buildTrafficSignalCard(),
        
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
        
        // Yearly Change and Well Depth Row
        Row(
          children: [
            Expanded(child: _buildYearlyChangeCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildWellDepthCard()),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Forecasts Row
        Row(
          children: [
            Expanded(child: _buildMonthlyForecastCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildDayForecastCard()),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Alerts and Notifications
        _buildAlertsNotificationsCard(),
      ],
    );
  }

  /// Build Traffic Signal Card
  Widget _buildTrafficSignalCard() {
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
                Text(
                  'Regional Water Status',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
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

  /// Build Traffic Light Visual
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

  String _getTrafficSignalLevel() {
    // This will be updated to use real API data
    // For now, we'll use mock logic but it can be easily replaced with real data
    final random = DateTime.now().millisecond % 3;
    switch (random) {
      case 0: return 'good';
      case 1: return 'warning';
      case 2: return 'critical';
      default: return 'good';
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

  /// Build Average Depth Card
  Widget _buildAverageDepthCard() {
    return Consumer(
      builder: (context, ref, child) {
        final stationData = ref.watch(stationDataProvider);
        
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
                stationData.when(
                  data: (data) {
                    final avgDepth = _calculateAverageDepthFromAPI(data);
                    return Text(
                      '${avgDepth.toStringAsFixed(1)} m',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[600],
                      ),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text(
                    'N/A',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last 12 months',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build Min Max Depth Card
  Widget _buildMinMaxDepthCard() {
    return Consumer(
      builder: (context, ref, child) {
        final stationData = ref.watch(stationDataProvider);
        
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
                        'Min / Max Depth',
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
                stationData.when(
                  data: (data) {
                    final minMax = _calculateMinMaxDepthFromAPI(data);
                    return Row(
                          children: [
                            Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Min',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),
                              Text(
                                '${minMax['min']?.toStringAsFixed(1) ?? 'N/A'} m',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF33B864),
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
                                'Max',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),
                              Text(
                                '${minMax['max']?.toStringAsFixed(1) ?? 'N/A'} m',
                                style: TextStyle(
                                  fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                  color: Colors.red[600],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Row(
                    children: [
                      Expanded(child: Text('N/A', style: TextStyle(color: Colors.grey[600]))),
                      Expanded(child: Text('N/A', style: TextStyle(color: Colors.grey[600]))),
                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
        );
      },
    );
  }

  /// Build Yearly Change Card
  Widget _buildYearlyChangeCard() {
    return Consumer(
      builder: (context, ref, child) {
        final stationData = ref.watch(stationDataProvider);
        
        return Card(
          elevation: 4,
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                stationData.when(
                  data: (data) {
                    final yearlyChange = _calculateYearlyChangeFromAPI(data);
                    return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: yearlyChange >= 0 
                                    ? Colors.red.withOpacity(0.2)
                                    : const Color(0xFF33B864).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                yearlyChange >= 0 ? Icons.trending_up : Icons.trending_down,
                                color: yearlyChange >= 0 ? Colors.red[600] : const Color(0xFF33B864),
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
                                  color: yearlyChange >= 0 ? Colors.red[700] : const Color(0xFF33B864),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                              Text(
                          '${yearlyChange >= 0 ? '+' : ''}${yearlyChange.toStringAsFixed(1)} m',
                          style: TextStyle(
                            fontSize: 20,
                                  fontWeight: FontWeight.bold,
                            color: yearlyChange >= 0 ? Colors.red[600] : const Color(0xFF33B864),
                                ),
                              ),
                        const SizedBox(height: 4),
                              Text(
                          'vs Last Year',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.trending_flat, color: Colors.grey[400], size: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Yearly Change',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                          ),
                        ),
                      ],
                      ),
                      const SizedBox(height: 12),
                        Text(
                        'N/A',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                        Text(
                        'vs Last Year',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build Well Depth Card
  Widget _buildWellDepthCard() {
    return Consumer(
      builder: (context, ref, child) {
        final stationData = ref.watch(stationDataProvider);
        
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
                        color: Colors.teal.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.water_drop, color: Colors.teal[600], size: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Well Depth',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.teal[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                stationData.when(
                  data: (data) {
                    final wellDepth = _getWellDepthFromAPI(data);
                    return Text(
                      '${wellDepth.toStringAsFixed(1)} m',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[600],
                      ),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text(
                    'N/A',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total depth',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// Build Monthly Forecast Card
  Widget _buildMonthlyForecastCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
                    gradient: LinearGradient(
                      colors: isDarkMode 
                        ? [
                            Colors.amber.withOpacity(0.2),
                            Colors.amber.withOpacity(0.1),
                          ]
                        : [
                            Colors.amber.withOpacity(0.1),
                            Colors.amber.withOpacity(0.05),
                          ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_month, 
                    color: isDarkMode ? Colors.amber[400] : Colors.amber[600], 
                    size: 20
                  ),
                ),
                const SizedBox(width: 8),
          Expanded(
            child: Text(
                    'Monthly Forecast',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDarkMode ? Colors.amber[400] : Colors.amber[700],
                    ),
            ),
          ),
        ],
            ),
            const SizedBox(height: 12),
            Text(
              '${_getMonthlyForecast().toStringAsFixed(1)} m',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.amber[300] : Colors.amber[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Next month',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getForecastTrendColor().withOpacity(isDarkMode ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getForecastTrend(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
                    gradient: LinearGradient(
                      colors: isDarkMode 
                        ? [
                            Colors.cyan.withOpacity(0.2),
                            Colors.cyan.withOpacity(0.1),
                          ]
                        : [
                            Colors.cyan.withOpacity(0.1),
                            Colors.cyan.withOpacity(0.05),
                          ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.today, 
                    color: isDarkMode ? Colors.cyan[400] : Colors.cyan[600], 
                    size: 20
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Day Forecast',
                    style: TextStyle(
                    fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDarkMode ? Colors.cyan[400] : Colors.cyan[700],
                  ),
                ),
              ),
            ],
          ),
            const SizedBox(height: 12),
          Text(
              '${_getDayForecast().toStringAsFixed(1)} m',
            style: TextStyle(
                fontSize: 20,
              fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.cyan[300] : Colors.cyan[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
              'Tomorrow',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getDayForecastTrendColor().withOpacity(isDarkMode ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getDayForecastTrend(),
                style: TextStyle(
              fontSize: 10,
                  fontWeight: FontWeight.bold,
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
    final alerts = _getActiveAlerts();
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
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    color: Colors.red[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Alerts & Notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: alerts.isNotEmpty ? Colors.red : const Color(0xFF33B864),
                    borderRadius: BorderRadius.circular(12),
                  ),
                child: Text(
                    '${alerts.length}',
                    style: const TextStyle(
                      color: Colors.white,
                    fontWeight: FontWeight.bold,
                      fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
            const SizedBox(height: 16),
            
            if (alerts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF33B864).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF33B864).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: const Color(0xFF33B864)),
                    const SizedBox(width: 12),
          Text(
                      'No active alerts',
                      style: TextStyle(
              fontWeight: FontWeight.bold,
                        color: const Color(0xFF33B864),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...alerts.map((alert) => _buildAlertItem(alert)).toList(),
              
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to detailed alerts screen
                  context.go('/alerts');
                },
                icon: const Icon(Icons.notifications),
                label: const Text('View All Alerts'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual alert item
  Widget _buildAlertItem(Map<String, dynamic> alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getAlertColor(alert['type']).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getAlertColor(alert['type']).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getAlertIcon(alert['type']),
            color: _getAlertColor(alert['type']),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getAlertColor(alert['type']),
                    fontSize: 14,
                  ),
                ),
                Text(
                  alert['message'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Text(
            alert['time'],
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for calculations and data using API
  double _calculateAverageDepthFromAPI(Map<String, dynamic>? data) {
    if (data == null) return 0.0;
    
    // Extract water level data from API response
    final waterLevel = data['latestWaterLevel'] as double? ?? 0.0;
    final historicalData = data['historicalData'] as List<dynamic>? ?? [];
    
    if (historicalData.isEmpty) return waterLevel;
    
    // Calculate average from historical data
    double sum = waterLevel;
    for (var item in historicalData) {
      if (item is Map<String, dynamic>) {
        final level = item['waterLevel'] as double? ?? 0.0;
        sum += level;
      }
    }
    
    return sum / (historicalData.length + 1);
  }

  Map<String, double> _calculateMinMaxDepthFromAPI(Map<String, dynamic>? data) {
    if (data == null) return {'min': 0.0, 'max': 0.0};
    
    final waterLevel = data['latestWaterLevel'] as double? ?? 0.0;
    final historicalData = data['historicalData'] as List<dynamic>? ?? [];
    
    double minDepth = waterLevel;
    double maxDepth = waterLevel;
    
    for (var item in historicalData) {
      if (item is Map<String, dynamic>) {
        final level = item['waterLevel'] as double? ?? 0.0;
        if (level < minDepth) minDepth = level;
        if (level > maxDepth) maxDepth = level;
      }
    }
    
    return {'min': minDepth, 'max': maxDepth};
  }

  double _calculateYearlyChangeFromAPI(Map<String, dynamic>? data) {
    if (data == null) return 0.0;
    
    final currentLevel = data['latestWaterLevel'] as double? ?? 0.0;
    final historicalData = data['historicalData'] as List<dynamic>? ?? [];
    
    if (historicalData.isEmpty) return 0.0;
    
    // Find data from one year ago (simplified - in real app, use proper date filtering)
    final oneYearAgoData = historicalData.length > 12 
        ? historicalData[historicalData.length - 12] 
        : historicalData.first;
    
    double previousLevel = 0.0;
    if (oneYearAgoData is Map<String, dynamic>) {
      previousLevel = oneYearAgoData['waterLevel'] as double? ?? 0.0;
    }
    
    // Positive means water level went down (bad), negative means it went up (good)
    return currentLevel - previousLevel;
  }

  double _getWellDepthFromAPI(Map<String, dynamic>? data) {
    if (data == null) return 0.0;
    
    return data['wellDepth'] as double? ?? 0.0;
  }

  double _getMonthlyForecast() {
    // Mock monthly forecast
    return 16.8 + (DateTime.now().millisecond % 15) / 10;
  }

  double _getDayForecast() {
    // Mock day forecast
    return 15.5 + (DateTime.now().millisecond % 8) / 10;
  }

  String _getForecastTrend() {
    final trend = DateTime.now().millisecond % 3;
    switch (trend) {
      case 0: return 'STABLE';
      case 1: return 'DECLINING';
      case 2: return 'RISING';
      default: return 'STABLE';
    }
  }

  Color _getForecastTrendColor() {
    switch (_getForecastTrend()) {
      case 'STABLE': return Colors.blue;
      case 'DECLINING': return Colors.red;
      case 'RISING': return const Color(0xFF33B864);
      default: return Colors.blue;
    }
  }

  String _getDayForecastTrend() {
    final trend = DateTime.now().millisecond % 3;
    switch (trend) {
      case 0: return 'STABLE';
      case 1: return 'DECLINING';
      case 2: return 'RISING';
      default: return 'STABLE';
    }
  }

  Color _getDayForecastTrendColor() {
    switch (_getDayForecastTrend()) {
      case 'STABLE': return Colors.blue;
      case 'DECLINING': return Colors.red;
      case 'RISING': return const Color(0xFF33B864);
      default: return Colors.blue;
    }
  }

  List<Map<String, dynamic>> _getActiveAlerts() {
    // Mock alerts - in real app, this would come from a service
    final alerts = <Map<String, dynamic>>[];
    
    // Add some mock alerts based on conditions
    if (_getTrafficSignalLevel() == 'critical') {
      alerts.add({
        'type': 'critical',
        'title': 'Critical Water Level',
        'message': 'Water levels are critically low in your area',
        'time': '2h ago',
      });
    }
    
    // In a real app, this would check actual API data for yearly change
    // For now, we'll use mock logic
    final mockYearlyChange = (DateTime.now().millisecond % 20) - 10;
    if (mockYearlyChange > 5) {
      alerts.add({
        'type': 'warning',
        'title': 'Rapid Decline',
        'message': 'Water levels declining faster than normal',
        'time': '1d ago',
      });
    }
    
    if (alerts.isEmpty) {
      // Add a general info alert
      alerts.add({
        'type': 'info',
        'title': 'System Update',
        'message': 'All systems operating normally',
        'time': '3h ago',
      });
    }
    
    return alerts;
  }

  Color _getAlertColor(String type) {
    switch (type) {
      case 'critical': return Colors.red;
      case 'warning': return Colors.orange;
      case 'info': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'critical': return Icons.error;
      case 'warning': return Icons.warning;
      case 'info': return Icons.info;
      default: return Icons.notifications;
    }
  }

  Widget _buildAnalyticsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            showAnalytics = !showAnalytics;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF33B864),
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
            Icon(showAnalytics ? Icons.visibility_off : Icons.analytics, size: 24),
            const SizedBox(width: 12),
            Text(
              showAnalytics ? 'Hide Analytics' : 'Show Analytics',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Icon(showAnalytics ? Icons.keyboard_arrow_up : Icons.arrow_forward, size: 20),
          ],
        ),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF33B864)),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF33B864)),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF33B864)),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF33B864)),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF33B864)),
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

