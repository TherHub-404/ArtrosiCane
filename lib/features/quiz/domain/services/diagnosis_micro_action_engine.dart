import 'package:artrosi_cane/features/quiz/domain/entities/diagnosis_micro_action_models.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/diagnosis_priority_models.dart';

class DiagnosisMicroActionEngine {
  const DiagnosisMicroActionEngine();

  DiagnosisMicroActionPlan buildPlan(
    DiagnosisPriorityResult result, {
    int minItems = 3,
    int maxItems = 5,
  }) {
    final focusAreas = _focusAreas(result);
    final areaLevels = {
      for (final area in PriorityArea.values) area: result.area(area).level,
    };

    final scoped = _actionBank
        .where((item) => item.areas.any(focusAreas.contains))
        .toList();

    final ranked = [...scoped]
      ..sort(
        (a, b) =>
            _score(b, focusAreas, areaLevels) -
            _score(a, focusAreas, areaLevels),
      );

    final actions = ranked
        .where((item) => item.type == DiagnosisMicroActionType.action)
        .toList();
    final avoids = ranked
        .where((item) => item.type == DiagnosisMicroActionType.avoid)
        .toList();

    final items = <DiagnosisMicroAction>[];
    final used = <String>{};
    var expectAction = true;

    DiagnosisMicroAction? pickFrom(
      List<DiagnosisMicroAction> source,
      PriorityArea? previousArea,
    ) {
      for (final item in source) {
        if (used.contains(item.id)) continue;
        if (previousArea != null && item.primaryArea == previousArea) continue;
        return item;
      }
      for (final item in source) {
        if (!used.contains(item.id)) return item;
      }
      return null;
    }

    while (items.length < maxItems) {
      final previousArea = items.isEmpty ? null : items.last.primaryArea;
      DiagnosisMicroAction? picked;
      if (expectAction) {
        picked =
            pickFrom(actions, previousArea) ?? pickFrom(avoids, previousArea);
      } else {
        picked =
            pickFrom(avoids, previousArea) ?? pickFrom(actions, previousArea);
      }

      if (picked == null) break;
      items.add(picked);
      used.add(picked.id);
      expectAction = !expectAction;
    }

    if (items.length < minItems) {
      final fallback = [..._actionBank]
        ..sort(
          (a, b) =>
              _score(b, focusAreas, areaLevels) -
              _score(a, focusAreas, areaLevels),
        );
      for (final item in fallback) {
        if (items.length >= minItems) break;
        if (used.contains(item.id)) continue;
        if (items.isNotEmpty && items.last.primaryArea == item.primaryArea)
          continue;
        items.add(item);
        used.add(item.id);
      }
    }

    return DiagnosisMicroActionPlan(
      focusAreas: focusAreas,
      items: items.take(maxItems).toList(),
    );
  }

  List<PriorityArea> _focusAreas(DiagnosisPriorityResult result) {
    final fromHigh = result.shownHighAreas.take(2).toList();
    if (fromHigh.length == 2) return fromHigh;

    final ordered = result.orderedAreas;
    if (fromHigh.length == 1) {
      final second = ordered.firstWhere(
        (area) => area != fromHigh.first,
        orElse: () => fromHigh.first,
      );
      return [fromHigh.first, second];
    }

    return ordered.take(2).toList();
  }

  int _score(
    DiagnosisMicroAction item,
    List<PriorityArea> focusAreas,
    Map<PriorityArea, PriorityLevel> areaLevels,
  ) {
    var score = 0;
    if (item.primaryArea == focusAreas.first) score += 6;
    if (focusAreas.length > 1 && item.primaryArea == focusAreas[1]) score += 5;
    score += item.areas.where(focusAreas.contains).length * 2;

    final level = areaLevels[item.primaryArea] ?? PriorityLevel.bassa;
    switch (level) {
      case PriorityLevel.alta:
        score += 3;
        break;
      case PriorityLevel.media:
        score += 1;
        break;
      case PriorityLevel.bassa:
        break;
    }

    if (item.type == DiagnosisMicroActionType.avoid) {
      score += 1;
    }

    return score;
  }
}

