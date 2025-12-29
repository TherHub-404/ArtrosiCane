import 'package:artrosi_cane/features/quiz/domain/entities/quiz_question.dart';

class QuizQuestionModel {
  const QuizQuestionModel({
    required this.id,
    required this.text,
    required this.options,
  });

  final String id;
  final String text;
  final List<String> options;

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      id: json['id'] as String,
      text: json['text'] as String,
      options:
          (json['options'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }

  QuizQuestion toEntity() => QuizQuestion(id: id, text: text, options: options);
}
