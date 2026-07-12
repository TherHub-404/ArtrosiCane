import 'package:artrosi_cane/features/onboarding/domain/entities/dog_profile.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';

enum DailySymptomLevel { no, lieve, marcata }

enum PlannedLoad { breve, medio, lungo }

enum RecoveryDelta { uguale, pocoPiuRigido, moltoPiuRigido }

enum DailyRiskFactor { caldo, sabbia, scale, scivoloso, auto, acqua }

enum DailySemaphore { verde, giallo, rosso }

enum DailyDiaryStatus { unavailable, notStarted, inProgress, completed }

class DailyCheckDraft {
  const DailyCheckDraft({
    this.symptomLevel,
    this.plannedLoad,
    this.riskFactors = const <DailyRiskFactor>{},
    this.recoveryDelta,
    this.updatedAt,
  });

  final DailySymptomLevel? symptomLevel;
  final PlannedLoad? plannedLoad;
  final Set<DailyRiskFactor> riskFactors;
  final RecoveryDelta? recoveryDelta;
  final DateTime? updatedAt;

  bool get hasAnswers =>
      symptomLevel != null ||
      plannedLoad != null ||
      riskFactors.isNotEmpty ||
      recoveryDelta != null;

  bool get isComplete =>
      symptomLevel != null && plannedLoad != null && recoveryDelta != null;
}

class TodayDailyDiaryState {
  const TodayDailyDiaryState({
    required this.status,
    this.latestEntry,
    this.draft,
  });

  final DailyDiaryStatus status;
  final DailyLogEntry? latestEntry;
  final DailyCheckDraft? draft;

  bool get canStartOrContinue =>
      status == DailyDiaryStatus.notStarted ||
      status == DailyDiaryStatus.inProgress;
}

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

/// A persisted daily log entry as fetched from the remote `daily_logs` table.
/// Used by the history screen and chart.
class DailyLogEntry {
  const DailyLogEntry({
    required this.createdAt,
    required this.semaphore,
    required this.score,
    required this.rawScore,
    required this.actions,
    required this.avoid,
    required this.videoLabel,
    required this.videoUrl,
    required this.routeTag,
  });

  final DateTime createdAt;
  final DailySemaphore semaphore;
  final int score;
  final int rawScore;
  final List<String> actions;
  final String avoid;
  final String videoLabel;
  final String videoUrl;
  final String routeTag;
}

String dailyRiskFactorLabel(DailyRiskFactor factor) {
  final l10n = AppLocalizations.current;
  switch (factor) {
    case DailyRiskFactor.caldo:
      return l10n.text('Caldo forte');
    case DailyRiskFactor.sabbia:
      return l10n.text('Sabbia');
    case DailyRiskFactor.scale:
      return l10n.text('Scale');
    case DailyRiskFactor.scivoloso:
      return l10n.text('Superfici scivolose');
    case DailyRiskFactor.auto:
      return l10n.text('Auto frequente');
    case DailyRiskFactor.acqua:
      return l10n.text('Acqua');
  }
}

String diagnosisStatusLabel(ArthrosisDiagnosisStatus? status) {
  final l10n = AppLocalizations.current;
  switch (status) {
    case ArthrosisDiagnosisStatus.confirmed:
      return l10n.text('Diagnosi confermata');
    case ArthrosisDiagnosisStatus.notDiagnosed:
      return l10n.text('Nessuna diagnosi');
    case ArthrosisDiagnosisStatus.unknown:
      return l10n.text('Diagnosi non certa');
    case null:
      return l10n.text('Non indicato');
  }
}
