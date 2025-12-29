class QuizAnswer {
  const QuizAnswer({
    required this.questionId,
    required this.value,
  });

  final String questionId;
  final int value; // 0 = Mai, 1 = A volte, 2 = Spesso
}
