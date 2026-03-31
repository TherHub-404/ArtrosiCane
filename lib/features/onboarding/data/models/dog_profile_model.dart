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
    this.diagnosisStatus,
    this.diagnosisAnsweredAt,
    this.diagnosisDate,
    this.diagnosisVet,
    this.diagnosisFiles = const <String>[],
    this.diagnosisCareNotes,
    required this.ageGroup,
    required this.size,
  });

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
      diagnosisStatus: _parseDiagnosisStatus(json),
      diagnosisAnsweredAt: json['diagnosisAnsweredAt'] as String?,
      diagnosisDate: json['diagnosisDate'] as String?,
      diagnosisVet: json['diagnosisVet'] as String?,
      diagnosisFiles: (json['diagnosisFiles'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      diagnosisCareNotes: json['diagnosisCareNotes'] as String?,
      ageGroup: AgeGroup.values.firstWhere(
        (age) =>
            age.name == (json['ageGroup'] as String? ?? AgeGroup.adulto.name),
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
      diagnosisStatus: profile.diagnosisStatus,
      diagnosisAnsweredAt: profile.diagnosisAnsweredAt?.toIso8601String(),
      diagnosisDate: profile.diagnosisDate,
      diagnosisVet: profile.diagnosisVet,
      diagnosisFiles: profile.diagnosisFiles,
      diagnosisCareNotes: profile.diagnosisCareNotes,
      ageGroup: profile.ageGroup,
      size: profile.size,
    );
  }

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
  final String? diagnosisAnsweredAt;
  final String? diagnosisDate;
  final String? diagnosisVet;
  final List<String> diagnosisFiles;
  final String? diagnosisCareNotes;
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
    'diagnosisStatus': diagnosisStatus?.name,
    'hasDiagnosis': diagnosisStatus == ArthrosisDiagnosisStatus.confirmed,
    'diagnosisAnsweredAt': diagnosisAnsweredAt,
    'diagnosisDate': diagnosisDate,
    'diagnosisVet': diagnosisVet,
    'diagnosisFiles': diagnosisFiles,
    'diagnosisCareNotes': diagnosisCareNotes,
    'ageGroup': ageGroup.name,
    'size': size.name,
  };

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
    diagnosisStatus: diagnosisStatus,
    diagnosisAnsweredAt: diagnosisAnsweredAt == null
        ? null
        : DateTime.tryParse(diagnosisAnsweredAt!),
    diagnosisDate: diagnosisDate,
    diagnosisVet: diagnosisVet,
    diagnosisFiles: diagnosisFiles,
    diagnosisCareNotes: diagnosisCareNotes,
    ageGroup: ageGroup,
    size: size,
  );

  static ArthrosisDiagnosisStatus? _parseDiagnosisStatus(
    Map<String, dynamic> json,
  ) {
    final rawStatus = json['diagnosisStatus'] as String?;
    if (rawStatus != null && rawStatus.isNotEmpty) {
      for (final status in ArthrosisDiagnosisStatus.values) {
        if (status.name == rawStatus) return status;
      }
    }

    final legacyHasDiagnosis = json['hasDiagnosis'];
    if (legacyHasDiagnosis is bool) {
      return legacyHasDiagnosis
          ? ArthrosisDiagnosisStatus.confirmed
          : ArthrosisDiagnosisStatus.notDiagnosed;
    }
    return null;
  }
}
