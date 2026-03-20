import 'package:artrosi_cane/features/quiz/domain/entities/diagnosis_priority_models.dart';

enum DiagnosisMicroActionType { action, avoid }

class DiagnosisMicroAction {
  const DiagnosisMicroAction({
    required this.id,
    required this.text,
    required this.type,
    required this.primaryArea,
    required this.areas,
  });

  final String id;
  final String text;
  final DiagnosisMicroActionType type;
  final PriorityArea primaryArea;
  final Set<PriorityArea> areas;
}

class DiagnosisMicroActionPlan {
  const DiagnosisMicroActionPlan({
    required this.focusAreas,
    required this.items,
  });

  final List<PriorityArea> focusAreas;
  final List<DiagnosisMicroAction> items;
}
