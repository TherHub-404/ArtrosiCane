import 'package:artrosi_cane/features/quiz/domain/entities/quiz_question.dart';
import 'package:artrosi_cane/features/quiz/domain/repositories/quiz_repository.dart';

class GetQuestions {
  GetQuestions(this.repository);

  final QuizRepository repository;

  Future<List<QuizQuestion>> call() => repository.getQuestions();
}
