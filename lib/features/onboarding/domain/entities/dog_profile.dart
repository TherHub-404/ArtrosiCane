enum AgeGroup { cucciolo, adulto, senior }

enum DogSize { piccola, media, grande }

class DogProfile {
  const DogProfile({
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
    this.ageGroup = AgeGroup.adulto,
    this.size = DogSize.media,
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
}
