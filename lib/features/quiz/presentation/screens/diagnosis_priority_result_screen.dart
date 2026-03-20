import 'package:artrosi_cane/core/widgets/app_scaffold.dart';
import 'package:artrosi_cane/core/widgets/non_medical_disclaimer.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/diagnosis_micro_action_models.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/diagnosis_priority_models.dart';
import 'package:artrosi_cane/features/quiz/domain/services/diagnosis_micro_action_engine.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DiagnosisPriorityResultScreen extends StatelessWidget {
  const DiagnosisPriorityResultScreen({super.key, required this.result});

  final DiagnosisPriorityResult result;

  @override
  Widget build(BuildContext context) {
    const microActionEngine = DiagnosisMicroActionEngine();
    final microPlan = microActionEngine.buildPlan(result);
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
            ...result.orderedAreas.map((area) {
              final item = result.area(area);
              return _PriorityTile(item: item);
            }),
            if (result.compressedFromHigh.isNotEmpty) ...[
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Videocall: funzione in arrivo.'),
                    ),
                  );
                },
                child: const Text('Prenota videocall iniziale'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/auth'),
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
                onPressed: () => context.go('/auth'),
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
