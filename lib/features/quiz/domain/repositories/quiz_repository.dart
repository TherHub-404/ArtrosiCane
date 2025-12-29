import 'package:artrosi_cane/features/quiz/domain/entities/quiz_answer.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/quiz_question.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/quiz_result.dart';

abstract class QuizRepository {
  Future<List<QuizQuestion>> getQuestions();
  Future<void> saveProgress(List<QuizAnswer> answers);
  Future<List<QuizAnswer>> loadProgress();
  Future<void> saveLastResult(QuizResult result);
  Future<QuizResult?> loadLastResult();
}
