import 'package:artrosi_cane/features/quiz/domain/entities/quiz_answer.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/quiz_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizRemoteDataSource {
  QuizRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<void> saveResult({
    required QuizResult result,
    String? dogId,
    List<QuizAnswer> answers = const [],
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final response = await _client
        .from('quiz_results')
        .insert({
          'owner_id': userId,
          'dog_id': dogId,
          'score': result.score,
          'risk_level': result.riskLevel.name,
        })
        .select('id')
        .limit(1)
        .maybeSingle();

    final resultId = response?['id'] as String?;
    if (resultId == null || answers.isEmpty) return;

    await _client.from('quiz_answers').insert(
          answers
              .map((a) => {
                    'result_id': resultId,
                    'question_id': a.questionId,
                    'answer_value': a.value,
                  })
              .toList(),
        );
  }
}

final quizRemoteDataSourceProvider = Provider<QuizRemoteDataSource>((ref) {
  final client = Supabase.instance.client;
  return QuizRemoteDataSource(client);
});
