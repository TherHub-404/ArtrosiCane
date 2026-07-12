import 'package:artrosi_cane/features/daily_check/data/daily_check_repository.dart';
import 'package:artrosi_cane/features/daily_check/domain/entities/daily_check_models.dart';
import 'package:artrosi_cane/features/daily_check/domain/services/daily_recommendation_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dailyRecommendationEngineProvider = Provider<DailyRecommendationEngine>(
  (ref) => DailyRecommendationEngine(),
);

final todayDailyDiaryStateProvider = FutureProvider.autoDispose
    .family<TodayDailyDiaryState, String?>((ref, dogId) {
      final repo = ref.watch(dailyCheckRepositoryProvider);
      return repo.todayState(dogId: dogId);
    });
