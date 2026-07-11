import 'package:artrosi_cane/features/daily_check/domain/entities/daily_check_models.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';

class DailyRecommendationEngine {
  DailyRecommendationEngine();

  DailyCheckResult evaluate({
    required DailyCheckInput input,
    required Map<DailyRiskFactor, int> sensitivities,
  }) {
    final score = input.totalScore;
    final semaphore = _toSemaphore(score);
    final recommendation = _recommend(
      input: input,
      semaphore: semaphore,
      sensitivities: sensitivities,
    );

    final header = _headerFor(semaphore);
    return DailyCheckResult(
      semaphore: semaphore,
      score: score,
      rawScore: input.rawScore,
      title: header.$1,
      subtitle: header.$2,
      recommendation: recommendation,
    );
  }

  DailySemaphore _toSemaphore(int score) {
    if (score <= 3) return DailySemaphore.verde;
    if (score <= 6) return DailySemaphore.giallo;
    return DailySemaphore.rosso;
  }

  (String, String) _headerFor(DailySemaphore semaphore) {
    final l10n = AppLocalizations.current;
    switch (semaphore) {
      case DailySemaphore.verde:
        return (
          l10n.text('Giornata stabile'),
          l10n.text('Puoi muoverti, con criterio.'),
        );
      case DailySemaphore.giallo:
        return (
          l10n.text('Giornata da gestire'),
          l10n.text('Riduci intensità, osserva il recupero.'),
        );
      case DailySemaphore.rosso:
        return (
          l10n.text('Giornata di protezione'),
          l10n.text('Oggi meno carico, più controllo.'),
        );
    }
  }

  DailyRecommendation _recommend({
    required DailyCheckInput input,
    required DailySemaphore semaphore,
    required Map<DailyRiskFactor, int> sensitivities,
  }) {
    final l10n = AppLocalizations.current;
    final candidates = _rules.where((rule) {
      if (!_fitsSemaphore(rule, semaphore)) return false;
      if (!_fitsLoad(rule, input.plannedLoad)) return false;
      if (!_fitsRecovery(rule, input.recoveryDelta)) return false;
      if (rule.riskFactorTags.isNotEmpty &&
          rule.riskFactorTags.intersection(input.riskFactors).isEmpty) {
        return false;
      }
      return true;
    }).toList();

    final scored = candidates.map((rule) {
      var score = rule.priorityBase;
      score += _semaphoreBonus(semaphore);
      score += input.recoveryDelta.index;
      if (input.plannedLoad == PlannedLoad.lungo &&
          (rule.category.contains('durata') ||
              rule.category.contains('pause'))) {
        score += 2;
      }
      for (final factor in rule.riskFactorTags) {
        if (input.riskFactors.contains(factor)) {
          score += sensitivities[factor] ?? 0;
        }
      }
      return (rule: rule, score: score);
    }).toList()..sort((a, b) => b.score.compareTo(a.score));

    final topActions = <String>[];
    final usedCategories = <String>{};
    for (final item in scored) {
      if (item.rule.type != DailyActionType.action) continue;
      if (usedCategories.contains(item.rule.category)) continue;
      topActions.add(l10n.text(item.rule.text));
      usedCategories.add(item.rule.category);
      if (topActions.length == 2) break;
    }

    if (topActions.length < 2) {
      final fallback = _rules
          .where((r) => r.type == DailyActionType.action)
          .map((r) => l10n.text(r.text))
          .where((t) => !topActions.contains(t))
          .take(2 - topActions.length);
      topActions.addAll(fallback);
    }

    String? avoid;
    for (final item in scored) {
      if (item.rule.type == DailyActionType.avoid) {
        avoid = l10n.text(item.rule.text);
        break;
      }
    }
    avoid ??= l10n.text('Evita variazioni brusche di ritmo nelle passeggiate.');

    final routeTag = input.riskFactors.contains(DailyRiskFactor.sabbia)
        ? 'bibione'
        : 'standard';

    final videoLabel = semaphore == DailySemaphore.rosso
        ? l10n.text('Routine mobilità dolce (20s)')
        : semaphore == DailySemaphore.giallo
        ? l10n.text('Routine controllo carico (30s)')
        : l10n.text('Routine mantenimento (25s)');

    final videoUrl = semaphore == DailySemaphore.rosso
        ? 'https://www.youtube.com/watch?v=6sM4fQn8f8Q'
        : semaphore == DailySemaphore.giallo
        ? 'https://www.youtube.com/watch?v=uKx1qN7QfKk'
        : 'https://www.youtube.com/watch?v=GgP7M6k8hPc';

    return DailyRecommendation(
      actions: topActions,
      avoid: avoid,
      routeTag: routeTag,
      videoLabel: videoLabel,
      videoUrl: videoUrl,
    );
  }

  bool _fitsSemaphore(DailyActionRule rule, DailySemaphore semaphore) {
    return semaphore.index >= rule.semaphoreMin.index &&
        semaphore.index <= rule.semaphoreMax.index;
  }

  bool _fitsLoad(DailyActionRule rule, PlannedLoad load) {
    return load.index >= rule.loadMin.index && load.index <= rule.loadMax.index;
  }

