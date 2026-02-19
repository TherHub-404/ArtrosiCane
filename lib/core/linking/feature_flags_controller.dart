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

  Future<void> persistInviteLocation(String location) async {
    final normalized = location.trim().toLowerCase();
    if (normalized.isEmpty) {
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
    final rawFlags = _prefs.getString(_flagsStorageKey);
    if (rawFlags == null || rawFlags.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(rawFlags);
      if (decoded is! Map) {
        return;
      }

      final rawUpdatedAt = _prefs.getString(_flagsUpdatedAtStorageKey);
      state = state.copyWith(
        flags: Map<String, dynamic>.unmodifiable(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        ),
        activeToken: getStoredToken(),
        inviteLocation: _prefs.getString(_inviteLocationStorageKey),
        lastUpdatedAt: rawUpdatedAt == null
            ? null
            : DateTime.tryParse(rawUpdatedAt),
        lastError: null,
      );
    } catch (error) {
      AppLogger.debug('Unable to hydrate flags from storage: $error');
    }
  }
}