const List<DiagnosisMicroAction> _actionBank = [
  DiagnosisMicroAction(
    id: 'DO_01',
    text: 'Osserva i primi 10 passi al mattino e registra la rigidita.',
    type: DiagnosisMicroActionType.action,
    primaryArea: PriorityArea.dolore,
    areas: {PriorityArea.dolore},
  ),
  DiagnosisMicroAction(
    id: 'DO_02',
    text: 'Riduci del 20% la passeggiata per 5 giorni consecutivi.',
    type: DiagnosisMicroActionType.action,
    primaryArea: PriorityArea.dolore,
    areas: {PriorityArea.dolore, PriorityArea.movimento},
  ),
  DiagnosisMicroAction(
    id: 'DO_03',
    text: 'Inserisci 5 minuti di camminata lenta prima di aumentare il ritmo.',
    type: DiagnosisMicroActionType.action,
    primaryArea: PriorityArea.dolore,
    areas: {PriorityArea.dolore, PriorityArea.movimento},
  ),
  DiagnosisMicroAction(
    id: 'DO_04',
    text: 'Evita giochi esplosivi con partenze improvvise.',
    type: DiagnosisMicroActionType.avoid,
    primaryArea: PriorityArea.dolore,
    areas: {PriorityArea.dolore, PriorityArea.routineCarico},
  ),
  DiagnosisMicroAction(
    id: 'DO_05',
    text: 'Non saltare la terapia nei giorni in cui sembra stare bene.',
    type: DiagnosisMicroActionType.avoid,
    primaryArea: PriorityArea.dolore,
    areas: {PriorityArea.dolore},
  ),
  DiagnosisMicroAction(
    id: 'DO_06',
    text: 'Dopo una passeggiata lunga, pianifica il giorno dopo piu leggero.',
    type: DiagnosisMicroActionType.action,
    primaryArea: PriorityArea.dolore,
    areas: {PriorityArea.dolore, PriorityArea.routineCarico},
  ),
  DiagnosisMicroAction(
    id: 'DO_07',
    text: 'Evita superfici instabili per i prossimi 10 giorni.',
    type: DiagnosisMicroActionType.avoid,
    primaryArea: PriorityArea.dolore,
    areas: {PriorityArea.dolore, PriorityArea.ambiente},
  ),
  DiagnosisMicroAction(
    id: 'AM_01',
    text: 'Metti tappeti antiscivolo nei due punti piu usati.',
    type: DiagnosisMicroActionType.action,
    primaryArea: PriorityArea.ambiente,
    areas: {PriorityArea.ambiente},
  ),
  DiagnosisMicroAction(
    id: 'AM_02',
    text: 'Blocca le scale non necessarie nelle ore piu attive.',
    type: DiagnosisMicroActionType.action,
    primaryArea: PriorityArea.ambiente,
    areas: {PriorityArea.ambiente},
  ),
  DiagnosisMicroAction(
    id: 'AM_03',
    text: 'Evita salti su e giu da divano o letto.',
    type: DiagnosisMicroActionType.avoid,
    primaryArea: PriorityArea.ambiente,
    areas: {PriorityArea.ambiente, PriorityArea.dolore},
  ),
  DiagnosisMicroAction(
    id: 'AM_04',
    text: 'Usa una rampa per salire in auto.',
    type: DiagnosisMicroActionType.action,
    primaryArea: PriorityArea.ambiente,
    areas: {PriorityArea.ambiente},
  ),
  DiagnosisMicroAction(
    id: 'AM_05',
    text: 'Non farlo camminare su pavimento bagnato o molto liscio.',
    type: DiagnosisMicroActionType.avoid,
    primaryArea: PriorityArea.ambiente,
    areas: {PriorityArea.ambiente},
  ),
  DiagnosisMicroAction(
    id: 'AM_06',
    text: 'Riduci la distanza tra cuccia e ciotola dell\'acqua.',
    type: DiagnosisMicroActionType.action,
    primaryArea: PriorityArea.ambiente,
    areas: {PriorityArea.ambiente},
  ),
  DiagnosisMicroAction(
    id: 'PE_01',
    text: 'Pesa il cibo con bilancia per 7 giorni consecutivi.',
    type: DiagnosisMicroActionType.action,
    primaryArea: PriorityArea.peso,
    areas: {PriorityArea.peso},
  ),
  DiagnosisMicroAction(
    id: 'PE_02',
    text: 'Elimina snack extra non misurati.',
    type: DiagnosisMicroActionType.avoid,
    primaryArea: PriorityArea.peso,
    areas: {PriorityArea.peso},
  ),
  DiagnosisMicroAction(
    id: 'PE_03',
    text: 'Controlla il peso una volta al mese sempre nello stesso giorno.',
    type: DiagnosisMicroActionType.action,
    primaryArea: PriorityArea.peso,
    areas: {PriorityArea.peso},
  ),
  DiagnosisMicroAction(
    id: 'PE_04',
    text: 'Non aumentare la razione nei giorni in cui e piu triste.',
    type: DiagnosisMicroActionType.avoid,
    primaryArea: PriorityArea.peso,
    areas: {PriorityArea.peso},
  ),
  DiagnosisMicroAction(
    id: 'PE_05',
    text: 'Dividi la razione in 2 o 3 pasti per ridurre la fame.',
    type: DiagnosisMicroActionType.action,
    primaryArea: PriorityArea.peso,
    areas: {PriorityArea.peso},
  ),
  DiagnosisMicroAction(
    id: 'MO_01',
    text: 'Cammina ogni giorno con la stessa durata per 10 giorni.',
    type: DiagnosisMicroActionType.action,
    primaryArea: PriorityArea.movimento,
    areas: {PriorityArea.movimento, PriorityArea.routineCarico},
  ),
  DiagnosisMicroAction(
    id: 'MO_02',
    text: 'Evita alternanza 3 giorni fermo e 1 giorno troppo lungo.',
    type: DiagnosisMicroActionType.avoid,
    primaryArea: PriorityArea.movimento,
    areas: {PriorityArea.movimento, PriorityArea.routineCarico},
  ),
  DiagnosisMicroAction(
    id: 'MO_03',
    text: 'Preferisci fondi compatti e regolari.',
    type: DiagnosisMicroActionType.action,
    primaryArea: PriorityArea.movimento,
    areas: {PriorityArea.movimento},
  ),
  DiagnosisMicroAction(
    id: 'MO_04',
    text: 'Inserisci due pause brevi se la passeggiata supera 15 minuti.',
    type: DiagnosisMicroActionType.action,
    primaryArea: PriorityArea.movimento,
    areas: {PriorityArea.movimento},
  ),
  DiagnosisMicroAction(
    id: 'MO_05',
    text: 'Evita salite ripetute quando e presente rigidita.',
    type: DiagnosisMicroActionType.avoid,
    primaryArea: PriorityArea.movimento,
    areas: {PriorityArea.movimento, PriorityArea.dolore},
  ),
  DiagnosisMicroAction(
    id: 'MO_06',
    text: 'Mantieni un ritmo costante senza accelerazioni improvvise.',
    type: DiagnosisMicroActionType.action,
    primaryArea: PriorityArea.movimento,
    areas: {PriorityArea.movimento},
  ),
  DiagnosisMicroAction(
    id: 'RO_01',
    text: 'Programma un calendario settimanale con durata fissa.',
    type: DiagnosisMicroActionType.action,
    primaryArea: PriorityArea.routineCarico,
    areas: {PriorityArea.routineCarico},
  ),
  DiagnosisMicroAction(
    id: 'RO_02',
    text: 'Non decidere la durata della passeggiata a sensazione.',
    type: DiagnosisMicroActionType.avoid,
    primaryArea: PriorityArea.routineCarico,
    areas: {PriorityArea.routineCarico},
  ),
  DiagnosisMicroAction(
    id: 'RO_03',
    text: 'Dopo un weekend attivo, riduci il carico del 30% il lunedi.',
    type: DiagnosisMicroActionType.action,
    primaryArea: PriorityArea.routineCarico,
    areas: {PriorityArea.routineCarico, PriorityArea.dolore},
  ),
  DiagnosisMicroAction(
    id: 'RO_04',
    text: 'Mantieni orari di uscita costanti per tutta la settimana.',
    type: DiagnosisMicroActionType.action,
    primaryArea: PriorityArea.routineCarico,
    areas: {PriorityArea.routineCarico},
  ),
  DiagnosisMicroAction(
    id: 'RO_05',
    text: 'Evita cambi improvvisi di terreno senza adattamento.',
    type: DiagnosisMicroActionType.avoid,
    primaryArea: PriorityArea.routineCarico,
    areas: {PriorityArea.routineCarico, PriorityArea.movimento},
  ),
  DiagnosisMicroAction(
    id: 'RO_06',
    text:
        'Dopo una giornata intensa, il giorno seguente fai solo uscita breve.',
    type: DiagnosisMicroActionType.action,
    primaryArea: PriorityArea.routineCarico,
    areas: {PriorityArea.routineCarico},
  ),
  DiagnosisMicroAction(
    id: 'RO_07',
    text: 'Non introdurre esercizi nuovi quando la rigidita aumenta.',
    type: DiagnosisMicroActionType.avoid,
    primaryArea: PriorityArea.routineCarico,
    areas: {PriorityArea.routineCarico, PriorityArea.dolore},
  ),
];
