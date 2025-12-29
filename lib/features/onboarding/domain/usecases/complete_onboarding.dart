import 'package:artrosi_cane/features/onboarding/domain/repositories/onboarding_repository.dart';

class CompleteOnboarding {
  CompleteOnboarding(this.repository);

  final OnboardingRepository repository;

  Future<void> call() => repository.completeOnboarding();
}
