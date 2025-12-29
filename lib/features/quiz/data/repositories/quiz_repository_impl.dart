import 'package:artrosi_cane/core/data/preferences_data_source.dart';
import 'package:artrosi_cane/features/quiz/data/datasources/quiz_local_data_source.dart';
import 'package:artrosi_cane/features/quiz/data/models/quiz_answer_model.dart';
import 'package:artrosi_cane/features/quiz/data/models/quiz_result_model.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/quiz_answer.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/quiz_question.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/quiz_result.dart';
import 'package:artrosi_cane/features/quiz/domain/repositories/quiz_repository.dart';

class QuizRepositoryImpl implements QuizRepository {
  QuizRepositoryImpl(
    this._localDataSource,
    this._preferencesDataSource,
  );

  final QuizLocalDataSource _localDataSource;
  final PreferencesDataSource _preferencesDataSource;

  @override
  Future<List<QuizQuestion>> getQuestions() async {
    final models = await _localDataSource.loadQuestions();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<QuizAnswer>> loadProgress() async {
    final models = await _preferencesDataSource.loadQuizProgress();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> saveLastResult(QuizResult result) async {
    final model = QuizResultModel.fromEntity(result);
    await _preferencesDataSource.saveLastResult(model);
  }

  @override
  Future<QuizResult?> loadLastResult() async {
    final model = await _preferencesDataSource.loadLastResult();
    return model?.toEntity();
  }

  @override
  Future<void> saveProgress(List<QuizAnswer> answers) async {
    final models = answers.map(QuizAnswerModel.fromEntity).toList();
    await _preferencesDataSource.saveQuizProgress(models);
  }
}
