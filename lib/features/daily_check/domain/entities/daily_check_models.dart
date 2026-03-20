import 'package:artrosi_cane/features/onboarding/domain/entities/dog_profile.dart';

enum DailySymptomLevel { no, lieve, marcata }

enum PlannedLoad { breve, medio, lungo }

enum RecoveryDelta { uguale, pocoPiuRigido, moltoPiuRigido }

enum DailyRiskFactor { caldo, sabbia, scale, scivoloso, auto, acqua }

enum DailySemaphore { verde, giallo, rosso }

enum DailyActionType { action, avoid }

class DailyActionRule {
  const DailyActionRule({
    required this.id,
    required this.text,
    required this.type,
    required this.category,
    required this.semaphoreMin,
    required this.semaphoreMax,
    required this.loadMin,
    required this.loadMax,
    required this.priorityBase,
    this.recoveryMin,
    this.riskFactorTags = const <DailyRiskFactor>{},
  });

  final String id;
  final String text;
  final DailyActionType type;
  final String category;
  final DailySemaphore semaphoreMin;
  final DailySemaphore semaphoreMax;
  final PlannedLoad loadMin;
  final PlannedLoad loadMax;
  final int priorityBase;
  final RecoveryDelta? recoveryMin;
  final Set<DailyRiskFactor> riskFactorTags;
}

class DailyCheckInput {
  const DailyCheckInput({
    required this.symptomLevel,
    required this.plannedLoad,
    required this.riskFactors,
    required this.recoveryDelta,
    this.diagnosisStatus,
    this.dogId,
    this.dogName,
  });

  final DailySymptomLevel symptomLevel;
  final PlannedLoad plannedLoad;
  final Set<DailyRiskFactor> riskFactors;
  final RecoveryDelta recoveryDelta;
  final ArthrosisDiagnosisStatus? diagnosisStatus;
  final String? dogId;
  final String? dogName;

  int get diagnosisModifier {
    switch (diagnosisStatus) {
      case ArthrosisDiagnosisStatus.confirmed:
        return 1;
      case ArthrosisDiagnosisStatus.unknown:
        return 2;
      case ArthrosisDiagnosisStatus.notDiagnosed:
      case null:
        return 0;
    }
  }

  int get rawScore =>
      symptomLevel.index +
      plannedLoad.index +
      riskFactors.length +
      recoveryDelta.index;

  int get totalScore => rawScore + diagnosisModifier;
}

class DailyRecommendation {
  const DailyRecommendation({
    required this.actions,
    required this.avoid,
    required this.routeTag,
    required this.videoLabel,
    required this.videoUrl,
  });

  final List<String> actions;
  final String avoid;
  final String routeTag;
  final String videoLabel;
  final String videoUrl;
}

class DailyCheckResult {
  const DailyCheckResult({
    required this.semaphore,
    required this.score,
    required this.rawScore,
    required this.title,
    required this.subtitle,
    required this.recommendation,
  });

  final DailySemaphore semaphore;
  final int score;
  final int rawScore;
  final String title;
  final String subtitle;
  final DailyRecommendation recommendation;
}

String dailyRiskFactorLabel(DailyRiskFactor factor) {
  switch (factor) {
    case DailyRiskFactor.caldo:
      return 'Caldo forte';
    case DailyRiskFactor.sabbia:
      return 'Sabbia';
    case DailyRiskFactor.scale:
      return 'Scale';
    case DailyRiskFactor.scivoloso:
      return 'Superfici scivolose';
    case DailyRiskFactor.auto:
      return 'Auto frequente';
    case DailyRiskFactor.acqua:
      return 'Acqua';
  }
}

String diagnosisStatusLabel(ArthrosisDiagnosisStatus? status) {
  switch (status) {
    case ArthrosisDiagnosisStatus.confirmed:
      return 'Diagnosi confermata';
    case ArthrosisDiagnosisStatus.notDiagnosed:
      return 'Nessuna diagnosi';
    case ArthrosisDiagnosisStatus.unknown:
      return 'Diagnosi non certa';
    case null:
      return 'Non indicato';
  }
}
