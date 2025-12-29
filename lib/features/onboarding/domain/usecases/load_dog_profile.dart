import 'package:artrosi_cane/features/onboarding/domain/entities/dog_profile.dart';
import 'package:artrosi_cane/features/onboarding/domain/repositories/onboarding_repository.dart';

class LoadDogProfile {
  LoadDogProfile(this.repository);

  final OnboardingRepository repository;

  Future<DogProfile?> call() => repository.loadDogProfile();
}
