import 'dart:convert';
import 'dart:io';

import 'package:artrosi_cane/l10n/app_translation_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const initialAssessment = <({String id, String question, List<String> answers})>[
    (
      id: 'q1',
      question: 'Il tuo cane si muove con meno voglia del solito?',
      answers: ['No, è come sempre', 'Ogni tanto sì', 'Sì, spesso'],
    ),
    (
      id: 'q2',
      question: 'Ha ancora voglia di uscire, giocare, muoversi?',
      answers: [
        'Sì, come sempre',
        'Un po\' meno del solito',
        'Molto meno, si vede chiaramente',
      ],
    ),
    (
      id: 'q3',
      question:
          'Dopo una passeggiata o le scale, lo vedi leccarsi le zampe, cambiare spesso posizione o evitare di muoversi?',
      answers: [
        'Quasi mai',
        'Qualche volta, se si è stancato di più',
        'Spesso, anche per cose di tutti i giorni',
      ],
    ),
    (
      id: 'q4',
      question:
          'In generale, come sta andando il tuo cane in questa settimana?',
      answers: [
        'Bene, sereno',
        'Un po\' meno in forma del solito',
        'Visibilmente giù',
      ],
    ),
  ];

  const updatedLocalizedContent = <String>{
    'Diario giornaliero',
    'Oggi si è mosso con difficoltà o ha zoppicato?',
    'Un po\'',
    'Sì, parecchio',
    'Quanto pensi che si muoverà oggi?',
    'Poco (0-10 min)',
    'Il solito (10-20 min)',
    'Tanto (20+ min)',
    'Oggi c\'è qualcosa di questo in giro? Seleziona tutto quello che c\'è',
    'Caldo forte',
    'Sabbia',
    'Scale',
    'Pavimenti scivolosi',
    'Tante ore in auto',
    'Acqua/mare',
    'Stamattina, rispetto a ieri, come lo hai trovato?',
    'Uguale',
    'Un po\' più rigido',
    'Molto più rigido',
    'Oggi vai piano e con calma.',
    'Meglio due passeggiate corte che una lunga.',
    'Evita corse improvvise o giochi troppo bruschi.',
    'Un video pensato apposta per oggi.',
    'Esercizi facili per le sue articolazioni',
    'Routine di 25 secondi, tutti i giorni',
    'Domani ti bastano 20 secondi per aggiornare il Diario.',
  };

  test(
    'initial assessment contains the approved four questions and answers',
    () {
      final questions =
          jsonDecode(File('assets/questions_it.json').readAsStringSync())
              as List<dynamic>;

      expect(questions, hasLength(initialAssessment.length));
      for (var index = 0; index < initialAssessment.length; index++) {
        final actual = questions[index] as Map<String, dynamic>;
        final expected = initialAssessment[index];
        expect(actual['id'], expected.id);
        expect(actual['text'], expected.question);
        expect(actual['options'], expected.answers);
      }
    },
  );

  test(
    'all updated content is translated in every supported non-Italian locale',
    () {
      final assessmentContent = initialAssessment.expand(
        (question) => <String>[question.question, ...question.answers],
      );
      final requiredKeys = <String>{
        ...assessmentContent,
        ...updatedLocalizedContent,
      };

      expect(
        appTranslationCatalog.keys,
        containsAll(<String>['en', 'fr', 'de']),
      );
      for (final locale in <String>['en', 'fr', 'de']) {
        final translations = appTranslationCatalog[locale]!;
        for (final key in requiredKeys) {
          expect(
            translations[key],
            isNotNull,
            reason: 'Missing $locale translation for "$key"',
          );
          expect(
            translations[key],
            isNot(key),
            reason: '$locale must not fall back to Italian for "$key"',
          );
        }
      }
    },
  );
}
