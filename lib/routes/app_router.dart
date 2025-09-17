import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../screens/onboarding_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/citizen_dashboard.dart';
import '../screens/researcher_dashboard.dart';
import '../screens/policy_makers_dashboard.dart';
import '../screens/home_dashboard.dart';
import '../screens/stations_list_screen.dart';
import '../screens/station_details_screen.dart';
import '../screens/map_screen.dart';
import '../screens/reports_alerts_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/location_search_screen.dart';

/// App router configuration
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/role-selection',
      name: 'role-selection',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/citizen-dashboard',
      name: 'citizen-dashboard',
      builder: (context, state) => const CitizenDashboard(),
    ),
    GoRoute(
      path: '/researcher-dashboard',
      name: 'researcher-dashboard',
      builder: (context, state) => const ResearcherDashboard(),
    ),
    GoRoute(
      path: '/policy-makers-dashboard',
      name: 'policy-makers-dashboard',
      builder: (context, state) => const PolicyMakersDashboard(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeDashboard(),
    ),
    GoRoute(
      path: '/stations',
      name: 'stations',
      builder: (context, state) => const StationsListScreen(),
    ),
    GoRoute(
      path: '/station/:stationId',
      name: 'station-detail',
      builder: (context, state) {
        final stationId = state.pathParameters['stationId']!;
        return StationDetailsScreen(stationId: stationId);
      },
    ),
    GoRoute(
      path: '/map',
      name: 'map',
      builder: (context, state) => const MapScreen(),
    ),
    GoRoute(
      path: '/alerts',
      name: 'alerts',
      builder: (context, state) => const ReportsAlertsScreen(),
    ),
    GoRoute(
      path: '/reports',
      name: 'reports',
      builder: (context, state) => const ReportsAlertsScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/location-search',
      name: 'location-search',
      builder: (context, state) => const LocationSearchScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Page not found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'The page you are looking for does not exist.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);
