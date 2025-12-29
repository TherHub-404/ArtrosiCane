import 'package:artrosi_cane/features/onboarding/domain/entities/dog_profile.dart';
import 'package:artrosi_cane/features/onboarding/domain/repositories/onboarding_repository.dart';

class SaveDogProfile {
  SaveDogProfile(this.repository);

  final OnboardingRepository repository;

  Future<void> call(DogProfile profile) => repository.saveDogProfile(profile);
}
