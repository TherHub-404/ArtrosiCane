const _inviteLocationUnchanged = Object();

class FeatureFlagsState {
  const FeatureFlagsState({
    required this.flags,
    this.activeToken,
    this.inviteLocation,
    this.lastError,
    this.lastUpdatedAt,
    this.isLoading = false,
  });

  factory FeatureFlagsState.initial() => const FeatureFlagsState(flags: {});

  final Map<String, dynamic> flags;
  final String? activeToken;
  final String? inviteLocation;
  final String? lastError;
  final DateTime? lastUpdatedAt;
  final bool isLoading;

  FeatureFlagsState copyWith({
    Map<String, dynamic>? flags,
    String? activeToken,
    Object? inviteLocation = _inviteLocationUnchanged,
    String? lastError,
    DateTime? lastUpdatedAt,
    bool? isLoading,
  }) {
    return FeatureFlagsState(
      flags: flags ?? this.flags,
      activeToken: activeToken ?? this.activeToken,
      inviteLocation: identical(inviteLocation, _inviteLocationUnchanged)
          ? this.inviteLocation
          : inviteLocation as String?,
      lastError: lastError,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// True when the install/deep-link asked the app to skip the onboarding
  /// flow (welcome + quiz) and route the user straight to login / home.
  bool get shouldSkipOnboarding => inviteLocation == 'skip-onboard';

  /// True when the install/deep-link is the Bibione partner flow.
  bool get isBibioneFlow => inviteLocation == 'bibione';

  bool isEnabled(String key, {bool defaultValue = false}) {
    final value = flags[key];
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return defaultValue;
  }
}
