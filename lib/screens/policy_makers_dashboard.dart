import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Policy Makers Dashboard - Clean minimal version
class PolicyMakersDashboard extends ConsumerStatefulWidget {
  const PolicyMakersDashboard({super.key});

  @override
  ConsumerState<PolicyMakersDashboard> createState() => _PolicyMakersDashboardState();
}

class _PolicyMakersDashboardState extends ConsumerState<PolicyMakersDashboard> {
  String? selectedRegion;
  String? selectedZoneType;
  bool showZoneDetails = false;
  
  // All Indian states and union territories (same as citizen dashboard)
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

  // Mock data for danger zones (expanded to include more states)
  final Map<String, Map<String, dynamic>> dangerZones = {
    'Andhra Pradesh': {
      'red': 12,
      'orange': 8,
      'green': 15,
      'total': 35,
      'notes': 'Coastal regions facing saltwater intrusion. Groundwater management policies needed.',
      'redZones': ['Visakhapatnam', 'Vijayawada', 'Guntur', 'Nellore', 'Kurnool', 'Anantapur', 'Chittoor', 'East Godavari', 'West Godavari', 'Krishna', 'Prakasam', 'Srikakulam'],
      'orangeZones': ['Kadapa', 'Ongole', 'Tirupati', 'Rajahmundry', 'Eluru', 'Tadepalligudem', 'Tanuku', 'Bhimavaram'],
      'greenZones': ['Araku Valley', 'Puttaparthi', 'Mantralayam', 'Srisailam', 'Tirumala', 'Bapatla', 'Narasapur', 'Palakollu', 'Bhimavaram', 'Gudivada', 'Machilipatnam', 'Nidadavolu', 'Samalkot', 'Tenali', 'Vizianagaram'],
    },
    'Delhi': {
      'red': 15,
      'orange': 8,
      'green': 12,
      'total': 35,
      'notes': 'Critical water stress in central Delhi. Immediate intervention required.',
      'redZones': ['Central Delhi', 'New Delhi', 'East Delhi', 'South Delhi', 'West Delhi', 'North Delhi', 'North East Delhi', 'North West Delhi', 'South East Delhi', 'South West Delhi', 'Shahdara', 'Karol Bagh', 'Connaught Place', 'Lajpat Nagar', 'Greater Kailash'],
      'orangeZones': ['Dwarka', 'Rohini', 'Pitampura', 'Janakpuri', 'Vasant Kunj', 'Saket', 'Malviya Nagar', 'Hauz Khas'],
      'greenZones': ['Aerocity', 'Gurgaon Border', 'Noida Border', 'Faridabad Border', 'Ghaziabad Border', 'Sonipat Border', 'Bahadurgarh', 'Najafgarh', 'Bawana', 'Narela', 'Burari', 'Timarpur'],
    },
    'Gujarat': {
      'red': 20,
      'orange': 15,
      'green': 18,
      'total': 53,
      'notes': 'Industrial regions showing severe groundwater depletion. Policy intervention critical.',
      'redZones': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar', 'Jamnagar', 'Junagadh', 'Gandhinagar', 'Nadiad', 'Anand', 'Mehsana', 'Bharuch', 'Navsari', 'Valsad', 'Porbandar', 'Morbi', 'Surendranagar', 'Palanpur', 'Bhuj', 'Godhra'],
      'orangeZones': ['Dahod', 'Narmada', 'Tapi', 'Dang', 'Kheda', 'Panchmahal', 'Sabarkantha', 'Banaskantha', 'Patan', 'Mahesana', 'Aravalli', 'Botad', 'Chhota Udaipur', 'Devbhoomi Dwarka', 'Gir Somnath'],
      'greenZones': ['Kutch', 'Amreli', 'Bhavnagar', 'Rajkot', 'Jamnagar', 'Porbandar', 'Junagadh', 'Gir Somnath', 'Amreli', 'Bhavnagar', 'Botad', 'Surendranagar', 'Morbi', 'Rajkot', 'Jamnagar', 'Devbhoomi Dwarka', 'Porbandar', 'Junagadh'],
    },
    'Haryana': {
      'red': 22,
      'orange': 18,
      'green': 25,
      'total': 65,
      'notes': 'Agricultural regions showing severe depletion. Policy review needed.',
      'redZones': ['Gurgaon', 'Faridabad', 'Panipat', 'Karnal', 'Sonipat', 'Ambala', 'Yamunanagar', 'Kurukshetra', 'Kaithal', 'Jind', 'Hisar', 'Fatehabad', 'Sirsa', 'Bhiwani', 'Rewari', 'Mahendragarh', 'Palwal', 'Nuh', 'Panchkula', 'Rohtak', 'Jhajjar', 'Charkhi Dadri'],
      'orangeZones': ['Bahadurgarh', 'Ballabhgarh', 'Gohana', 'Hansi', 'Narnaul', 'Pehowa', 'Samalkha', 'Sohna', 'Tohana', 'Bawal', 'Dabwali', 'Ellenabad', 'Hodal', 'Ladwa', 'Mandi Dabwali', 'Naraingarh', 'Pataudi', 'Radaur'],
      'greenZones': ['Pinjore', 'Kalka', 'Morni', 'Barwala', 'Beri', 'Bilaspur', 'Chhachhrauli', 'Dharuhera', 'Fatehpur', 'Gharaunda', 'Hassanpur', 'Indri', 'Israna', 'Jakhal', 'Kalanaur', 'Loharu', 'Maham', 'Mustafabad', 'Narwana', 'Nilokheri', 'Punahana', 'Rania', 'Ratia', 'Safidon', 'Taraori'],
    },
    'Karnataka': {
      'red': 18,
      'orange': 12,
      'green': 22,
      'total': 52,
      'notes': 'Urban areas showing rapid groundwater decline. Conservation policies needed.',
      'redZones': ['Bangalore Urban', 'Bangalore Rural', 'Mysore', 'Hubli-Dharwad', 'Mangalore', 'Belgaum', 'Gulbarga', 'Davanagere', 'Bellary', 'Bijapur', 'Tumkur', 'Raichur', 'Kolar', 'Chitradurga', 'Shimoga', 'Hassan', 'Mandya', 'Chikmagalur'],
      'orangeZones': ['Udupi', 'Dakshina Kannada', 'Kodagu', 'Chamrajnagar', 'Haveri', 'Gadag', 'Bagalkot', 'Koppal', 'Yadgir', 'Bidar', 'Chikkaballapur', 'Ramanagara'],
      'greenZones': ['Coorg', 'Chikmagalur', 'Hassan', 'Mysore', 'Mandya', 'Chamarajanagar', 'Kodagu', 'Udupi', 'Dakshina Kannada', 'Shimoga', 'Chitradurga', 'Tumkur', 'Kolar', 'Bangalore Rural', 'Ramanagara', 'Chikkaballapur', 'Bidar', 'Yadgir', 'Koppal', 'Bagalkot', 'Gadag', 'Haveri'],
    },
    'Maharashtra': {
      'red': 25,
      'orange': 20,
      'green': 15,
      'total': 60,
      'notes': 'Industrial and urban regions facing severe water stress. Policy intervention urgent.',
      'redZones': ['Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Aurangabad', 'Solapur', 'Amravati', 'Kolhapur', 'Sangli', 'Satara', 'Ratnagiri', 'Sindhudurg', 'Thane', 'Raigad', 'Pune', 'Ahmednagar', 'Beed', 'Jalna', 'Latur', 'Osmanabad', 'Nanded', 'Parbhani', 'Hingoli', 'Washim', 'Yavatmal'],
      'orangeZones': ['Gadchiroli', 'Chandrapur', 'Bhandara', 'Gondia', 'Wardha', 'Akola', 'Buldhana', 'Jalgaon', 'Dhule', 'Nandurbar', 'Palghar', 'Mumbai Suburban', 'Bhiwandi', 'Kalyan', 'Ulhasnagar'],
      'greenZones': ['Konkan', 'Western Ghats', 'Melghat', 'Tadoba', 'Pench', 'Nagzira', 'Bor', 'Umred', 'Koyna', 'Radhanagari', 'Chandoli', 'Sahyadri', 'Matheran', 'Lonavala', 'Khandala'],
    },
    'Punjab': {
      'red': 18,
      'orange': 12,
      'green': 20,
      'total': 50,
      'notes': 'Groundwater levels declining rapidly in agricultural areas.',
      'redZones': ['Amritsar', 'Ludhiana', 'Jalandhar', 'Patiala', 'Bathinda', 'Mohali', 'Firozpur', 'Batala', 'Moga', 'Abohar', 'Malerkotla', 'Khanna', 'Phagwara', 'Muktsar', 'Barnala', 'Rajpura', 'Kapurthala', 'Sunam'],
      'orangeZones': ['Fazilka', 'Gurdaspur', 'Hoshiarpur', 'Mansa', 'Muktsar', 'Nawanshahr', 'Rupnagar', 'Sangrur', 'Tarn Taran', 'Fatehgarh Sahib', 'Moga', 'Sri Muktsar Sahib'],
      'greenZones': ['Anandpur Sahib', 'Baba Bakala', 'Banga', 'Bhagta Bhai Ka', 'Budhlada', 'Chamkaur Sahib', 'Dasuya', 'Dera Baba Nanak', 'Dharamkot', 'Dina Nagar', 'Dirba', 'Fatehgarh Churian', 'Ghanaur', 'Gidderbaha', 'Gobindgarh', 'Jaitu', 'Jalalabad', 'Kalanaur', 'Khamanon', 'Kotkapura'],
    },
    'Rajasthan': {
      'red': 35,
      'orange': 20,
      'green': 15,
      'total': 70,
      'notes': 'Desert regions showing extreme water stress. Conservation policies critical.',
      'redZones': ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Bikaner', 'Ajmer', 'Bharatpur', 'Bhilwara', 'Alwar', 'Ganganagar', 'Sikar', 'Pali', 'Tonk', 'Jhunjhunu', 'Churu', 'Nagaur', 'Dausa', 'Karauli', 'Sawai Madhopur', 'Dungarpur', 'Rajsamand', 'Banswara', 'Pratapgarh', 'Sirohi', 'Jalore', 'Barmer', 'Jaisalmer', 'Jhalawar', 'Baran', 'Bundi', 'Chittorgarh', 'Hanumangarh', 'Jhunjhunu', 'Kishangarh', 'Beawar'],
      'orangeZones': ['Abu Road', 'Alwar', 'Anupgarh', 'Banswara', 'Barmer', 'Bayana', 'Beawar', 'Bhiwadi', 'Bikaner', 'Chittorgarh', 'Dausa', 'Deeg', 'Dholpur', 'Dungarpur', 'Fatehpur', 'Gangapur', 'Hanumangarh', 'Jhalawar', 'Karauli', 'Kishangarh'],
      'greenZones': ['Mount Abu', 'Pushkar', 'Ajmer', 'Bundi', 'Chittorgarh', 'Dungarpur', 'Jaisalmer', 'Jhalawar', 'Kota', 'Pratapgarh', 'Rajsamand', 'Sawai Madhopur', 'Sirohi', 'Tonk', 'Udaipur'],
    },
    'Tamil Nadu': {
      'red': 22,
      'orange': 15,
      'green': 18,
      'total': 55,
      'notes': 'Coastal and urban regions facing severe groundwater depletion.',
      'redZones': ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem', 'Tirunelveli', 'Tiruppur', 'Erode', 'Vellore', 'Thoothukkudi', 'Dindigul', 'Thanjavur', 'Ranipet', 'Kanchipuram', 'Chengalpattu', 'Tiruvallur', 'Villupuram', 'Cuddalore', 'Nagapattinam', 'Karur', 'Namakkal', 'Theni'],
      'orangeZones': ['Krishnagiri', 'Dharmapuri', 'Tiruvannamalai', 'Vellore', 'Ranipet', 'Kanchipuram', 'Chengalpattu', 'Tiruvallur', 'Villupuram', 'Cuddalore', 'Nagapattinam', 'Pudukkottai', 'Sivaganga', 'Ramanathapuram', 'Virudhunagar'],
      'greenZones': ['Nilgiris', 'Coimbatore', 'Erode', 'Salem', 'Namakkal', 'Karur', 'Tiruchirappalli', 'Perambalur', 'Ariyalur', 'Thanjavur', 'Nagapattinam', 'Tiruvarur', 'Mayiladuthurai', 'Cuddalore', 'Villupuram', 'Kallakurichi', 'Tiruvannamalai'],
    },
    'Uttar Pradesh': {
      'red': 30,
      'orange': 25,
      'green': 20,
      'total': 75,
      'notes': 'Most populous state facing severe groundwater stress. Policy intervention critical.',
      'redZones': ['Lucknow', 'Kanpur', 'Agra', 'Varanasi', 'Meerut', 'Allahabad', 'Bareilly', 'Ghaziabad', 'Noida', 'Moradabad', 'Aligarh', 'Saharanpur', 'Gorakhpur', 'Firozabad', 'Muzaffarnagar', 'Mathura', 'Shahjahanpur', 'Rampur', 'Etawah', 'Mirzapur', 'Bulandshahr', 'Sambhal', 'Amroha', 'Hardoi', 'Fatehpur', 'Raebareli', 'Orai', 'Sitapur', 'Bahraich', 'Modinagar'],
      'orangeZones': ['Banda', 'Barabanki', 'Basti', 'Bijnor', 'Chandauli', 'Chitrakoot', 'Deoria', 'Etah', 'Farrukhabad', 'Gonda', 'Hamirpur', 'Hathras', 'Jalaun', 'Jaunpur', 'Kannauj', 'Kaushambi', 'Kushinagar', 'Lalitpur', 'Maharajganj', 'Mainpuri', 'Mau', 'Pilibhit', 'Pratapgarh', 'Sant Kabir Nagar', 'Shravasti'],
      'greenZones': ['Agra', 'Aligarh', 'Etah', 'Firozabad', 'Hathras', 'Mathura', 'Mainpuri', 'Bareilly', 'Badaun', 'Pilibhit', 'Shahjahanpur', 'Sambhal', 'Moradabad', 'Rampur', 'Bijnor', 'Amroha', 'Saharanpur', 'Muzaffarnagar', 'Meerut', 'Ghaziabad'],
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Policy Makers Dashboard'),
        backgroundColor: Colors.orange,
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
            
            // Danger Zone Selection
            _buildDangerZoneSection(),
            const SizedBox(height: 24),
            
            // Zone Details (shown when region is selected)
            if (showZoneDetails && selectedRegion != null)
              _buildZoneDetailsSection(),
          ],
        ),
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
            Colors.orange,
            Colors.orange[700]!,
            Colors.deepOrange[600]!,
          ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
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
                  Icons.admin_panel_settings,
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
                    'Welcome, Policy Maker',
                    style: TextStyle(
                      color: Colors.white,
                        fontSize: 26,
                      fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Monitor danger zones and access critical water management insights',
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

  /// Build danger zone selection section
  Widget _buildDangerZoneSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withOpacity(0.2),
                        Colors.orange.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                  Icons.warning_amber,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Danger Zone Monitoring',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Select a region to view danger zone statistics and access detailed data',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            
            // Region Selection Dropdown
            _buildDropdown(
              label: 'Select Region',
              value: selectedRegion,
              items: indianStates,
              onChanged: (value) {
                setState(() {
                  selectedRegion = value;
                  selectedZoneType = null;
                  showZoneDetails = value != null && dangerZones.containsKey(value);
                });
              },
            ),
            
            const SizedBox(height: 16),

            // Zone Type Selection (if region with danger zone data is selected)
            if (selectedRegion != null && dangerZones.containsKey(selectedRegion))
              _buildDropdown(
                label: 'Zone Type',
                value: selectedZoneType,
                items: const ['All Zones', 'Red Zones', 'Orange Zones', 'Green Zones'],
                onChanged: (value) {
                  setState(() {
                    selectedZoneType = value;
                  });
                },
              ),
            
            // Message for regions without danger zone data
            if (selectedRegion != null && !dangerZones.containsKey(selectedRegion))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Danger zone data not available for $selectedRegion. Please select a region with available data.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[700],
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

  /// Build zone details section
  Widget _buildZoneDetailsSection() {
    final regionData = dangerZones[selectedRegion!]!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Zone Statistics Cards
        _buildZoneStatisticsCards(regionData),
        const SizedBox(height: 20),
        
        // Dynamic Zone Containers
        _buildDynamicZoneContainers(regionData),
        const SizedBox(height: 20),
        
        // Researcher Notes
        _buildResearcherNotes(regionData['notes']),
        const SizedBox(height: 20),
        
        // Detailed Zone Information
        _buildDetailedZoneInfo(),
      ],
    );
  }

  /// Build zone statistics cards
  Widget _buildZoneStatisticsCards(Map<String, dynamic> regionData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zone Statistics - $selectedRegion',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 16),
        Row(
            children: [
            Expanded(
              child: _buildZoneCard(
                'Red Zones',
                regionData['red'].toString(),
                'Critical',
                Colors.red,
                Icons.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildZoneCard(
                'Orange Zones',
                regionData['orange'].toString(),
                'Moderate',
                Colors.orange,
                Icons.warning_amber,
              ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildZoneCard(
                'Green Zones',
                regionData['green'].toString(),
                'Safe',
                Colors.green,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildZoneCard(
                'Total Zones',
                regionData['total'].toString(),
                'All',
                Colors.blue,
                Icons.location_on,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build dynamic zone containers
  Widget _buildDynamicZoneContainers(Map<String, dynamic> regionData) {
    List<String> zonesToShow = [];
    String zoneTypeTitle = '';
    Color zoneColor = Colors.grey;
    IconData zoneIcon = Icons.location_on;

    // Determine which zones to show based on selection
    if (selectedZoneType == null || selectedZoneType == 'All Zones') {
      // Show all zones
      zonesToShow = [
        ...(regionData['redZones'] as List<String>),
        ...(regionData['orangeZones'] as List<String>),
        ...(regionData['greenZones'] as List<String>),
      ];
      zoneTypeTitle = 'All Zones';
      zoneColor = Colors.blue;
      zoneIcon = Icons.location_on;
    } else if (selectedZoneType == 'Red Zones') {
      zonesToShow = regionData['redZones'] as List<String>;
      zoneTypeTitle = 'Red Zones (Critical)';
      zoneColor = Colors.red;
      zoneIcon = Icons.warning;
    } else if (selectedZoneType == 'Orange Zones') {
      zonesToShow = regionData['orangeZones'] as List<String>;
      zoneTypeTitle = 'Orange Zones (Moderate)';
      zoneColor = Colors.orange;
      zoneIcon = Icons.warning_amber;
    } else if (selectedZoneType == 'Green Zones') {
      zonesToShow = regionData['greenZones'] as List<String>;
      zoneTypeTitle = 'Green Zones (Safe)';
      zoneColor = Colors.green;
      zoneIcon = Icons.check_circle;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Zone Type Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: zoneColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                zoneIcon,
                color: zoneColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              zoneTypeTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: zoneColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: zoneColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: zoneColor.withOpacity(0.3)),
              ),
              child: Text(
                '${zonesToShow.length} zones',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: zoneColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Zone Containers Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: zonesToShow.length,
          itemBuilder: (context, index) {
            final zoneName = zonesToShow[index];
            return _buildZoneContainer(zoneName, zoneColor, zoneIcon);
          },
        ),
      ],
    );
  }

  /// Build individual zone container
  Widget _buildZoneContainer(String zoneName, Color zoneColor, IconData zoneIcon) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showZoneDetails(zoneName, zoneColor),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                zoneColor.withOpacity(0.1),
                zoneColor.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: zoneColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: zoneColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  zoneIcon,
                  color: zoneColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  zoneName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: zoneColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: zoneColor.withOpacity(0.6),
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show zone details dialog
  void _showZoneDetails(String zoneName, Color zoneColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: zoneColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                zoneColor == Colors.red ? Icons.warning :
                zoneColor == Colors.orange ? Icons.warning_amber :
                zoneColor == Colors.green ? Icons.check_circle : Icons.location_on,
                color: zoneColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                zoneName,
                style: TextStyle(
                  color: zoneColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zone Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            _buildZoneInfoItem('Region', selectedRegion!),
            _buildZoneInfoItem('Zone Type', 
              zoneColor == Colors.red ? 'Critical (Red Zone)' :
              zoneColor == Colors.orange ? 'Moderate (Orange Zone)' :
              zoneColor == Colors.green ? 'Safe (Green Zone)' : 'Unknown'
            ),
            _buildZoneInfoItem('Status', 
              zoneColor == Colors.red ? 'Immediate intervention required' :
              zoneColor == Colors.orange ? 'Monitoring and preventive measures needed' :
              zoneColor == Colors.green ? 'Continue current management practices' : 'Unknown'
            ),
            _buildZoneInfoItem('Priority', 
              zoneColor == Colors.red ? 'High Priority' :
              zoneColor == Colors.orange ? 'Medium Priority' :
              zoneColor == Colors.green ? 'Low Priority' : 'Unknown'
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Zone $zoneName selected for detailed analysis'),
                  backgroundColor: zoneColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: zoneColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Analyze'),
          ),
        ],
      ),
    );
  }

  /// Build zone info item
  Widget _buildZoneInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build zone card
  Widget _buildZoneCard(String title, String count, String status, Color color, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
                  Text(
              count,
              style: TextStyle(
                fontSize: 24,
                      fontWeight: FontWeight.bold,
                color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build researcher notes section
  Widget _buildResearcherNotes(String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
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
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.science,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Researcher Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            notes,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Build detailed zone information
  Widget _buildDetailedZoneInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.withOpacity(0.1),
            Colors.grey.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
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
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Zone Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildZoneDetailItem('Red Zones', 'Critical water stress - Immediate intervention required'),
          _buildZoneDetailItem('Orange Zones', 'Moderate stress - Monitoring and preventive measures needed'),
          _buildZoneDetailItem('Green Zones', 'Safe levels - Continue current management practices'),
        ],
      ),
    );
  }

  /// Build zone detail item
  Widget _buildZoneDetailItem(String zone, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: zone.contains('Red') ? Colors.red : 
                     zone.contains('Orange') ? Colors.orange : Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zone,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build dropdown widget
  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                'Select $label',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
              dropdownColor: Colors.white,
              icon: Icon(
                Icons.arrow_drop_down,
                color: Colors.orange[700],
              ),
              isExpanded: true,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Colors.black87,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
