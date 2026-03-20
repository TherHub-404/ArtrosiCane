import 'package:artrosi_cane/features/quiz/domain/entities/diagnosis_priority_models.dart';

class DiagnosisPriorityEngine {
  const DiagnosisPriorityEngine();

  static const List<PriorityArea> _areaOrder = [
    PriorityArea.dolore,
    PriorityArea.routineCarico,
    PriorityArea.ambiente,
    PriorityArea.movimento,
    PriorityArea.peso,
  ];

  DiagnosisPriorityResult evaluate(DiagnosisPriorityInput input) {
    final scores = <PriorityArea, int>{
      for (final area in PriorityArea.values) area: 0,
    };

    void add(PriorityArea area, int points) {
      scores[area] = (scores[area] ?? 0) + points;
    }

    final jointCount = input.joints.length;
    if (jointCount == 2) {
      add(PriorityArea.dolore, 1);
    } else if (jointCount >= 3) {
      add(PriorityArea.dolore, 2);
    }

    switch (input.mobility) {
      case DiagnosisMobility.lieve:
        add(PriorityArea.dolore, 1);
        break;
      case DiagnosisMobility.moderata:
        add(PriorityArea.dolore, 2);
        add(PriorityArea.ambiente, 1);
        break;
      case DiagnosisMobility.avanzata:
        add(PriorityArea.dolore, 3);
        add(PriorityArea.ambiente, 2);
        break;
    }

    switch (input.rigidityFrequency) {
      case DiagnosisRigidityFrequency.mai:
        break;
      case DiagnosisRigidityFrequency.unoDue:
        add(PriorityArea.dolore, 1);
        add(PriorityArea.movimento, 1);
        break;
      case DiagnosisRigidityFrequency.treQuattro:
        add(PriorityArea.dolore, 2);
        add(PriorityArea.movimento, 1);
        break;
      case DiagnosisRigidityFrequency.cinqueSette:
        add(PriorityArea.dolore, 3);
        add(PriorityArea.movimento, 2);
        break;
    }

    switch (input.recovery) {
      case DiagnosisRecovery.uguale:
        break;
      case DiagnosisRecovery.unPoPeggio:
        add(PriorityArea.dolore, 1);
        add(PriorityArea.routineCarico, 2);
        break;
      case DiagnosisRecovery.moltoPeggio:
        add(PriorityArea.dolore, 2);
        add(PriorityArea.routineCarico, 3);
        break;
    }

    if (input.hasHomeRiskFactors) {
      add(PriorityArea.ambiente, 3);
    }

    switch (input.weightTrend) {
      case DiagnosisWeightTrend.stabile:
        break;
      case DiagnosisWeightTrend.inAumento:
        add(PriorityArea.peso, 3);
        add(PriorityArea.dolore, 1);
        break;
      case DiagnosisWeightTrend.nonSo:
        add(PriorityArea.peso, 1);
        break;
    }

    switch (input.movementRhythm) {
      case DiagnosisMovementRhythm.regolareOgniGiorno:
        break;
      case DiagnosisMovementRhythm.giorniAlterniTanto:
        add(PriorityArea.movimento, 2);
        add(PriorityArea.routineCarico, 2);
        break;
      case DiagnosisMovementRhythm.irregolareWeekend:
        add(PriorityArea.movimento, 3);
        add(PriorityArea.routineCarico, 3);
        break;
    }

    final levels = <PriorityArea, PriorityLevel>{
      for (final area in PriorityArea.values)
        area: _classify(scores[area] ?? 0),
    };

    final safetyTrigger =
        input.mobility == DiagnosisMobility.avanzata ||
        input.rigidityFrequency == DiagnosisRigidityFrequency.cinqueSette ||
        input.recovery == DiagnosisRecovery.moltoPeggio;

    var safetyRuleApplied = false;
    if (safetyTrigger && levels[PriorityArea.dolore] == PriorityLevel.bassa) {
      levels[PriorityArea.dolore] = PriorityLevel.media;
      safetyRuleApplied = true;
    }

    final highAreas = levels.entries
        .where((entry) => entry.value == PriorityLevel.alta)
        .map((entry) => entry.key)
        .toList();

    final compressed = <PriorityArea>[];
    if (highAreas.length > 2) {
      highAreas.sort((a, b) => _compareAreasByScore(scores, a, b));
      final keepHigh = highAreas.take(2).toSet();
      for (final area in highAreas) {
        if (!keepHigh.contains(area)) {
          levels[area] = PriorityLevel.media;
          compressed.add(area);
        }
      }
    }

    final orderedAreas = [...PriorityArea.values]
      ..sort((a, b) => _compareAreasByScore(scores, a, b));
    final shownHighAreas = orderedAreas
        .where((area) => levels[area] == PriorityLevel.alta)
        .toList();

    final areas = <PriorityArea, AreaPriority>{
      for (final area in PriorityArea.values)
        area: AreaPriority(
          area: area,
          score: scores[area] ?? 0,
          level: levels[area] ?? PriorityLevel.bassa,
          compressedFromHigh: compressed.contains(area),
        ),
    };

    final totalScore = PriorityArea.values.fold<int>(
      0,
      (sum, area) => sum + (scores[area] ?? 0),
    );

    return DiagnosisPriorityResult(
      areas: areas,
      orderedAreas: orderedAreas,
      shownHighAreas: shownHighAreas,
      compressedFromHigh: compressed,
      safetyRuleApplied: safetyRuleApplied,
      totalScore: totalScore,
    );
  }

  PriorityLevel _classify(int score) {
    if (score <= 2) return PriorityLevel.bassa;
    if (score <= 5) return PriorityLevel.media;
    return PriorityLevel.alta;
  }

  int _compareAreasByScore(
    Map<PriorityArea, int> scores,
    PriorityArea a,
    PriorityArea b,
  ) {
    final scoreDelta = (scores[b] ?? 0).compareTo(scores[a] ?? 0);
    if (scoreDelta != 0) return scoreDelta;
    return _areaOrder.indexOf(a).compareTo(_areaOrder.indexOf(b));
  }
}
