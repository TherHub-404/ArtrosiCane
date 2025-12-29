import 'package:artrosi_cane/features/home/data/dog_remote_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userDogsProvider = FutureProvider((ref) {
  final repo = ref.watch(dogRemoteRepositoryProvider);
  return repo.fetchDogs();
});
