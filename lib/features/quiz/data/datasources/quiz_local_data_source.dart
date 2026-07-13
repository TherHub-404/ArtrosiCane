import 'dart:convert';

import 'package:artrosi_cane/core/errors/exceptions.dart';
import 'package:artrosi_cane/features/quiz/data/models/quiz_question_model.dart';
import 'package:flutter/services.dart';

abstract class QuizLocalDataSource {
  Future<List<QuizQuestionModel>> loadQuestions();
}

class AssetQuizLocalDataSource implements QuizLocalDataSource {
  const AssetQuizLocalDataSource(this.assetPath);

  final String assetPath;

  @override
  Future<List<QuizQuestionModel>> loadQuestions() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final data = json.decode(raw) as List<dynamic>;
      return data
          .map(
            (item) => QuizQuestionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw CacheException('Errore nel caricamento delle domande: $e');
    }
  }
}
