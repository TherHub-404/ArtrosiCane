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
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DiagnosisPriorityResultScreen extends ConsumerStatefulWidget {
  const DiagnosisPriorityResultScreen({
    super.key,
    this.result,
    this.dogData,
    this.showJourneyOnly = false,
  });

  final DiagnosisPriorityResult? result;
  final Map<String, dynamic>? dogData;
  final bool showJourneyOnly;

  @override
  ConsumerState<DiagnosisPriorityResultScreen> createState() =>
      _DiagnosisPriorityResultScreenState();
}

class _DiagnosisPriorityResultScreenState
    extends ConsumerState<DiagnosisPriorityResultScreen> {
  static const String _annualJourneyUrl =
      'https://artrosicane.com/custom_paths';

  @override
  void initState() {
    super.initState();
    if (widget.showJourneyOnly || widget.result == null) {
      return;
    }
    final result = widget.result!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackEvent(
        'diagnosis_result_viewed',
        payload: {
          'totalScore': result.totalScore,
          'shownHighAreas': result.shownHighAreas
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
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      if (widget.dogData != null) {
        context.go('/dog-dashboard', extra: widget.dogData);
      } else {
        context.go('/home');
      }
      return;
    }
    context.go(
      '/auth',
      extra: {
        'entryContext': entryContext,
        'source': 'diagnosis_result',
        'dog': widget.dogData,
      },
    );
  }

  Future<void> _openVideoCallRequest() async {
    await _trackEvent(
      'diagnosis_result_cta_click',
      payload: {'entryContext': 'videocall_form'},
    );
    if (!mounted) return;
    context.go('/videocall-request', extra: {'dog': widget.dogData});
  }

  Future<void> _openAnnualPlanOptions() async {
    await _trackEvent(
      'diagnosis_result_cta_click',
      payload: {'entryContext': 'percorso_annuale'},
    );
    if (!mounted) return;
    await _openAnnualJourneyUrl();
  }

  Future<void> _openAnnualJourneyUrl() async {
    final uri = Uri.parse(_annualJourneyUrl);
    var opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!opened) {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (!opened && mounted) {
      _showSnackBar('Impossibile aprire il link del Percorso Annuale.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final hasDetailedPlan = !widget.showJourneyOnly && widget.result != null;
    const microActionEngine = DiagnosisMicroActionEngine();
    final viewportHeight = MediaQuery.of(context).size.height;
    final sectionMinHeight = (viewportHeight * 0.88).clamp(520.0, 820.0);

    if (!hasDetailedPlan) {
      return AppScaffold(
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildJourneySection(
              sectionMinHeight: sectionMinHeight,
              standalone: true,
            ),
          ],
        ),
      );
    }

    final result = widget.result!;
    final microPlan = microActionEngine.buildPlan(result);
    final orderedPriorities = result.orderedAreas.map(result.area).toList();
    final firstSectionHeight = (viewportHeight * 0.92).clamp(540.0, 860.0);

    return AppScaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: firstSectionHeight,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF4F8FF), Colors.white],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'La tua Mappa Priorita',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryBlue,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Ecco le aree che oggi influenzano di piu il benessere del tuo cane.',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.text.withValues(alpha: 0.82),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Column(
                    children: orderedPriorities.indexed.map((entry) {
                      final (index, item) = entry;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == orderedPriorities.length - 1
                              ? 0
                              : AppSpacing.sm,
                        ),
                        child: _PriorityBadge(item: item),
                      );
                    }).toList(),
                  ),
                  if (result.compressedFromHigh.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Le altre aree le affrontiamo nel secondo step.',
                      style: TextStyle(
                        color: AppColors.text.withValues(alpha: 0.68),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const Spacer(),
                  const Center(
                    child: _DownScrollHint(
                      label: 'Scorri verso le microazioni',
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              height: sectionMinHeight,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Microazioni',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ctaApricot,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Scorri orizzontalmente e applica una microazione per volta.',
                    style: TextStyle(
                      fontSize: 17,
                      color: AppColors.text.withValues(alpha: 0.8),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.ctaApricot.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      'Focus: ${microPlan.focusAreas.map(priorityAreaLabel).join(' + ')}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 252,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: microPlan.items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, index) {
                        return _MicroActionCarouselCard(
                          item: microPlan.items[index],
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                  const Center(
                    child: _DownScrollHint(
                      label: 'Scendi verso i prossimi passi',
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildJourneySection(sectionMinHeight: sectionMinHeight),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildJourneySection({
    required double sectionMinHeight,
    bool standalone = false,
  }) {
    return SliverToBoxAdapter(
      child: Container(
        constraints: BoxConstraints(minHeight: sectionMinHeight),
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          standalone ? AppSpacing.xl + AppSpacing.sm : AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.03),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scegli il tuo prossimo passo',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _JourneyCard(
              icon: Icons.videocam_rounded,
              title: 'Prenota video Call',
              description:
                  'Un confronto iniziale con supporto guidato sulle priorita emerse.',
              accent: const Color(0xFF4A84F4),
              onTap: _openVideoCallRequest,
            ),
            const SizedBox(height: AppSpacing.md),
            _JourneyCard(
              icon: Icons.calendar_month_rounded,
              title: 'Scegli il piano più adatto a te',
              description:
                  'Confronta le opzioni disponibili e scegli quella migliore al checkout.',
              accent: AppColors.ctaApricot,
              onTap: _openAnnualPlanOptions,
            ),
            const SizedBox(height: AppSpacing.md),
            _JourneyCard(
              icon: Icons.directions_walk_rounded,
              title: 'Continua in autonomia',
              description:
                  'Prosegui in autonomia con consigli pratici e progressivi.',
              accent: const Color(0xFF2E9D65),
              onTap: () => _openAuthWithContext('autonomia'),
            ),
            const SizedBox(height: AppSpacing.lg),
            const NonMedicalDisclaimer(),
          ],
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.item});

  final AreaPriority item;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.level) {
      PriorityLevel.alta => const Color(0xFFD64545),
      PriorityLevel.media => const Color(0xFFF2A93B),
      PriorityLevel.bassa => const Color(0xFF2E9D65),
    };

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  priorityAreaLabel(item.area),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                priorityLevelLabel(item.level),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownScrollHint extends StatelessWidget {
  const _DownScrollHint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.text.withValues(alpha: 0.62),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 34,
          color: AppColors.primaryBlue.withValues(alpha: 0.72),
        ),
      ],
    );
  }
}

class _MicroActionCarouselCard extends StatelessWidget {
  const _MicroActionCarouselCard({required this.item});

  final DiagnosisMicroAction item;

  @override
  Widget build(BuildContext context) {
    final isAction = item.type == DiagnosisMicroActionType.action;
    final accent = isAction ? const Color(0xFF2E9D65) : const Color(0xFFD64545);
    final icon = isAction ? Icons.check_circle_rounded : Icons.block_rounded;
    final prefix = isAction ? 'Azione' : 'Evita';

    return Container(
      width: 300,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: accent, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '$prefix · ${priorityAreaLabel(item.primaryArea)}',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Text(
              item.text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.22,
                color: AppColors.text,
              ),
            ),
          ),
          Text(
            'Micro-passaggio pratico da applicare oggi.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.text.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: accent),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.text.withValues(alpha: 0.78),
                height: 1.32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
