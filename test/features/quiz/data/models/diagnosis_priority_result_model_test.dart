import 'package:artrosi_cane/features/quiz/data/models/diagnosis_priority_result_model.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/diagnosis_priority_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Serializza e deserializza il risultato priorita', () {
    const model = DiagnosisPriorityResultModel(
      areas: {
        PriorityArea.dolore: AreaPriority(
          area: PriorityArea.dolore,
          score: 7,
          level: PriorityLevel.alta,
        ),
        PriorityArea.ambiente: AreaPriority(
          area: PriorityArea.ambiente,
          score: 4,
          level: PriorityLevel.media,
        ),
        PriorityArea.peso: AreaPriority(
          area: PriorityArea.peso,
          score: 3,
          level: PriorityLevel.media,
        ),
        PriorityArea.movimento: AreaPriority(
          area: PriorityArea.movimento,
          score: 4,
          level: PriorityLevel.media,
        ),
        PriorityArea.routineCarico: AreaPriority(
          area: PriorityArea.routineCarico,
          score: 5,
          level: PriorityLevel.media,
          compressedFromHigh: true,
        ),
      },
      orderedAreas: [
        PriorityArea.dolore,
        PriorityArea.routineCarico,
        PriorityArea.ambiente,
      ],
      shownHighAreas: [PriorityArea.dolore],
      compressedFromHigh: [PriorityArea.routineCarico],
      safetyRuleApplied: false,
      totalScore: 23,
    );

    final json = model.toJson();
    final decoded = DiagnosisPriorityResultModel.fromJson(json);

    expect(decoded.totalScore, 23);
    expect(decoded.areas[PriorityArea.dolore]?.level, PriorityLevel.alta);
    expect(
      decoded.areas[PriorityArea.routineCarico]?.compressedFromHigh,
      isTrue,
    );
    expect(decoded.orderedAreas.first, PriorityArea.dolore);
    expect(decoded.shownHighAreas, [PriorityArea.dolore]);
  });
}
