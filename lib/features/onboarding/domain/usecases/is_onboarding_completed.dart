import 'package:artrosi_cane/features/onboarding/domain/repositories/onboarding_repository.dart';

class IsOnboardingCompleted {
  IsOnboardingCompleted(this.repository);

  final OnboardingRepository repository;

  Future<bool> call() => repository.isOnboardingCompleted();
}
