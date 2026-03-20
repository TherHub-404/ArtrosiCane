enum DiagnosisJoint { colonna, anca, ginocchio, gomito, spalla }

enum DiagnosisMobility { lieve, moderata, avanzata }

enum DiagnosisRigidityFrequency { mai, unoDue, treQuattro, cinqueSette }

enum DiagnosisRecovery { uguale, unPoPeggio, moltoPeggio }

enum DiagnosisWeightTrend { stabile, inAumento, nonSo }

enum DiagnosisMovementRhythm {
  regolareOgniGiorno,
  giorniAlterniTanto,
  irregolareWeekend,
}

enum PriorityArea { dolore, ambiente, peso, movimento, routineCarico }

enum PriorityLevel { bassa, media, alta }

class DiagnosisPriorityInput {
  const DiagnosisPriorityInput({
    required this.joints,
    required this.mobility,
    required this.rigidityFrequency,
    required this.recovery,
    required this.hasHomeRiskFactors,
    required this.weightTrend,
    required this.movementRhythm,
  });

  final Set<DiagnosisJoint> joints;
  final DiagnosisMobility mobility;
  final DiagnosisRigidityFrequency rigidityFrequency;
  final DiagnosisRecovery recovery;
  final bool hasHomeRiskFactors;
  final DiagnosisWeightTrend weightTrend;
  final DiagnosisMovementRhythm movementRhythm;
}

class AreaPriority {
  const AreaPriority({
    required this.area,
    required this.score,
    required this.level,
    this.compressedFromHigh = false,
  });

  final PriorityArea area;
  final int score;
  final PriorityLevel level;
  final bool compressedFromHigh;
}

class DiagnosisPriorityResult {
  const DiagnosisPriorityResult({
    required this.areas,
    required this.orderedAreas,
    required this.shownHighAreas,
    required this.compressedFromHigh,
    required this.safetyRuleApplied,
    required this.totalScore,
  });

  final Map<PriorityArea, AreaPriority> areas;
  final List<PriorityArea> orderedAreas;
  final List<PriorityArea> shownHighAreas;
  final List<PriorityArea> compressedFromHigh;
  final bool safetyRuleApplied;
  final int totalScore;

  AreaPriority area(PriorityArea area) =>
      areas[area] ??
      AreaPriority(area: area, score: 0, level: PriorityLevel.bassa);
}

String priorityAreaLabel(PriorityArea area) {
  switch (area) {
    case PriorityArea.dolore:
      return 'Dolore';
    case PriorityArea.ambiente:
      return 'Ambiente';
    case PriorityArea.peso:
      return 'Peso';
    case PriorityArea.movimento:
      return 'Movimento';
    case PriorityArea.routineCarico:
      return 'Routine/Carico';
  }
}

String priorityLevelLabel(PriorityLevel level) {
  switch (level) {
    case PriorityLevel.alta:
      return 'Alta';
    case PriorityLevel.media:
      return 'Media';
    case PriorityLevel.bassa:
      return 'Bassa';
  }
}
