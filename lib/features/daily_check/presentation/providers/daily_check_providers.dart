import 'package:artrosi_cane/features/daily_check/domain/services/daily_recommendation_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dailyRecommendationEngineProvider = Provider<DailyRecommendationEngine>(
  (ref) => DailyRecommendationEngine(),
);
