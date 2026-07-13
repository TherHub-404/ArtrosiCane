import 'package:artrosi_cane/core/providers/preferences_data_source_provider.dart';
import 'package:artrosi_cane/features/quiz/data/datasources/quiz_local_data_source.dart';
import 'package:artrosi_cane/features/quiz/data/repositories/quiz_repository_impl.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/quiz_answer.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/quiz_question.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/quiz_result.dart';
import 'package:artrosi_cane/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:artrosi_cane/features/quiz/domain/usecases/calculate_result.dart';
import 'package:artrosi_cane/features/quiz/domain/usecases/get_questions.dart';
import 'package:artrosi_cane/features/quiz/domain/usecases/load_progress.dart';
import 'package:artrosi_cane/features/quiz/domain/usecases/save_progress.dart';
import 'package:artrosi_cane/features/quiz/domain/usecases/submit_answer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final quizLocalDataSourceProvider = Provider<QuizLocalDataSource>(
  (ref) => const AssetQuizLocalDataSource('assets/questions_it.json'),
);

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final local = ref.watch(quizLocalDataSourceProvider);
  final prefs = ref.watch(preferencesDataSourceProvider);
  return QuizRepositoryImpl(local, prefs);
});

final getQuestionsUseCaseProvider = Provider<GetQuestions>((ref) {
  final repository = ref.watch(quizRepositoryProvider);
  return GetQuestions(repository);
});

final submitAnswerUseCaseProvider = Provider<SubmitAnswer>((ref) {
  final repository = ref.watch(quizRepositoryProvider);
  return SubmitAnswer(repository);
});

final calculateResultUseCaseProvider = Provider<CalculateResult>((ref) {
  final repository = ref.watch(quizRepositoryProvider);
  return CalculateResult(repository);
});

final loadProgressUseCaseProvider = Provider<LoadProgress>((ref) {
  final repository = ref.watch(quizRepositoryProvider);
  return LoadProgress(repository);
});

final saveProgressUseCaseProvider = Provider<SaveProgress>((ref) {
  final repository = ref.watch(quizRepositoryProvider);
  return SaveProgress(repository);
});

class QuizState {
  const QuizState({
    this.questions = const [],
    this.answers = const [],
    this.currentIndex = 0,
    this.result,
    this.isLoading = false,
  });

  final List<QuizQuestion> questions;
  final List<QuizAnswer> answers;
  final int currentIndex;
  final QuizResult? result;
  final bool isLoading;

  QuizQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  bool get hasCompleted => result != null;

  QuizState copyWith({
    List<QuizQuestion>? questions,
    List<QuizAnswer>? answers,
    int? currentIndex,
    QuizResult? result,
    bool? isLoading,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      currentIndex: currentIndex ?? this.currentIndex,
      result: result ?? this.result,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class QuizController extends StateNotifier<QuizState> {
  QuizController({
    required this.getQuestions,
    required this.submitAnswer,
    required this.calculateResult,
    required this.loadProgress,
  }) : super(const QuizState());

  final GetQuestions getQuestions;
  final SubmitAnswer submitAnswer;
  final CalculateResult calculateResult;
  final LoadProgress loadProgress;

  Future<void> loadInitial() async {
    state = const QuizState(isLoading: true);
    try {
      final questions = await getQuestions();
      state = state.copyWith(questions: questions, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> selectAnswer(String questionId, int value) async {
    final newAnswer = QuizAnswer(questionId: questionId, value: value);
    final updatedAnswers = await submitAnswer(state.answers, newAnswer);
    state = state.copyWith(answers: updatedAnswers);
  }

  void setIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }

  Future<void> goToNext({int scoreAdjustment = 0}) async {
    if (state.currentIndex >= state.questions.length - 1) {
      final result = await calculateResult(
        state.answers,
        scoreAdjustment: scoreAdjustment,
      );
      state = state.copyWith(result: result);
      return;
    }
    state = state.copyWith(currentIndex: state.currentIndex + 1);
  }

  Future<void> submitQuiz({int scoreAdjustment = 0}) async {
    final result = await calculateResult(
      state.answers,
      scoreAdjustment: scoreAdjustment,
    );
    state = state.copyWith(result: result);
  }

  void reset() {
    state = const QuizState();
    loadInitial();
  }
}

final quizControllerProvider = StateNotifierProvider<QuizController, QuizState>(
  (ref) {
    final controller = QuizController(
      getQuestions: ref.watch(getQuestionsUseCaseProvider),
      submitAnswer: ref.watch(submitAnswerUseCaseProvider),
      calculateResult: ref.watch(calculateResultUseCaseProvider),
      loadProgress: ref.watch(loadProgressUseCaseProvider),
    );
    controller.loadInitial();
    return controller;
  },
);
