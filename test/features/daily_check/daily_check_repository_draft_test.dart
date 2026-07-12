import 'package:artrosi_cane/features/daily_check/data/daily_check_repository.dart';
import 'package:artrosi_cane/features/daily_check/domain/entities/daily_check_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late DailyCheckRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = DailyCheckRepository(
      prefs,
      SupabaseClient('https://example.supabase.co', 'anon-key'),
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

  test('replaces an existing local entry for the same day', () async {
    const input = DailyCheckInput(
      symptomLevel: DailySymptomLevel.no,
      plannedLoad: PlannedLoad.breve,
      riskFactors: const {},
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
    expect(history.single.semaphore, DailySemaphore.giallo);
  });
}
