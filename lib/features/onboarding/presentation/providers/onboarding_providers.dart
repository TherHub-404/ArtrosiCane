import 'package:artrosi_cane/core/providers/preferences_data_source_provider.dart';
import 'package:artrosi_cane/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:artrosi_cane/features/onboarding/data/repositories/breed_repository.dart';
import 'package:artrosi_cane/features/onboarding/domain/entities/dog_profile.dart';
import 'package:artrosi_cane/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:artrosi_cane/features/onboarding/domain/usecases/complete_onboarding.dart';
import 'package:artrosi_cane/features/onboarding/domain/usecases/is_onboarding_completed.dart';
import 'package:artrosi_cane/features/onboarding/domain/usecases/load_dog_profile.dart';
import 'package:artrosi_cane/features/onboarding/domain/usecases/save_dog_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final dataSource = ref.watch(preferencesDataSourceProvider);
  return OnboardingRepositoryImpl(dataSource);
});

final isOnboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(onboardingRepositoryProvider);
  return repository.isOnboardingCompleted();
});

final loadDogProfileProvider = FutureProvider<DogProfile?>((ref) async {
  final repository = ref.watch(onboardingRepositoryProvider);
  return repository.loadDogProfile();
});

final saveDogProfileUseCaseProvider = Provider<SaveDogProfile>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return SaveDogProfile(repository);
});

final completeOnboardingUseCaseProvider = Provider<CompleteOnboarding>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return CompleteOnboarding(repository);
});

final isOnboardingCompletedUseCaseProvider =
    Provider<IsOnboardingCompleted>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return IsOnboardingCompleted(repository);
});

final loadDogProfileUseCaseProvider = Provider<LoadDogProfile>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return LoadDogProfile(repository);
});

final breedListProvider = FutureProvider((ref) async {
  final repository = ref.watch(breedRepositoryProvider);
  return repository.fetchBreeds();
});
