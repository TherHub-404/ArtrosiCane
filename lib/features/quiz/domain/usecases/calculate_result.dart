import 'package:artrosi_cane/features/quiz/domain/entities/quiz_answer.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/quiz_result.dart';
import 'package:artrosi_cane/features/quiz/domain/repositories/quiz_repository.dart';

class CalculateResult {
  CalculateResult(this.repository);

  final QuizRepository repository;

  Future<QuizResult> call(
    List<QuizAnswer> answers, {
    int scoreAdjustment = 0,
  }) async {
    final score =
        answers.fold<int>(0, (prev, answer) => prev + answer.value) +
        scoreAdjustment;
    final riskLevel = _mapScoreToRisk(score);
    final result = QuizResult(riskLevel: riskLevel, score: score);
    await repository.saveLastResult(result);
    return result;
  }

  RiskLevel _mapScoreToRisk(int score) {
    if (score <= 2) return RiskLevel.basso;
    if (score <= 6) return RiskLevel.medio;
    return RiskLevel.alto;
  }
}
