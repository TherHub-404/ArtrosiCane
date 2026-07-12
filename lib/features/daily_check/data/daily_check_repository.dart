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
    final createdAt = DateTime.now().toUtc();
    await _saveLocalLog(input, result, createdAt: createdAt);
    await clearDraft(input.dogId);
    await _recomputeAndPersistSensitivities(input.dogId);
    await _enqueueRemoteLog(input, result, createdAt: createdAt);
    await _flushRemoteQueue();
  }

  DailyCheckDraft loadDraft(String? dogId) {
    final raw = _prefs.getString(_draftKey(dogId));
    if (raw == null || raw.isEmpty) return const DailyCheckDraft();
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      return DailyCheckDraft(
        symptomLevel: _enumByIndex(
          DailySymptomLevel.values,
          map['symptom'] as num?,
        ),
        plannedLoad: _enumByIndex(PlannedLoad.values, map['load'] as num?),
        riskFactors: ((map['riskFactors'] as List<dynamic>?) ?? <dynamic>[])
            .map((e) => e.toString())
            .map(_parseRiskFactor)
            .whereType<DailyRiskFactor>()
            .toSet(),
        recoveryDelta: _enumByIndex(
          RecoveryDelta.values,
          map['recovery'] as num?,
        ),
        updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? ''),
      );
    } catch (_) {
      return const DailyCheckDraft();
    }
  }

  Future<void> saveDraft({
    required String? dogId,
    DailySymptomLevel? symptomLevel,
    PlannedLoad? plannedLoad,
    required Set<DailyRiskFactor> riskFactors,
    RecoveryDelta? recoveryDelta,
  }) async {
    final hasAnswers =
        symptomLevel != null ||
        plannedLoad != null ||
        riskFactors.isNotEmpty ||
        recoveryDelta != null;
    if (!hasAnswers) {
      await clearDraft(dogId);
      return;
    }
    await _prefs.setString(
      _draftKey(dogId),
      json.encode({
        'symptom': symptomLevel?.index,
        'load': plannedLoad?.index,
        'riskFactors': riskFactors.map((e) => e.name).toList(),
        'recovery': recoveryDelta?.index,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  Future<void> clearDraft(String? dogId) => _prefs.remove(_draftKey(dogId));

  Future<TodayDailyDiaryState> todayState({required String? dogId}) async {
    if (dogId == null || dogId.isEmpty) {
      return const TodayDailyDiaryState(status: DailyDiaryStatus.unavailable);
    }
    final localToday = _localHistory(dogId).where(_isToday).toList();
    if (localToday.isNotEmpty) {
      return TodayDailyDiaryState(
        status: DailyDiaryStatus.completed,
        latestEntry: localToday.first,
      );
    }
    final draft = loadDraft(dogId);
    if (draft.hasAnswers) {
      return TodayDailyDiaryState(
        status: DailyDiaryStatus.inProgress,
        draft: draft,
      );
    }
    return const TodayDailyDiaryState(status: DailyDiaryStatus.notStarted);
  }

  Future<void> _saveLocalLog(
    DailyCheckInput input,
    DailyCheckResult result, {
    required DateTime createdAt,
  }) async {
    final key = _dailyLogKey(input.dogId);
    final existingRaw = _prefs.getString(key);
    final list = existingRaw == null
        ? <Map<String, dynamic>>[]
        : (json.decode(existingRaw) as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

    list.removeWhere((item) {
      final ts = DateTime.tryParse(item['ts']?.toString() ?? '')?.toLocal();
      return ts != null && _isSameLocalDay(ts, createdAt.toLocal());
    });

    list.add({
      'ts': createdAt.toIso8601String(),
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
    DailyCheckResult result, {
    required DateTime createdAt,
  }) async {
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
      'created_at': createdAt.toIso8601String(),
    };

    final existingRaw = _prefs.getString(_remoteQueueKey);
    final queue = existingRaw == null
        ? <Map<String, dynamic>>[]
        : (json.decode(existingRaw) as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
    queue.removeWhere((item) {
      final sameDog = item['dog_id']?.toString() == input.dogId;
      final ts = DateTime.tryParse(
        item['created_at']?.toString() ?? '',
      )?.toLocal();
      return sameDog && ts != null && _isSameLocalDay(ts, createdAt.toLocal());
    });
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

  /// Fetch all persisted daily check logs for the given dog (most recent first).
  /// Falls back to the local cache when the remote query fails or when the
  /// device is offline. Returns an empty list when nothing is available.
  Future<List<DailyLogEntry>> fetchHistory({required String dogId}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return _localHistory(dogId);

    // Try to flush any pending local writes before reading, so the remote
    // history reflects the most recent local checks.
    try {
      await _flushRemoteQueue();
    } catch (_) {}

    try {
      final rows = await _client
          .from('daily_logs')
          .select(
            'created_at, semaphore, score, raw_score, actions, avoid, '
            'video_label, video_url, route_tag, dog_id, owner_id',
          )
          .eq('owner_id', userId)
          .eq('dog_id', dogId)
          .order('created_at', ascending: false);
      final list = <DailyLogEntry>[];
      for (final row in (rows as List<dynamic>? ?? const <dynamic>[])) {
        final entry = _entryFromRow(Map<String, dynamic>.from(row as Map));
        if (entry != null) list.add(entry);
      }
      if (list.isNotEmpty) return list;
      return _localHistory(dogId);
    } catch (error) {
      AppLogger.debug('Failed to fetch daily history: $error');
      return _localHistory(dogId);
    }
  }

  List<DailyLogEntry> _localHistory(String dogId) {
    final raw = _prefs.getString(_dailyLogKey(dogId));
    if (raw == null || raw.isEmpty) return const <DailyLogEntry>[];
    try {
      final list = (json.decode(raw) as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final out = <DailyLogEntry>[];
      for (final item in list) {
        final entry = _entryFromLocal(item);
        if (entry != null) out.add(entry);
      }
      out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return out;
    } catch (_) {
      return const <DailyLogEntry>[];
    }
  }

  DailyLogEntry? _entryFromRow(Map<String, dynamic> row) {
    final createdRaw = row['created_at'] as String?;
    final created = createdRaw == null
        ? null
        : DateTime.tryParse(createdRaw)?.toLocal();
    final semaphore = _parseSemaphore(row['semaphore']?.toString());
    if (created == null || semaphore == null) return null;
    final actions = (row['actions'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => e.toString())
        .toList();
    return DailyLogEntry(
      createdAt: created,
      semaphore: semaphore,
      score: (row['score'] as num?)?.toInt() ?? 0,
      rawScore: (row['raw_score'] as num?)?.toInt() ?? 0,
      actions: actions,
      avoid: (row['avoid'] as String?) ?? '',
      videoLabel: (row['video_label'] as String?) ?? '',
      videoUrl: (row['video_url'] as String?) ?? '',
      routeTag: (row['route_tag'] as String?) ?? 'standard',
    );
  }

  DailyLogEntry? _entryFromLocal(Map<String, dynamic> item) {
    final createdRaw = item['ts'] as String?;
    final created = createdRaw == null
        ? null
        : DateTime.tryParse(createdRaw)?.toLocal();
    final semaphore = _parseSemaphore(item['semaphore']?.toString());
    if (created == null || semaphore == null) return null;
    return DailyLogEntry(
      createdAt: created,
      semaphore: semaphore,
      score: (item['score'] as num?)?.toInt() ?? 0,
      rawScore: (item['rawScore'] as num?)?.toInt() ?? 0,
      actions: const <String>[],
      avoid: '',
      videoLabel: '',
      videoUrl: '',
      routeTag: 'standard',
    );
  }

  DailySemaphore? _parseSemaphore(String? value) {
    if (value == null) return null;
    for (final s in DailySemaphore.values) {
      if (s.name == value) return s;
    }
    return null;
  }

  bool _isToday(DailyLogEntry entry) =>
      _isSameLocalDay(entry.createdAt, DateTime.now());

  bool _isSameLocalDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  T? _enumByIndex<T>(List<T> values, num? index) {
    final parsed = index?.toInt();
    if (parsed == null || parsed < 0 || parsed >= values.length) return null;
    return values[parsed];
  }

  DailyRiskFactor? _parseRiskFactor(String value) {
    for (final factor in DailyRiskFactor.values) {
      if (factor.name == value) return factor;
    }
    return null;
  }

  String _sensitivityKey(String? dogId) =>
      'factorSensitivity::${dogId ?? 'global'}';

  String _dailyLogKey(String? dogId) => 'dailyLog::${dogId ?? 'global'}';

  String _draftKey(String? dogId) => 'dailyCheckDraft::${dogId ?? 'global'}';
}

final dailyCheckRepositoryProvider = Provider<DailyCheckRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final client = ref.watch(supabaseClientProvider);
  return DailyCheckRepository(prefs, client);
});
