import 'package:artrosi_cane/features/quiz/domain/entities/quiz_result.dart';

class QuizResultModel {
  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    return QuizResultModel(
      riskLevel: RiskLevel.values.firstWhere(
        (level) => level.name == json['riskLevel'] as String,
      ),
      score: json['score'] as int,
    );
  }

  factory QuizResultModel.fromEntity(QuizResult result) {
    return QuizResultModel(riskLevel: result.riskLevel, score: result.score);
  }
  const QuizResultModel({required this.riskLevel, required this.score});

  final RiskLevel riskLevel;
  final int score;

  Map<String, dynamic> toJson() => {
    'riskLevel': riskLevel.name,
    'score': score,
  };

  QuizResult toEntity() => QuizResult(riskLevel: riskLevel, score: score);
}
