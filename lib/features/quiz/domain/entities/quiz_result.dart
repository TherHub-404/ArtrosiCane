enum RiskLevel { basso, medio, alto }

class QuizResult {
  const QuizResult({
    required this.riskLevel,
    required this.score,
  });

  final RiskLevel riskLevel;
  final int score;
}
