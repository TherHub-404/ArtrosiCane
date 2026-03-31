import 'dart:convert';

import 'package:artrosi_cane/core/logging/app_logger.dart';
import 'package:artrosi_cane/core/providers/shared_prefs_provider.dart';
import 'package:artrosi_cane/core/providers/supabase_provider.dart';
import 'package:artrosi_cane/features/daily_check/domain/entities/daily_check_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyCheckRepository {
  DailyCheckRepository(this._prefs, this._client);

  final SharedPreferences _prefs;
  final SupabaseClient _client;

  static const _defaultSensitivity = {
    DailyRiskFactor.caldo: 2,
    DailyRiskFactor.sabbia: 3,
    DailyRiskFactor.scale: 3,
    DailyRiskFactor.scivoloso: 2,
    DailyRiskFactor.auto: 1,
    DailyRiskFactor.acqua: 1,
  };
  static const _remoteQueueKey = 'dailyLogRemoteQueue';

  Map<DailyRiskFactor, int> loadSensitivities({String? dogId}) {
    final key = _sensitivityKey(dogId);
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return Map<DailyRiskFactor, int>.from(_defaultSensitivity);
    }
    final jsonMap = json.decode(raw) as Map<String, dynamic>;
    final out = <DailyRiskFactor, int>{};
    for (final factor in DailyRiskFactor.values) {
      out[factor] =
          (jsonMap[factor.name] as num?)?.toInt() ??
          _defaultSensitivity[factor]!;
    }
    return out;
  }

  Future<void> saveDailyLog({
    required DailyCheckInput input,
    required DailyCheckResult result,
  }) async {
    await _saveLocalLog(input, result);
    await _recomputeAndPersistSensitivities(input.dogId);
    await _enqueueRemoteLog(input, result);
    await _flushRemoteQueue();
  }

  Future<void> _saveLocalLog(
    DailyCheckInput input,
    DailyCheckResult result,
  ) async {
    final key = _dailyLogKey(input.dogId);
    final existingRaw = _prefs.getString(key);
    final list = existingRaw == null
        ? <Map<String, dynamic>>[]
        : (json.decode(existingRaw) as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

    list.add({
      'ts': DateTime.now().toIso8601String(),
      'symptom': input.symptomLevel.index,
      'load': input.plannedLoad.index,
      'recovery': input.recoveryDelta.index,
      'riskFactors': input.riskFactors.map((f) => f.name).toList(),
      'rawScore': input.rawScore,
      'score': result.score,
      'semaphore': result.semaphore.name,
    });

    final trimmed = list.length > 45 ? list.sublist(list.length - 45) : list;
    await _prefs.setString(key, json.encode(trimmed));
  }

  Future<void> _recomputeAndPersistSensitivities(String? dogId) async {
    final key = _dailyLogKey(dogId);
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return;

    final entries = (json.decode(raw) as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    if (entries.length < 7) {
      final fallback = Map<DailyRiskFactor, int>.from(_defaultSensitivity);
      await _prefs.setString(
        _sensitivityKey(dogId),
        json.encode({for (final e in fallback.entries) e.key.name: e.value}),
      );
      return;
    }

    final updated = <DailyRiskFactor, int>{};
    for (final factor in DailyRiskFactor.values) {
      final withFactor = <double>[];
      final withoutFactor = <double>[];
      for (final item in entries) {
        final factors = ((item['riskFactors'] as List<dynamic>?) ?? <dynamic>[])
            .map((e) => e.toString())
            .toSet();
        final proxy =
            ((item['symptom'] as num?)?.toDouble() ?? 0) +
            ((item['recovery'] as num?)?.toDouble() ?? 0);
        if (factors.contains(factor.name)) {
          withFactor.add(proxy);
        } else {
          withoutFactor.add(proxy);
        }
      }
      final double withMean = withFactor.isEmpty
          ? 0.0
          : withFactor.reduce((a, b) => a + b) / withFactor.length;
      final double withoutMean = withoutFactor.isEmpty
          ? 0.0
          : withoutFactor.reduce((a, b) => a + b) / withoutFactor.length;
      final double delta = withMean - withoutMean;
      updated[factor] = _deltaToWeight(delta);
    }

    await _prefs.setString(
      _sensitivityKey(dogId),
      json.encode({for (final e in updated.entries) e.key.name: e.value}),
    );
  }

  int _deltaToWeight(double delta) {
    if (delta < 0.2) return 0;
    if (delta < 0.5) return 1;
    if (delta < 0.8) return 2;
    if (delta < 1.2) return 3;
    if (delta < 1.6) return 4;
    return 5;
  }

  Future<void> _enqueueRemoteLog(
    DailyCheckInput input,
    DailyCheckResult result,
  ) async {
    final payload = {
      'owner_id': _client.auth.currentUser?.id,
      'dog_id': input.dogId,
      'symptom_level': input.symptomLevel.index,
      'load_planned': input.plannedLoad.index,
      'risk_factors': input.riskFactors.map((e) => e.name).toList(),
      'recovery_delta': input.recoveryDelta.index,
      'diagnosis_status': input.diagnosisStatus?.name,
      'raw_score': input.rawScore,
      'score': result.score,
      'semaphore': result.semaphore.name,
      'actions': result.recommendation.actions,
      'avoid': result.recommendation.avoid,
      'route_tag': result.recommendation.routeTag,
      'video_label': result.recommendation.videoLabel,
      'video_url': result.recommendation.videoUrl,
      'created_at': DateTime.now().toIso8601String(),
    };

    final existingRaw = _prefs.getString(_remoteQueueKey);
    final queue = existingRaw == null
        ? <Map<String, dynamic>>[]
        : (json.decode(existingRaw) as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
    queue.add(payload);
    final trimmed = queue.length > 240
        ? queue.sublist(queue.length - 240)
        : queue;
    await _prefs.setString(_remoteQueueKey, json.encode(trimmed));
  }

  Future<void> _flushRemoteQueue() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final existingRaw = _prefs.getString(_remoteQueueKey);
    if (existingRaw == null || existingRaw.isEmpty) return;
    final queue = (json.decode(existingRaw) as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    if (queue.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];
    for (final item in queue) {
      final payload = Map<String, dynamic>.from(item);
      final capturedOwnerId = payload['owner_id'] as String?;
      if (capturedOwnerId != null &&
          capturedOwnerId.isNotEmpty &&
          capturedOwnerId != userId) {
        AppLogger.debug(
          'Skip daily log queue item for different owner: $capturedOwnerId',
        );
        continue;
      }
      payload['owner_id'] = userId;

      try {
        await _client.from('daily_logs').insert(payload);
      } catch (error) {
        remaining.add(item);
        AppLogger.debug('Failed to flush daily log queue item: $error');
      }
    }

    if (remaining.isEmpty) {
      await _prefs.remove(_remoteQueueKey);
      return;
    }

    await _prefs.setString(_remoteQueueKey, json.encode(remaining));
  }

  String _sensitivityKey(String? dogId) =>
      'factorSensitivity::${dogId ?? 'global'}';

  String _dailyLogKey(String? dogId) => 'dailyLog::${dogId ?? 'global'}';
}

final dailyCheckRepositoryProvider = Provider<DailyCheckRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final client = ref.watch(supabaseClientProvider);
  return DailyCheckRepository(prefs, client);
});
