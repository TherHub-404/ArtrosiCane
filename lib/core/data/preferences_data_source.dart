import 'dart:convert';

import 'package:artrosi_cane/core/errors/exceptions.dart';
import 'package:artrosi_cane/features/onboarding/data/models/dog_profile_model.dart';
import 'package:artrosi_cane/features/quiz/data/models/quiz_answer_model.dart';
import 'package:artrosi_cane/features/quiz/data/models/diagnosis_priority_result_model.dart';
import 'package:artrosi_cane/features/quiz/data/models/quiz_result_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesDataSource {
  PreferencesDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const _onboardingKey = 'onboardingCompleted';
  static const _dogProfileKey = 'dogProfile';
  static const _quizProgressKey = 'quizProgress';
  static const _lastResultKey = 'lastResult';
  static const _lastResultSyncedSignatureKey = 'lastResultSyncedSignature';
  static const _lastDiagnosisPriorityResultKey = 'lastDiagnosisPriorityResult';
  static const _onboardingEventsKey = 'onboardingEvents';

  Future<bool> isOnboardingCompleted() async {
    return _prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_onboardingKey, true);
  }

  Future<void> saveDogProfile(DogProfileModel model) async {
    final jsonString = json.encode(model.toJson());
    final saved = await _prefs.setString(_dogProfileKey, jsonString);
    if (!saved) {
      throw CacheException('Impossibile salvare il profilo del cane');
    }
  }

  Future<DogProfileModel?> loadDogProfile() async {
    final jsonString = _prefs.getString(_dogProfileKey);
    if (jsonString == null) return null;
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return DogProfileModel.fromJson(map);
  }

  Future<void> saveQuizProgress(List<QuizAnswerModel> answers) async {
    final jsonString = json.encode(answers.map((a) => a.toJson()).toList());
    final saved = await _prefs.setString(_quizProgressKey, jsonString);
    if (!saved) {
      throw CacheException('Impossibile salvare il progresso del quiz');
    }
  }

  Future<List<QuizAnswerModel>> loadQuizProgress() async {
    final jsonString = _prefs.getString(_quizProgressKey);
    if (jsonString == null) return <QuizAnswerModel>[];
    final list = json.decode(jsonString) as List<dynamic>;
    return list
        .map((item) => QuizAnswerModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveLastResult(QuizResultModel model) async {
    final saved = await _prefs.setString(
      _lastResultKey,
      json.encode(model.toJson()),
    );
    if (!saved) {
      throw CacheException('Impossibile salvare il risultato del quiz');
    }
    await _prefs.remove(_lastResultSyncedSignatureKey);
  }

  Future<QuizResultModel?> loadLastResult() async {
    final jsonString = _prefs.getString(_lastResultKey);
    if (jsonString == null) return null;
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return QuizResultModel.fromJson(map);
  }

  Future<void> saveDiagnosisPriorityResult(
    DiagnosisPriorityResultModel model,
  ) async {
    final saved = await _prefs.setString(
      _lastDiagnosisPriorityResultKey,
      json.encode(model.toJson()),
    );
    if (!saved) {
      throw CacheException(
        'Impossibile salvare il risultato priorita diagnosi',
      );
    }
  }

  Future<DiagnosisPriorityResultModel?> loadDiagnosisPriorityResult() async {
    final jsonString = _prefs.getString(_lastDiagnosisPriorityResultKey);
    if (jsonString == null) return null;
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return DiagnosisPriorityResultModel.fromJson(map);
  }

  Future<void> appendOnboardingEvent({
    required String eventName,
    Map<String, dynamic> payload = const {},
  }) async {
    final raw = _prefs.getString(_onboardingEventsKey);
    final events = raw == null
        ? <Map<String, dynamic>>[]
        : (json.decode(raw) as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

    events.add({
      'eventName': eventName,
      'payload': payload,
      'createdAt': DateTime.now().toIso8601String(),
    });

    final trimmed = events.length > 120
        ? events.sublist(events.length - 120)
        : events;
    final saved = await _prefs.setString(
      _onboardingEventsKey,
      json.encode(trimmed),
    );
    if (!saved) {
      throw CacheException('Impossibile salvare evento onboarding');
    }
  }

  Future<List<Map<String, dynamic>>> loadOnboardingEvents() async {
    final raw = _prefs.getString(_onboardingEventsKey);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    final list = json.decode(raw) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
