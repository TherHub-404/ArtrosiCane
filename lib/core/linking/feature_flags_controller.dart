import 'dart:convert';

import 'package:artrosi_cane/core/linking/feature_flags_state.dart';
import 'package:artrosi_cane/core/logging/app_logger.dart';
import 'package:artrosi_cane/core/providers/shared_prefs_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _flagsStorageKey = 'feature_flags_json';
const _lastTokenStorageKey = 'feature_flags_last_token';
const _flagsUpdatedAtStorageKey = 'feature_flags_updated_at';
const _inviteLocationStorageKey = 'invite_location';

final featureFlagsControllerProvider =
    StateNotifierProvider<FeatureFlagsController, FeatureFlagsState>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return FeatureFlagsController(prefs);
    });

class FeatureFlagsController extends StateNotifier<FeatureFlagsState> {
  FeatureFlagsController(this._prefs) : super(FeatureFlagsState.initial()) {
    _hydrateFromStorage();
  }

  final SharedPreferences _prefs;

  void setLoading(bool value) {
    state = state.copyWith(isLoading: value, lastError: state.lastError);
  }

  Future<void> persistFlags({
    required String token,
    required Map<String, dynamic> flags,
  }) async {
    final now = DateTime.now().toUtc();
    await _prefs.setString(_flagsStorageKey, jsonEncode(flags));
    await _prefs.setString(_lastTokenStorageKey, token);
    await _prefs.setString(_flagsUpdatedAtStorageKey, now.toIso8601String());

    state = state.copyWith(
      flags: Map<String, dynamic>.unmodifiable(flags),
      activeToken: token,
      lastUpdatedAt: now,
      lastError: null,
      isLoading: false,
    );
  }

  Future<void> persistInviteLocationFromLink(String? location) async {
    final normalized = _normalizeInviteLocation(location);
    if (normalized == null) {
      await _prefs.remove(_inviteLocationStorageKey);
      state = state.copyWith(inviteLocation: null);
      return;
    }

    await _prefs.setString(_inviteLocationStorageKey, normalized);
    state = state.copyWith(inviteLocation: normalized);
  }

  void setError(String message, {String? token}) {
    state = state.copyWith(
      activeToken: token ?? state.activeToken,
      lastError: message,
      isLoading: false,
    );
  }

  String? getStoredToken() {
    final token = _prefs.getString(_lastTokenStorageKey);
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  void _hydrateFromStorage() {
    final storedLocation = _normalizeInviteLocation(
      _prefs.getString(_inviteLocationStorageKey),
    );
    final rawUpdatedAt = _prefs.getString(_flagsUpdatedAtStorageKey);
    final storedToken = getStoredToken();

    final rawFlags = _prefs.getString(_flagsStorageKey);
    if (rawFlags == null || rawFlags.isEmpty) {
      state = state.copyWith(
        activeToken: storedToken,
        inviteLocation: storedLocation,
        lastUpdatedAt: rawUpdatedAt == null
            ? null
            : DateTime.tryParse(rawUpdatedAt),
        lastError: null,
      );
      return;
    }

    try {
      final decoded = jsonDecode(rawFlags);
      if (decoded is! Map) {
        state = state.copyWith(
          activeToken: storedToken,
          inviteLocation: storedLocation,
          lastUpdatedAt: rawUpdatedAt == null
              ? null
              : DateTime.tryParse(rawUpdatedAt),
          lastError: null,
        );
        return;
      }

      state = state.copyWith(
        flags: Map<String, dynamic>.unmodifiable(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        ),
        activeToken: storedToken,
        inviteLocation: storedLocation,
        lastUpdatedAt: rawUpdatedAt == null
            ? null
            : DateTime.tryParse(rawUpdatedAt),
        lastError: null,
      );
    } catch (error) {
      AppLogger.debug('Unable to hydrate flags from storage: $error');
    }
  }

  String? _normalizeInviteLocation(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    // Accept common variants/typos and map them to one canonical location.
    if (normalized == 'bibbione' ||
        normalized == 'bibione' ||
        normalized == 'bibbine' ||
        normalized == 'bibiobe' ||
        normalized.startsWith('bibb')) {
      return 'bibione';
    }
    if (normalized == 'skip-onboard' ||
        normalized == 'skip_onboard' ||
        normalized == 'skiponboard' ||
        normalized == 'skip-onboarding' ||
        normalized == 'skip_onboarding' ||
        normalized == 'skiponboarding') {
      return 'skip-onboard';
    }
    if (normalized == 'normal' || normalized == 'default') {
      return 'normal';
    }
    return normalized;
  }
}
