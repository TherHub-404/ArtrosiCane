import 'package:artrosi_cane/core/data/preferences_data_source.dart';
import 'package:artrosi_cane/features/onboarding/data/models/dog_profile_model.dart';
import 'package:artrosi_cane/features/onboarding/domain/entities/dog_profile.dart';
import 'package:artrosi_cane/features/onboarding/domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._preferencesDataSource);

  final PreferencesDataSource _preferencesDataSource;

  @override
  Future<void> completeOnboarding() async {
    await _preferencesDataSource.completeOnboarding();
  }

  @override
  Future<bool> isOnboardingCompleted() {
    return _preferencesDataSource.isOnboardingCompleted();
  }

  @override
  Future<DogProfile?> loadDogProfile() async {
    final model = await _preferencesDataSource.loadDogProfile();
    return model?.toEntity();
  }

  @override
  Future<void> saveDogProfile(DogProfile profile) async {
    final model = DogProfileModel.fromEntity(profile);
    await _preferencesDataSource.saveDogProfile(model);
  }
}
