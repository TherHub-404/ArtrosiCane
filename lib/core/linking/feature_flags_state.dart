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
    String? inviteLocation,
    String? lastError,
    DateTime? lastUpdatedAt,
    bool? isLoading,
  }) {
    return FeatureFlagsState(
      flags: flags ?? this.flags,
      activeToken: activeToken ?? this.activeToken,
      inviteLocation: inviteLocation ?? this.inviteLocation,
      lastError: lastError,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isLoading: isLoading ?? this.isLoading,
    );
  }

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
