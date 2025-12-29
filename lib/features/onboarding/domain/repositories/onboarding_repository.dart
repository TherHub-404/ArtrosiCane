import 'package:artrosi_cane/features/onboarding/domain/entities/dog_profile.dart';

abstract class OnboardingRepository {
  Future<bool> isOnboardingCompleted();
  Future<void> completeOnboarding();
  Future<void> saveDogProfile(DogProfile profile);
  Future<DogProfile?> loadDogProfile();
}
