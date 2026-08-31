import 'package:artrosi_cane/features/daily_check/data/daily_check_repository.dart';
import 'package:artrosi_cane/features/daily_check/domain/entities/daily_check_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late DailyCheckRepository repository;
  late DateTime now;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 8, 31, 10);
    repository = DailyCheckRepository(
      prefs,
      SupabaseClient('https://example.supabase.co', 'anon-key'),
      now: () => now,
    );
  });

  test('returns in progress today state when a partial draft exists', () async {
    await repository.saveDraft(
      dogId: 'dog-1',
      symptomLevel: DailySymptomLevel.lieve,
      plannedLoad: null,
      riskFactors: {DailyRiskFactor.scale},
      recoveryDelta: null,
    );

    final state = await repository.todayState(dogId: 'dog-1');

    expect(state.status, DailyDiaryStatus.inProgress);
    expect(state.draft?.symptomLevel, DailySymptomLevel.lieve);
    expect(state.draft?.riskFactors, contains(DailyRiskFactor.scale));
  });

  test(
    'ignores a duplicate local submission for the same dog and day',
    () async {
      const input = DailyCheckInput(
        symptomLevel: DailySymptomLevel.no,
        plannedLoad: PlannedLoad.breve,
        riskFactors: {},
        recoveryDelta: RecoveryDelta.uguale,
        dogId: 'dog-1',
      );
      const recommendation = DailyRecommendation(
        actions: ['azione 1', 'azione 2'],
        avoid: 'evita',
        routeTag: 'standard',
        videoLabel: 'video',
        videoUrl: 'https://example.com/video',
      );

      await repository.saveDailyLog(
        input: input,
        result: const DailyCheckResult(
          semaphore: DailySemaphore.verde,
          score: 0,
          rawScore: 0,
          title: 'ok',
          subtitle: 'ok',
          recommendation: recommendation,
        ),
      );
      await repository.saveDailyLog(
        input: input,
        result: const DailyCheckResult(
          semaphore: DailySemaphore.giallo,
          score: 1,
          rawScore: 1,
          title: 'attenzione',
          subtitle: 'attenzione',
          recommendation: recommendation,
        ),
      );

      final history = await repository.fetchHistory(dogId: 'dog-1');

      expect(history, hasLength(1));
      expect(history.single.semaphore, DailySemaphore.verde);
    },
  );

  test('tracks completion independently for each dog', () async {
    const result = DailyCheckResult(
      semaphore: DailySemaphore.verde,
      score: 0,
      rawScore: 0,
      title: 'ok',
      subtitle: 'ok',
      recommendation: DailyRecommendation(
        actions: [],
        avoid: '',
        routeTag: 'standard',
        videoLabel: '',
        videoUrl: '',
      ),
    );
    const dogOneInput = DailyCheckInput(
      symptomLevel: DailySymptomLevel.no,
      plannedLoad: PlannedLoad.breve,
      riskFactors: {},
      recoveryDelta: RecoveryDelta.uguale,
      dogId: 'dog-1',
    );

    await repository.saveDailyLog(input: dogOneInput, result: result);

    expect(
      (await repository.todayState(dogId: 'dog-1')).status,
      DailyDiaryStatus.completed,
    );
    expect(
      (await repository.todayState(dogId: 'dog-2')).status,
      DailyDiaryStatus.notStarted,
    );
  });

  test('makes the diary available again on the next local day', () async {
    const input = DailyCheckInput(
      symptomLevel: DailySymptomLevel.no,
      plannedLoad: PlannedLoad.breve,
      riskFactors: {},
      recoveryDelta: RecoveryDelta.uguale,
      dogId: 'dog-1',
    );
    const result = DailyCheckResult(
      semaphore: DailySemaphore.verde,
      score: 0,
      rawScore: 0,
      title: 'ok',
      subtitle: 'ok',
      recommendation: DailyRecommendation(
        actions: [],
        avoid: '',
        routeTag: 'standard',
        videoLabel: '',
        videoUrl: '',
      ),
    );

    await repository.saveDailyLog(input: input, result: result);
    expect(
      (await repository.todayState(dogId: 'dog-1')).status,
      DailyDiaryStatus.completed,
    );

    now = DateTime(2026, 9, 1, 0, 1);

    expect(
      (await repository.todayState(dogId: 'dog-1')).status,
      DailyDiaryStatus.notStarted,
    );
  });
}
