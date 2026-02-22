import 'package:artrosi_cane/features/home/data/dog_remote_repository.dart';
import 'package:artrosi_cane/features/home/data/monthly_sentence_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userDogsProvider = FutureProvider((ref) {
  final repo = ref.watch(dogRemoteRepositoryProvider);
  return repo.fetchDogs();
});

final currentMonthlySentenceProvider = FutureProvider<MonthlySentence?>((ref) {
  final repo = ref.watch(monthlySentenceRepositoryProvider);
  return repo.fetchSentenceForMonth(DateTime.now().month);
});
