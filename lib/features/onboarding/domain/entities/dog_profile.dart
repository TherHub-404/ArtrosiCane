enum AgeGroup { cucciolo, adulto, senior }

enum DogSize { piccola, media, grande }

enum ArthrosisDiagnosisStatus { confirmed, notDiagnosed, unknown }

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
    this.diagnosisStatus,
    this.diagnosisAnsweredAt,
    this.diagnosisDate,
    this.diagnosisVet,
    this.diagnosisFiles = const <String>[],
    this.diagnosisCareNotes,
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
  final ArthrosisDiagnosisStatus? diagnosisStatus;
  final DateTime? diagnosisAnsweredAt;
  final String? diagnosisDate;
  final String? diagnosisVet;
  final List<String> diagnosisFiles;
  final String? diagnosisCareNotes;
  final AgeGroup ageGroup;
  final DogSize size;

  bool get hasDiagnosis =>
      diagnosisStatus == ArthrosisDiagnosisStatus.confirmed;

  DogProfile copyWith({
    String? id,
    String? name,
    double? ageYears,
    double? weightKg,
    String? breedId,
    String? breedName,
    String? breedImageUrl,
    String? riskLevel,
    int? riskScore,
    ArthrosisDiagnosisStatus? diagnosisStatus,
    DateTime? diagnosisAnsweredAt,
    String? diagnosisDate,
    String? diagnosisVet,
    List<String>? diagnosisFiles,
    String? diagnosisCareNotes,
    AgeGroup? ageGroup,
    DogSize? size,
  }) {
    return DogProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      ageYears: ageYears ?? this.ageYears,
      weightKg: weightKg ?? this.weightKg,
      breedId: breedId ?? this.breedId,
      breedName: breedName ?? this.breedName,
      breedImageUrl: breedImageUrl ?? this.breedImageUrl,
      riskLevel: riskLevel ?? this.riskLevel,
      riskScore: riskScore ?? this.riskScore,
      diagnosisStatus: diagnosisStatus ?? this.diagnosisStatus,
      diagnosisAnsweredAt: diagnosisAnsweredAt ?? this.diagnosisAnsweredAt,
      diagnosisDate: diagnosisDate ?? this.diagnosisDate,
      diagnosisVet: diagnosisVet ?? this.diagnosisVet,
      diagnosisFiles: diagnosisFiles ?? this.diagnosisFiles,
      diagnosisCareNotes: diagnosisCareNotes ?? this.diagnosisCareNotes,
      ageGroup: ageGroup ?? this.ageGroup,
      size: size ?? this.size,
    );
  }
}
