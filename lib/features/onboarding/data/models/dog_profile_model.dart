import 'package:artrosi_cane/features/onboarding/domain/entities/dog_profile.dart';

class DogProfileModel {
  const DogProfileModel({
    this.id,
    this.name,
    this.ageYears,
    this.weightKg,
    this.breedId,
    this.breedName,
    this.breedImageUrl,
    this.riskLevel,
    this.riskScore,
    this.hasDiagnosis = false,
    this.diagnosisDate,
    this.diagnosisVet,
    required this.ageGroup,
    required this.size,
  });

  final String? id;
  final String? name;
  final double? ageYears;
  final double? weightKg;
  final String? breedId;
  final String? breedName;
  final String? breedImageUrl;
  final String? riskLevel;
  final int? riskScore;
  final bool hasDiagnosis;
  final String? diagnosisDate;
  final String? diagnosisVet;
  final AgeGroup ageGroup;
  final DogSize size;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ageYears': ageYears,
        'weightKg': weightKg,
        'breedId': breedId,
        'breedName': breedName,
        'breedImageUrl': breedImageUrl,
        'riskLevel': riskLevel,
        'riskScore': riskScore,
        'hasDiagnosis': hasDiagnosis,
        'diagnosisDate': diagnosisDate,
        'diagnosisVet': diagnosisVet,
        'ageGroup': ageGroup.name,
        'size': size.name,
      };

  factory DogProfileModel.fromJson(Map<String, dynamic> json) {
    return DogProfileModel(
      id: json['id'] as String?,
      name: json['name'] as String?,
      ageYears: (json['ageYears'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      breedId: json['breedId'] as String?,
      breedName: json['breedName'] as String?,
      breedImageUrl: json['breedImageUrl'] as String?,
      riskLevel: json['riskLevel'] as String?,
      riskScore: json['riskScore'] as int?,
      hasDiagnosis: json['hasDiagnosis'] as bool? ?? false,
      diagnosisDate: json['diagnosisDate'] as String?,
      diagnosisVet: json['diagnosisVet'] as String?,
      ageGroup: AgeGroup.values.firstWhere(
        (age) => age.name == (json['ageGroup'] as String? ?? AgeGroup.adulto.name),
        orElse: () => AgeGroup.adulto,
      ),
      size: DogSize.values.firstWhere(
        (s) => s.name == (json['size'] as String? ?? DogSize.media.name),
        orElse: () => DogSize.media,
      ),
    );
  }

  factory DogProfileModel.fromEntity(DogProfile profile) {
    return DogProfileModel(
      id: profile.id,
      name: profile.name,
      ageYears: profile.ageYears,
      weightKg: profile.weightKg,
      breedId: profile.breedId,
      breedName: profile.breedName,
      breedImageUrl: profile.breedImageUrl,
      riskLevel: profile.riskLevel,
      riskScore: profile.riskScore,
      hasDiagnosis: profile.hasDiagnosis,
      diagnosisDate: profile.diagnosisDate,
      diagnosisVet: profile.diagnosisVet,
      ageGroup: profile.ageGroup,
      size: profile.size,
    );
  }

  DogProfile toEntity() => DogProfile(
        id: id,
        name: name,
        ageYears: ageYears,
        weightKg: weightKg,
        breedId: breedId,
        breedName: breedName,
        breedImageUrl: breedImageUrl,
        riskLevel: riskLevel,
        riskScore: riskScore,
        hasDiagnosis: hasDiagnosis,
        diagnosisDate: diagnosisDate,
        diagnosisVet: diagnosisVet,
        ageGroup: ageGroup,
        size: size,
      );
}
