import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User role enumeration
enum UserRole {
  user, // Represents a citizen/individual
  researcher,
  policyMaker, // Represents policy makers
}

/// User state class (represents citizen/researcher state)
class UserState {
  final UserRole role;
  final String? location;
  final bool hasCompletedOnboarding;
  final DateTime? lastActive;

  const UserState({
    this.role = UserRole.user,
    this.location,
    this.hasCompletedOnboarding = false,
    this.lastActive,
  });

  UserState copyWith({
    UserRole? role,
    String? location,
    bool? hasCompletedOnboarding,
    DateTime? lastActive,
  }) {
    return UserState(
      role: role ?? this.role,
      location: location ?? this.location,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}

/// User state notifier
class UserNotifier extends StateNotifier<UserState> {
  UserNotifier() : super(const UserState());

  /// Set user role (citizen or researcher)
  void setRole(UserRole role) {
    state = state.copyWith(role: role, lastActive: DateTime.now());
  }

  /// Set citizen/researcher location
  void setLocation(String location) {
    state = state.copyWith(location: location, lastActive: DateTime.now());
  }

  /// Mark onboarding as completed
  void completeOnboarding() {
    state = state.copyWith(
      hasCompletedOnboarding: true,
      lastActive: DateTime.now(),
    );
  }

  /// Update last active time
  void updateLastActive() {
    state = state.copyWith(lastActive: DateTime.now());
  }

  /// Reset user state
  void reset() {
    state = const UserState();
  }
}

/// Provider for user state (citizen/researcher)
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});

/// Provider for user role (citizen/researcher)
final userRoleProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});

/// Provider for citizen/researcher location
final userLocationProvider = Provider<String?>((ref) {
  return ref.watch(userProvider).location;
});

/// Provider for onboarding status
final onboardingStatusProvider = Provider<bool>((ref) {
  return ref.watch(userProvider).hasCompletedOnboarding;
});
