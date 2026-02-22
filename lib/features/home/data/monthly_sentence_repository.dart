import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MonthlySentence {
  const MonthlySentence({
    required this.monthNumber,
    required this.monthName,
    required this.title,
    required this.focus,
    required this.objective,
    required this.areas,
  });

  final int monthNumber;
  final String monthName;
  final String title;
  final String focus;
  final String objective;
  final List<String> areas;

  factory MonthlySentence.fromMap(Map<String, dynamic> map) {
    final monthNumber =
        _readInt(map['month_number'] ?? map['month']) ?? DateTime.now().month;
    final monthName =
        _readString(map['month_name']) ?? _italianMonthName(monthNumber);
    final title = _readString(map['title']) ?? monthName.toUpperCase();
    final focus = _readString(map['focus']) ?? '';
    final objective = _readString(map['objective']) ?? '';
    final areas = _readAreas(map['areas'] ?? map['aree']);

    return MonthlySentence(
      monthNumber: monthNumber,
      monthName: monthName,
      title: title,
      focus: focus,
      objective: objective,
      areas: areas,
    );
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _readString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static List<String> _readAreas(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String) {
      return value
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static String _italianMonthName(int month) {
    const months = <String>[
      'Gennaio',
      'Febbraio',
      'Marzo',
      'Aprile',
      'Maggio',
      'Giugno',
      'Luglio',
      'Agosto',
      'Settembre',
      'Ottobre',
      'Novembre',
      'Dicembre',
    ];
    final index = month.clamp(1, 12) - 1;
    return months[index];
  }
}

class MonthlySentenceRepository {
  MonthlySentenceRepository(this._client);

  final SupabaseClient _client;

  Future<MonthlySentence?> fetchSentenceForMonth(int month) async {
    try {
      final response = await _client
          .from('monthly_sentence')
          .select('month_number, month_name, title, focus, objective, areas')
          .eq('month_number', month)
          .maybeSingle();

      if (response == null) return null;
      return MonthlySentence.fromMap(response);
    } on PostgrestException {
      return null;
    }
  }
}

final monthlySentenceRepositoryProvider = Provider<MonthlySentenceRepository>((
  ref,
) {
  final client = Supabase.instance.client;
  return MonthlySentenceRepository(client);
});
