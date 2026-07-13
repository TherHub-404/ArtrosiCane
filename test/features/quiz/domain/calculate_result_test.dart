import 'package:artrosi_cane/features/quiz/domain/entities/quiz_answer.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/quiz_result.dart';
import 'package:artrosi_cane/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:artrosi_cane/features/quiz/domain/usecases/calculate_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockQuizRepository extends Mock implements QuizRepository {}

class _FakeQuizResult extends Fake implements QuizResult {}

void main() {
  late _MockQuizRepository repository;
  late CalculateResult usecase;

  setUpAll(() {
    registerFallbackValue(_FakeQuizResult());
  });

  setUp(() {
    repository = _MockQuizRepository();
    usecase = CalculateResult(repository);
    when(() => repository.saveLastResult(any())).thenAnswer((_) async {});
  });

  test('Calcola rischio basso per punteggio <=2', () async {
    final answers = [
      const QuizAnswer(questionId: 'q1', value: 1),
      const QuizAnswer(questionId: 'q2', value: 1),
    ];

    final result = await usecase(answers);

    expect(result.riskLevel, RiskLevel.basso);
    verify(() => repository.saveLastResult(result)).called(1);
  });

  test('Calcola rischio medio per punteggio 6-11', () async {
    final answers = List.generate(
      6,
      (index) => QuizAnswer(questionId: 'q$index', value: 1),
    );

    final result = await usecase(answers);

    expect(result.riskLevel, RiskLevel.medio);
  });

  test('Calcola rischio alto per punteggio >=12', () async {
    final answers = List.generate(
      6,
      (index) => QuizAnswer(questionId: 'q$index', value: 2),
    );

    final result = await usecase(answers);

    expect(result.riskLevel, RiskLevel.alto);
  });
}
