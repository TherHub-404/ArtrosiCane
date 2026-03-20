import 'package:artrosi_cane/features/quiz/domain/entities/diagnosis_priority_models.dart';
import 'package:artrosi_cane/features/quiz/domain/services/diagnosis_priority_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = DiagnosisPriorityEngine();

  test('Riproduce il caso esempio del PDF', () {
    final result = engine.evaluate(
      const DiagnosisPriorityInput(
        joints: {DiagnosisJoint.anca, DiagnosisJoint.colonna},
        mobility: DiagnosisMobility.moderata,
        rigidityFrequency: DiagnosisRigidityFrequency.treQuattro,
        recovery: DiagnosisRecovery.unPoPeggio,
        hasHomeRiskFactors: true,
        weightTrend: DiagnosisWeightTrend.inAumento,
        movementRhythm: DiagnosisMovementRhythm.irregolareWeekend,
      ),
    );

    expect(result.area(PriorityArea.dolore).score, 7);
    expect(result.area(PriorityArea.ambiente).score, 4);
    expect(result.area(PriorityArea.peso).score, 3);
    expect(result.area(PriorityArea.movimento).score, 4);
    expect(result.area(PriorityArea.routineCarico).score, 5);

    expect(result.area(PriorityArea.dolore).level, PriorityLevel.alta);
    expect(result.area(PriorityArea.ambiente).level, PriorityLevel.media);
    expect(result.area(PriorityArea.peso).level, PriorityLevel.media);
    expect(result.area(PriorityArea.movimento).level, PriorityLevel.media);
    expect(result.area(PriorityArea.routineCarico).level, PriorityLevel.media);
  });

  test('Non espone mai piu di due aree alte', () {
    final result = engine.evaluate(
      const DiagnosisPriorityInput(
        joints: {
          DiagnosisJoint.anca,
          DiagnosisJoint.colonna,
          DiagnosisJoint.ginocchio,
        },
        mobility: DiagnosisMobility.avanzata,
        rigidityFrequency: DiagnosisRigidityFrequency.cinqueSette,
        recovery: DiagnosisRecovery.moltoPeggio,
        hasHomeRiskFactors: true,
        weightTrend: DiagnosisWeightTrend.inAumento,
        movementRhythm: DiagnosisMovementRhythm.irregolareWeekend,
      ),
    );

    expect(result.shownHighAreas.length, lessThanOrEqualTo(2));
    for (final area in result.compressedFromHigh) {
      expect(result.area(area).level, PriorityLevel.media);
      expect(result.area(area).compressedFromHigh, isTrue);
    }
  });

  test('Ordina le aree per punteggio decrescente', () {
    final result = engine.evaluate(
      const DiagnosisPriorityInput(
        joints: {DiagnosisJoint.spalla},
        mobility: DiagnosisMobility.lieve,
        rigidityFrequency: DiagnosisRigidityFrequency.unoDue,
        recovery: DiagnosisRecovery.uguale,
        hasHomeRiskFactors: false,
        weightTrend: DiagnosisWeightTrend.stabile,
        movementRhythm: DiagnosisMovementRhythm.regolareOgniGiorno,
      ),
    );

    final orderedScores = result.orderedAreas
        .map((area) => result.area(area).score)
        .toList();

    for (var i = 1; i < orderedScores.length; i++) {
      expect(orderedScores[i - 1] >= orderedScores[i], isTrue);
    }
  });
}
