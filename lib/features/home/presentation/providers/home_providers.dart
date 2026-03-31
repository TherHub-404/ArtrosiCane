import 'package:artrosi_cane/core/providers/supabase_provider.dart';
import 'package:artrosi_cane/features/home/data/dog_remote_repository.dart';
import 'package:artrosi_cane/features/home/data/monthly_sentence_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authUserIdChangesProvider = StreamProvider<String?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange
      .map((state) => state.session?.user.id)
      .distinct();
});

final userDogsProvider = FutureProvider((ref) {
  // Recompute dogs list whenever logged user changes (login/logout/account switch).
  ref.watch(authUserIdChangesProvider);
  final repo = ref.watch(dogRemoteRepositoryProvider);
  return repo.fetchDogs();
});

final currentMonthlySentenceProvider = FutureProvider<MonthlySentence?>((ref) {
  final repo = ref.watch(monthlySentenceRepositoryProvider);
  return repo.fetchSentenceForMonth(DateTime.now().month);
});
