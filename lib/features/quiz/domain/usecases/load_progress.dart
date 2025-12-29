import 'package:artrosi_cane/features/quiz/domain/entities/quiz_answer.dart';
import 'package:artrosi_cane/features/quiz/domain/repositories/quiz_repository.dart';

class LoadProgress {
  LoadProgress(this.repository);

  final QuizRepository repository;

  Future<List<QuizAnswer>> call() => repository.loadProgress();
}
