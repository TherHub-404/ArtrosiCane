import 'package:artrosi_cane/features/quiz/domain/entities/diagnosis_priority_models.dart';

class DiagnosisPriorityResultModel {
  factory DiagnosisPriorityResultModel.fromEntity(
    DiagnosisPriorityResult entity,
  ) {
    return DiagnosisPriorityResultModel(
      areas: entity.areas,
      orderedAreas: entity.orderedAreas,
      shownHighAreas: entity.shownHighAreas,
      compressedFromHigh: entity.compressedFromHigh,
      safetyRuleApplied: entity.safetyRuleApplied,
      totalScore: entity.totalScore,
    );
  }

  factory DiagnosisPriorityResultModel.fromJson(Map<String, dynamic> json) {
    final rawAreas = json['areas'] as Map<String, dynamic>? ?? const {};
    final parsedAreas = <PriorityArea, AreaPriority>{};

    for (final area in PriorityArea.values) {
      final raw = rawAreas[area.name] as Map<String, dynamic>?;
      if (raw == null) {
        parsedAreas[area] = AreaPriority(
          area: area,
          score: 0,
          level: PriorityLevel.bassa,
        );
        continue;
      }

      final rawLevel = raw['level'] as String?;
      final level = PriorityLevel.values.firstWhere(
        (item) => item.name == rawLevel,
        orElse: () => PriorityLevel.bassa,
      );

      parsedAreas[area] = AreaPriority(
        area: area,
        score: (raw['score'] as num?)?.toInt() ?? 0,
        level: level,
        compressedFromHigh: raw['compressedFromHigh'] as bool? ?? false,
      );
    }

    List<PriorityArea> parseAreaList(String key) {
      final raw = (json[key] as List<dynamic>? ?? const []).map((e) => '$e');
      return raw
          .map(
            (name) => PriorityArea.values.firstWhere(
              (item) => item.name == name,
              orElse: () => PriorityArea.dolore,
            ),
          )
          .toList();
    }

    return DiagnosisPriorityResultModel(
      areas: parsedAreas,
      orderedAreas: parseAreaList('orderedAreas'),
      shownHighAreas: parseAreaList('shownHighAreas'),
      compressedFromHigh: parseAreaList('compressedFromHigh'),
      safetyRuleApplied: json['safetyRuleApplied'] as bool? ?? false,
      totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
    );
  }
  const DiagnosisPriorityResultModel({
    required this.areas,
    required this.orderedAreas,
    required this.shownHighAreas,
    required this.compressedFromHigh,
    required this.safetyRuleApplied,
    required this.totalScore,
  });

  final Map<PriorityArea, AreaPriority> areas;
  final List<PriorityArea> orderedAreas;
  final List<PriorityArea> shownHighAreas;
  final List<PriorityArea> compressedFromHigh;
  final bool safetyRuleApplied;
  final int totalScore;

  DiagnosisPriorityResult toEntity() {
    return DiagnosisPriorityResult(
      areas: areas,
      orderedAreas: orderedAreas,
      shownHighAreas: shownHighAreas,
      compressedFromHigh: compressedFromHigh,
      safetyRuleApplied: safetyRuleApplied,
      totalScore: totalScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'areas': {
        for (final entry in areas.entries)
          entry.key.name: {
            'score': entry.value.score,
            'level': entry.value.level.name,
            'compressedFromHigh': entry.value.compressedFromHigh,
          },
      },
      'orderedAreas': orderedAreas.map((a) => a.name).toList(),
      'shownHighAreas': shownHighAreas.map((a) => a.name).toList(),
      'compressedFromHigh': compressedFromHigh.map((a) => a.name).toList(),
      'safetyRuleApplied': safetyRuleApplied,
      'totalScore': totalScore,
    };
  }
}
