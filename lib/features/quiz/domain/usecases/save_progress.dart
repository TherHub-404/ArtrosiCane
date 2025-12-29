import 'package:artrosi_cane/features/quiz/domain/entities/quiz_answer.dart';
import 'package:artrosi_cane/features/quiz/domain/repositories/quiz_repository.dart';

class SaveProgress {
  SaveProgress(this.repository);

  final QuizRepository repository;

  Future<void> call(List<QuizAnswer> answers) => repository.saveProgress(answers);
}
