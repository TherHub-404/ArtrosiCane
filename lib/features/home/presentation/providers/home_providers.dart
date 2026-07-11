import 'package:artrosi_cane/core/providers/supabase_provider.dart';
import 'package:artrosi_cane/features/home/data/daily_sentence_repository.dart';
import 'package:artrosi_cane/features/home/data/dog_remote_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authUserIdChangesProvider = StreamProvider<String?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange
      .map((state) => state.session?.user.id)
      .distinct();
});

final userDogsProvider = FutureProvider((ref) {
  ref.watch(authUserIdChangesProvider);
  final repo = ref.watch(dogRemoteRepositoryProvider);
  return repo.fetchDogs();
});

final dailySentenceForTodayProvider =
    FutureProvider.family<DailySentence?, String>((ref, language) {
  final repo = ref.watch(dailySentenceRepositoryProvider);
  final now = DateTime.now();
  return repo.fetchForToday(
    language: language,
    month: now.month,
    day: now.day,
  );
});
