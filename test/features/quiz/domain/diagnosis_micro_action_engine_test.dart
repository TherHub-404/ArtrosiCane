import 'package:artrosi_cane/features/quiz/domain/entities/diagnosis_micro_action_models.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/diagnosis_priority_models.dart';
import 'package:artrosi_cane/features/quiz/domain/services/diagnosis_micro_action_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = DiagnosisMicroActionEngine();

  DiagnosisPriorityResult sampleResult({
    required List<PriorityArea> ordered,
    required List<PriorityArea> shownHigh,
  }) {
    AreaPriority area(PriorityArea area, int score, PriorityLevel level) {
      return AreaPriority(area: area, score: score, level: level);
    }

    return DiagnosisPriorityResult(
      areas: {
        PriorityArea.dolore: area(PriorityArea.dolore, 7, PriorityLevel.alta),
        PriorityArea.routineCarico: area(
          PriorityArea.routineCarico,
          6,
          PriorityLevel.alta,
        ),
        PriorityArea.ambiente: area(
          PriorityArea.ambiente,
          4,
          PriorityLevel.media,
        ),
        PriorityArea.movimento: area(
          PriorityArea.movimento,
          3,
          PriorityLevel.media,
        ),
        PriorityArea.peso: area(PriorityArea.peso, 2, PriorityLevel.bassa),
      },
      orderedAreas: ordered,
      shownHighAreas: shownHigh,
      compressedFromHigh: const [],
      safetyRuleApplied: false,
      totalScore: 22,
    );
  }

  test('Genera da 3 a 5 micro-azioni', () {
    final plan = engine.buildPlan(
      sampleResult(
        ordered: const [
          PriorityArea.dolore,
          PriorityArea.routineCarico,
          PriorityArea.ambiente,
          PriorityArea.movimento,
          PriorityArea.peso,
        ],
        shownHigh: const [PriorityArea.dolore, PriorityArea.routineCarico],
      ),
    );

    expect(plan.items.length, inInclusiveRange(3, 5));
  });

  test('Focus sulle prime due aree alte', () {
    final plan = engine.buildPlan(
      sampleResult(
        ordered: const [
          PriorityArea.dolore,
          PriorityArea.routineCarico,
          PriorityArea.ambiente,
          PriorityArea.movimento,
          PriorityArea.peso,
        ],
        shownHigh: const [PriorityArea.dolore, PriorityArea.routineCarico],
      ),
    );

    expect(plan.focusAreas, [PriorityArea.dolore, PriorityArea.routineCarico]);
  });

  test(
    'Alterna action e avoid quando possibile e non ripete area consecutiva',
    () {
      final plan = engine.buildPlan(
        sampleResult(
          ordered: const [
            PriorityArea.dolore,
            PriorityArea.routineCarico,
            PriorityArea.ambiente,
            PriorityArea.movimento,
            PriorityArea.peso,
          ],
          shownHigh: const [PriorityArea.dolore, PriorityArea.routineCarico],
        ),
      );

      for (var i = 1; i < plan.items.length; i++) {
        final prev = plan.items[i - 1];
        final curr = plan.items[i];
        expect(curr.primaryArea == prev.primaryArea, isFalse);
      }

      final actionCount = plan.items
          .where((item) => item.type == DiagnosisMicroActionType.action)
          .length;
      final avoidCount = plan.items
          .where((item) => item.type == DiagnosisMicroActionType.avoid)
          .length;
      expect(actionCount, greaterThan(0));
      expect(avoidCount, greaterThan(0));
    },
  );
}