  bool _fitsRecovery(DailyActionRule rule, RecoveryDelta recovery) {
    if (rule.recoveryMin == null) return true;
    return recovery.index >= rule.recoveryMin!.index;
  }

  int _semaphoreBonus(DailySemaphore semaphore) {
    switch (semaphore) {
      case DailySemaphore.verde:
        return 0;
      case DailySemaphore.giallo:
        return 2;
      case DailySemaphore.rosso:
        return 4;
    }
  }
}

final List<DailyActionRule> _rules = [
  DailyActionRule(
    id: 'A01',
    text: 'Spezza la passeggiata in 2 uscite più brevi.',
    type: DailyActionType.action,
    category: 'durata',
    semaphoreMin: DailySemaphore.giallo,
    semaphoreMax: DailySemaphore.rosso,
    loadMin: PlannedLoad.medio,
    loadMax: PlannedLoad.lungo,
    priorityBase: 13,
  ),
  DailyActionRule(
    id: 'A02',
    text: 'Scegli fondo compatto e regolare.',
    type: DailyActionType.action,
    category: 'superficie',
    semaphoreMin: DailySemaphore.verde,
    semaphoreMax: DailySemaphore.rosso,
    loadMin: PlannedLoad.breve,
    loadMax: PlannedLoad.lungo,
    priorityBase: 11,
    riskFactorTags: {DailyRiskFactor.sabbia, DailyRiskFactor.scivoloso},
  ),
  DailyActionRule(
    id: 'A03',
    text: 'Aggiungi una pausa di 2 minuti ogni 10 minuti.',
    type: DailyActionType.action,
    category: 'pause',
    semaphoreMin: DailySemaphore.giallo,
    semaphoreMax: DailySemaphore.rosso,
    loadMin: PlannedLoad.medio,
    loadMax: PlannedLoad.lungo,
    priorityBase: 12,
  ),
  DailyActionRule(
    id: 'A04',
    text: 'Programma uscita al fresco: mattina presto o sera.',
    type: DailyActionType.action,
    category: 'ambiente',
    semaphoreMin: DailySemaphore.verde,
    semaphoreMax: DailySemaphore.rosso,
    loadMin: PlannedLoad.breve,
    loadMax: PlannedLoad.lungo,
    priorityBase: 10,
    riskFactorTags: {DailyRiskFactor.caldo},
  ),
  DailyActionRule(
    id: 'A05',
    text: 'Prediligi passo lento e costante.',
    type: DailyActionType.action,
    category: 'ritmo',
    semaphoreMin: DailySemaphore.verde,
    semaphoreMax: DailySemaphore.rosso,
    loadMin: PlannedLoad.breve,
    loadMax: PlannedLoad.lungo,
    priorityBase: 10,
    recoveryMin: RecoveryDelta.pocoPiuRigido,
  ),
  DailyActionRule(
    id: 'A06',
    text: 'Fai un riscaldamento dolce di 2 minuti prima di uscire.',
    type: DailyActionType.action,
    category: 'attivazione',
    semaphoreMin: DailySemaphore.giallo,
    semaphoreMax: DailySemaphore.rosso,
    loadMin: PlannedLoad.breve,
    loadMax: PlannedLoad.lungo,
    priorityBase: 11,
  ),
  DailyActionRule(
    id: 'V01',
    text: 'Evita scale ripetute oggi.',
    type: DailyActionType.avoid,
    category: 'evita-scale',
    semaphoreMin: DailySemaphore.giallo,
    semaphoreMax: DailySemaphore.rosso,
    loadMin: PlannedLoad.breve,
    loadMax: PlannedLoad.lungo,
    priorityBase: 14,
    riskFactorTags: {DailyRiskFactor.scale},
  ),
  DailyActionRule(
    id: 'V02',
    text: 'Evita sabbia morbida nelle ore centrali.',
    type: DailyActionType.avoid,
    category: 'evita-sabbia',
    semaphoreMin: DailySemaphore.giallo,
    semaphoreMax: DailySemaphore.rosso,
    loadMin: PlannedLoad.breve,
    loadMax: PlannedLoad.lungo,
    priorityBase: 13,
    riskFactorTags: {DailyRiskFactor.sabbia, DailyRiskFactor.caldo},
  ),
  DailyActionRule(
    id: 'V03',
    text: 'Evita salti da auto o divano.',
    type: DailyActionType.avoid,
    category: 'evita-salti',
    semaphoreMin: DailySemaphore.giallo,
    semaphoreMax: DailySemaphore.rosso,
    loadMin: PlannedLoad.breve,
    loadMax: PlannedLoad.lungo,
    priorityBase: 12,
    riskFactorTags: {DailyRiskFactor.auto},
  ),
  DailyActionRule(
    id: 'V04',
    text: 'Evita scatti e cambi di ritmo improvvisi.',
    type: DailyActionType.avoid,
    category: 'evita-scatti',
    semaphoreMin: DailySemaphore.verde,
    semaphoreMax: DailySemaphore.rosso,
    loadMin: PlannedLoad.breve,
    loadMax: PlannedLoad.lungo,
    priorityBase: 10,
  ),
];
