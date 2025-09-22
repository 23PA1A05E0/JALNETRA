import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../themes/dashboard_themes.dart';

/// Role selection screen for choosing user type
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole _selectedRole = UserRole.user;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              const SizedBox(height: 40),
              Text(
                'Choose Your Role',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Select how you\'d like to use JALNETRA',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Role Selection Tabs
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2D2D2D) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildRoleTab(
                        context,
                        'Citizen',
                        Icons.person,
                        DashboardThemes.CitizenTheme.primaryColor,
                        UserRole.user,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRoleTab(
                        context,
                        'Researcher',
                        Icons.search,
                        DashboardThemes.ResearcherTheme.primaryColor,
                        UserRole.researcher,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRoleTab(
                        context,
                        'Policy Makers',
                        Icons.admin_panel_settings,
                        DashboardThemes.PolicyMakerTheme.primaryColor,
                        UserRole.policyMaker,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Features Section
              _buildFeaturesSection(context),

              const SizedBox(height: 32),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _selectRole(ref, _selectedRole, context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getRoleColor(_selectedRole),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'Continue as ${_getRoleDisplayName(_selectedRole)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Footer note
              Text(
                'You can change your role anytime in settings',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white60 : Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    UserRole role,
  ) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: isSelected ? Colors.white : color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final color = _getRoleColor(_selectedRole);
    final features = _getRoleFeatures(_selectedRole);
    final description = _getRoleDescription(_selectedRole);

    return Container(
      width: double.infinity,
      height: 320, // Fixed height to ensure consistency
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark 
          ? color.withOpacity(0.1) 
          : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.3 : 0.2), 
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getRoleIcon(_selectedRole),
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getRoleDisplayName(_selectedRole),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Key Features:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: features
                    .map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle, size: 18, color: color),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: isDark ? Colors.white70 : Colors.grey[700],
                                      height: 1.4,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.user:
        return DashboardThemes.CitizenTheme.primaryColor;
      case UserRole.researcher:
        return DashboardThemes.ResearcherTheme.primaryColor;
      case UserRole.policyMaker:
        return DashboardThemes.PolicyMakerTheme.primaryColor;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.user:
        return Icons.person;
      case UserRole.researcher:
        return Icons.search;
      case UserRole.policyMaker:
        return Icons.admin_panel_settings;
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.user:
        return 'Citizen';
      case UserRole.researcher:
        return 'Researcher';
      case UserRole.policyMaker:
        return 'Policy Maker';
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.user:
        return 'Quick insights about water safety in your area. Get alerts and plan your daily water needs.';
      case UserRole.researcher:
        return 'Advanced tools for groundwater research. Download datasets, analyze trends, and export data.';
      case UserRole.policyMaker:
        return 'Critical water management insights and policy support tools for evidence-based decision making.';
    }
  }

  List<String> _getRoleFeatures(UserRole role) {
    switch (role) {
      case UserRole.user:
        return const [
          'Traffic light status (Green/Orange/Red)',
          'Daily water planning',
          'Local alerts & notifications',
          'Simple, easy-to-understand interface',
        ];
      case UserRole.researcher:
        return const [
          'Access raw DWLR data',
          'Advanced visualization tools',
          'Trend analysis & forecasting',
          'Export datasets & analytics',
        ];
      case UserRole.policyMaker:
        return const [
          'Critical regions/wells identification',
          'Water stress analysis',
          'Recharge potential assessment',
          'Trend monitoring & forecasting',
          'Alerts & early warnings',
          'Research/knowledge support',
        ];
    }
  }

  void _selectRole(WidgetRef ref, UserRole role, BuildContext context) {
    ref.read(userRoleProvider.notifier).setRole(role);

    // Navigate to appropriate dashboard using push instead of go
    // This allows users to go back to role selection
    switch (role) {
      case UserRole.user:
        context.push('/citizen-dashboard');
        break;
      case UserRole.researcher:
        context.push('/researcher-dashboard');
        break;
      case UserRole.policyMaker:
        context.push('/policy-makers-dashboard');
        break;
    }
  }
}
