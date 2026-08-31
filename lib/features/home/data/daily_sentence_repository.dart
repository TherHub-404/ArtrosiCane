import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailySentence {
  const DailySentence({
    required this.languageCode,
    required this.monthNum,
    required this.dayNum,
    required this.themeMonth,
    required this.category,
    required this.categoryKey,
    required this.phrase,
    required this.explanation,
    required this.microAction,
  });

  factory DailySentence.fromMap(Map<String, dynamic> map) {
    return DailySentence(
      languageCode: (map['language_code'] as String?)?.trim() ?? 'it',
      monthNum: (map['month_num'] as num?)?.toInt() ?? DateTime.now().month,
      dayNum: (map['day_num'] as num?)?.toInt() ?? 1,
      themeMonth: (map['theme_month'] as String?)?.trim() ?? '',
      category: (map['category'] as String?)?.trim() ?? '',
      categoryKey: (map['category_key'] as String?)?.trim() ?? '',
      phrase: (map['phrase'] as String?)?.trim() ?? '',
      explanation: (map['explanation'] as String?)?.trim() ?? '',
      microAction: (map['micro_action'] as String?)?.trim() ?? '',
    );
  }

  final String languageCode;
  final int monthNum;
  final int dayNum;
  final String themeMonth;
  final String category;
  final String categoryKey;
  final String phrase;
  final String explanation;
  final String microAction;
}

class DailySentenceRepository {
  DailySentenceRepository(this._client);

  final SupabaseClient _client;

  Future<DailySentence?> fetchForToday({
    required String language,
    required int month,
    required int day,
  }) async {
    final lang = _normalizeLanguage(language);
    final m = month.clamp(1, 12);
    // DB holds days 1..30; clamp to 30 for 31-day months and Feb 29.
    final d = day.clamp(1, 30);

    try {
      final response = await _client
          .from('daily_sentences')
          .select(
            'language_code, month_num, day_num, theme_month, category, category_key, phrase, explanation, micro_action',
          )
          .eq('language_code', lang)
          .eq('month_num', m)
          .eq('day_num', d)
          .maybeSingle();
      if (response == null) {
        return await _fetchFallback(lang: lang, month: m, day: d);
        }
      return DailySentence.fromMap(response);
    } on PostgrestException {
      return null;
    }
  }

  Future<DailySentence?> _fetchFallback({
    required String lang,
    required int month,
    required int day,
  }) async {
    // Fallback chain: same lang any day in month, then Italian for the day, then any.
    try {
      final res = await _client
          .from('daily_sentences')
          .select(
            'language_code, month_num, day_num, theme_month, category, category_key, phrase, explanation, micro_action',
          )
          .eq('language_code', lang)
          .eq('month_num', month)
          .order('day_num')
          .limit(1)
          .maybeSingle();
      if (res != null) return DailySentence.fromMap(res);
    } on PostgrestException {
      // ignore, try next fallback
    }
    try {
      final res = await _client
          .from('daily_sentences')
          .select(
            'language_code, month_num, day_num, theme_month, category, category_key, phrase, explanation, micro_action',
          )
          .eq('language_code', 'it')
          .eq('month_num', month)
          .eq('day_num', day)
          .maybeSingle();
      if (res != null) return DailySentence.fromMap(res);
    } on PostgrestException {
      // ignore
    }
    return null;
  }

  static String _normalizeLanguage(String code) {
    switch (code) {
      case 'it':
      case 'en':
      case 'fr':
      case 'de':
        return code;
      default:
        return 'it';
    }
  }
}

final dailySentenceRepositoryProvider = Provider<DailySentenceRepository>((
  ref,
) {
  final client = Supabase.instance.client;
  return DailySentenceRepository(client);
});
