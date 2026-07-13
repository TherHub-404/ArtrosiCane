import 'package:artrosi_cane/features/quiz/domain/entities/quiz_answer.dart';

class QuizAnswerModel {
  factory QuizAnswerModel.fromEntity(QuizAnswer answer) {
    return QuizAnswerModel(questionId: answer.questionId, value: answer.value);
  }

  factory QuizAnswerModel.fromJson(Map<String, dynamic> json) {
    return QuizAnswerModel(
      questionId: json['questionId'] as String,
      value: json['value'] as int,
    );
  }
  const QuizAnswerModel({required this.questionId, required this.value});

  final String questionId;
  final int value;

  QuizAnswer toEntity() => QuizAnswer(questionId: questionId, value: value);

  Map<String, dynamic> toJson() => {'questionId': questionId, 'value': value};
}
