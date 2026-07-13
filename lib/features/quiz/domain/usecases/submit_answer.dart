import 'package:artrosi_cane/features/quiz/domain/entities/quiz_answer.dart';
import 'package:artrosi_cane/features/quiz/domain/repositories/quiz_repository.dart';

class SubmitAnswer {
  SubmitAnswer(this.repository);

  final QuizRepository repository;

  Future<List<QuizAnswer>> call(
    List<QuizAnswer> current,
    QuizAnswer newAnswer,
  ) async {
    final updated = List<QuizAnswer>.from(current);
    final index = updated.indexWhere(
      (answer) => answer.questionId == newAnswer.questionId,
    );
    if (index >= 0) {
      updated[index] = newAnswer;
    } else {
      updated.add(newAnswer);
    }
    await repository.saveProgress(updated);
    return updated;
  }
}
