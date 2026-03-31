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
    final normalizedMonth = month.clamp(1, 12);
    try {
      final response = await _client
          .from('monthly_sentence')
          .select('month_number, month_name, title, focus, objective, areas')
          .eq('month_number', normalizedMonth)
          .maybeSingle();

      if (response == null) {
        return _fallbackSentenceForMonth(normalizedMonth);
      }
      return MonthlySentence.fromMap(response);
    } on PostgrestException {
      return _fallbackSentenceForMonth(normalizedMonth);
    }
  }

  MonthlySentence? _fallbackSentenceForMonth(int month) {
    return _fallbackMonthlySentences[month];
  }

  static const Map<int, MonthlySentence> _fallbackMonthlySentences = {
    1: MonthlySentence(
      monthNumber: 1,
      monthName: 'Gennaio',
      title: 'GENNAIO - CONSAPEVOLEZZA E OSSERVAZIONE',
      focus: 'Ascolta (A di A.L.L.E.A.T.O.)',
      objective: 'Imparare a vedere.',
      areas: [
        'Segnali precoci',
        'Scale, auto, divano',
        'Rigidita mattutina',
        'Diario semplice',
        'Differenza tra va meglio e e stabile',
      ],
    ),
    2: MonthlySentence(
      monthNumber: 2,
      monthName: 'Febbraio',
      title: 'FEBBRAIO - PESO E CONTROLLO',
      focus: 'Metodo P.E.S.O.',
      objective: 'Alleggerire carico articolare.',
      areas: [
        'Pesare il cibo',
        'Ridurre senza affamare',
        'Porzioni volumetriche',
        'Monitoraggio mensile',
        'Micro-errori quotidiani',
      ],
    ),
    3: MonthlySentence(
      monthNumber: 3,
      monthName: 'Marzo',
      title: 'MARZO - MOVIMENTO INTELLIGENTE',
      focus: 'Rispetta il ritmo (R di A.R.M.O.N.I.A.)',
      objective: 'Aumentare senza ricadute.',
      areas: [
        'Progressione graduale',
        'Terreno regolare vs irregolare',
        'Fine passeggiata buona',
        'Micro-uscite',
        'Consolidamento',
      ],
    ),
    4: MonthlySentence(
      monthNumber: 4,
      monthName: 'Aprile',
      title: 'APRILE - AMBIENTE E CASA',
      focus: 'Esplora (E di A.L.L.E.A.T.O.)',
      objective: 'Togliere microtraumi invisibili.',
      areas: [
        'Pavimenti scivolosi',
        'Rampe',
        'Scale',
        'Zone di riposo',
        'Auto',
      ],
    ),
    5: MonthlySentence(
      monthNumber: 5,
      monthName: 'Maggio',
      title: 'MAGGIO - MUSCOLO E STABILITA',
      focus: 'Mantieni il tono',
      objective: 'Costruire protezione attiva.',
      areas: [
        'Lieve salita',
        'Passo controllato',
        'Rinforzo leggero',
        'Stabilita su terreno naturale',
        'Frequenza > intensita',
      ],
    ),
    6: MonthlySentence(
      monthNumber: 6,
      monthName: 'Giugno',
      title: 'GIUGNO - CALDO E GESTIONE ESTIVA',
      focus: 'Adattare il carico',
      objective: 'Evitare infiammazioni da sovraccarico estivo.',
      areas: [
        'Orari corretti',
        'Asfalto caldo',
        'Idratazione',
        'Rigidita serale',
        'Attivita in acqua controllata',
      ],
    ),
    7: MonthlySentence(
      monthNumber: 7,
      monthName: 'Luglio',
      title: 'LUGLIO - VACANZE E SPOSTAMENTI',
      focus: 'Continuita fuori casa',
      objective: 'Non perdere la stabilita conquistata.',
      areas: [
        'Auto e salti',
        'Spiaggia',
        'Sabbia profonda',
        'Nuoto dosato',
        'Ritmo alterato',
      ],
    ),
    8: MonthlySentence(
      monthNumber: 8,
      monthName: 'Agosto',
      title: 'AGOSTO - COSTANZA',
      focus: 'Agisci con continuita (A di A.R.M.O.N.I.A.)',
      objective: 'Evitare il tutto o niente.',
      areas: [
        'Mini routine',
        'Diario veloce',
        'Micro-obiettivi',
        'Riduzione eccessi',
        'Stabilizzazione',
      ],
    ),
    9: MonthlySentence(
      monthNumber: 9,
      monthName: 'Settembre',
      title: 'SETTEMBRE - RICALIBRAZIONE',
      focus: 'Tiene traccia (T di A.L.L.E.A.T.O.)',
      objective: 'Correggere prima che peggiori.',
      areas: [
        'Revisione priorita',
        'Tendenza mensile',
        'Segnali nascosti',
        'Aggiustamenti piccoli',
        'Contatto con veterinario curante (se serve)',
      ],
    ),
    10: MonthlySentence(
      monthNumber: 10,
      monthName: 'Ottobre',
      title: 'OTTOBRE - CLIMA E RIGIDITA',
      focus: 'Osserva (O di A.L.L.E.A.T.O.)',
      objective: 'Prevenire riacutizzazioni.',
      areas: [
        'Attivazione prima uscita',
        'Riscaldamento lento',
        'Tempo di adattamento',
        'Segnali serali',
        'Terapia regolare',
      ],
    ),
    11: MonthlySentence(
      monthNumber: 11,
      monthName: 'Novembre',
      title: 'NOVEMBRE - MULTIMODALITA',
      focus: 'Integra quando serve (I di A.R.M.O.N.I.A.)',
      objective: 'Stabilita del dolore.',
      areas: [
        'Continuita terapeutica',
        'Non sospendere troppo presto',
        'Farmaco non e fallimento',
        'Sinergia movimento + peso + ambiente',
        'Monitoraggio risposta',
      ],
    ),
    12: MonthlySentence(
      monthNumber: 12,
      monthName: 'Dicembre',
      title: 'DICEMBRE - CONSOLIDAMENTO',
      focus: 'Armonia',
      objective: 'Trasformare gestione in normalita.',
      areas: [
        'Cosa ha funzionato',
        'Abitudini stabili',
        'Riduzione ricadute',
        'Relazione cane-proprietario',
        'Pianificazione nuovo anno',
      ],
    ),
  };
}

final monthlySentenceRepositoryProvider = Provider<MonthlySentenceRepository>((
  ref,
) {
  final client = Supabase.instance.client;
  return MonthlySentenceRepository(client);
});
