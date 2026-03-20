import 'package:artrosi_cane/core/providers/preferences_data_source_provider.dart';
import 'package:artrosi_cane/core/widgets/app_scaffold.dart';
import 'package:artrosi_cane/core/widgets/non_medical_disclaimer.dart';
import 'package:artrosi_cane/features/quiz/data/datasources/quiz_remote_data_source.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/diagnosis_micro_action_models.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/diagnosis_priority_models.dart';
import 'package:artrosi_cane/features/quiz/domain/services/diagnosis_micro_action_engine.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DiagnosisPriorityResultScreen extends ConsumerStatefulWidget {
  const DiagnosisPriorityResultScreen({super.key, required this.result});

  final DiagnosisPriorityResult result;

  @override
  ConsumerState<DiagnosisPriorityResultScreen> createState() =>
      _DiagnosisPriorityResultScreenState();
}

class _DiagnosisPriorityResultScreenState
    extends ConsumerState<DiagnosisPriorityResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackEvent(
        'diagnosis_result_viewed',
        payload: {
          'totalScore': widget.result.totalScore,
          'shownHighAreas': widget.result.shownHighAreas
              .map((area) => area.name)
              .toList(),
        },
      );
    });
  }

  Future<void> _trackEvent(
    String eventName, {
    Map<String, dynamic> payload = const {},
  }) async {
    try {
      await ref
          .read(preferencesDataSourceProvider)
          .appendOnboardingEvent(eventName: eventName, payload: payload);
    } catch (_) {
      // Ignore local telemetry errors.
    }

    await ref
        .read(quizRemoteDataSourceProvider)
        .saveOnboardingEvent(eventName: eventName, payload: payload);
  }

  Future<void> _openAuthWithContext(String entryContext) async {
    await _trackEvent(
      'diagnosis_result_cta_click',
      payload: {'entryContext': entryContext},
    );
    if (!mounted) return;
    context.go(
      '/auth',
      extra: {'entryContext': entryContext, 'source': 'diagnosis_result'},
    );
  }

  @override
  Widget build(BuildContext context) {
    const microActionEngine = DiagnosisMicroActionEngine();
    final microPlan = microActionEngine.buildPlan(widget.result);
    return AppScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La tua Mappa Priorita',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ecco cosa sta influenzando di piu il suo benessere oggi.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.text.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...widget.result.orderedAreas.map((area) {
              final item = widget.result.area(area);
              return _PriorityTile(item: item);
            }),
            if (widget.result.compressedFromHigh.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Ci lavoriamo dopo le priorita principali.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.text.withValues(alpha: 0.75),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.ctaApricot.withValues(alpha: 0.35),
                ),
              ),
              child: const Text(
                'Non serve fare tutto. Serve intervenire nell\'ordine giusto.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Micro-azioni consigliate',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Focus: ${microPlan.focusAreas.map(priorityAreaLabel).join(' + ')}',
                    style: TextStyle(
                      color: AppColors.text.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...microPlan.items.map(_MicroActionTile.new),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const NonMedicalDisclaimer(),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _openAuthWithContext('videocall'),
                child: const Text('Prenota videocall iniziale'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openAuthWithContext('percorso_annuale'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ctaApricot,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Inizia il Percorso Annuale'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _openAuthWithContext('autonomia'),
                child: const Text('Continua in autonomia'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityTile extends StatelessWidget {
  const _PriorityTile({required this.item});

  final AreaPriority item;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.level) {
      PriorityLevel.alta => const Color(0xFFD64545),
      PriorityLevel.media => const Color(0xFFF2A93B),
      PriorityLevel.bassa => const Color(0xFF2E9D65),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              priorityAreaLabel(item.area),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '${priorityLevelLabel(item.level)} (${item.score})',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MicroActionTile extends StatelessWidget {
  const _MicroActionTile(this.item);

  final DiagnosisMicroAction item;

  @override
  Widget build(BuildContext context) {
    final isAction = item.type == DiagnosisMicroActionType.action;
    final accent = isAction ? const Color(0xFF2E9D65) : const Color(0xFFD64545);
    final icon = isAction ? Icons.check_circle_outline : Icons.block;
    final prefix = isAction ? 'Azione' : 'Evita';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '$prefix · ${priorityAreaLabel(item.primaryArea)}\n${item.text}',
                style: const TextStyle(
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
