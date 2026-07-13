import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:artrosi_cane/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Clean, light AppBar shared by the Walks and Exercise advice screens.
PreferredSizeWidget adviceAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: AppColors.background,
    surfaceTintColor: AppColors.background,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleSpacing: 0,
    foregroundColor: AppColors.primaryBlue,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
      color: AppColors.primaryBlue,
      onPressed: () => context.pop(),
    ),
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.bodyBold.copyWith(
        color: AppColors.primaryBlue,
        fontSize: 18,
      ),
    ),
  );
}

/// White rounded surface used by every advice section.
class AdviceCard extends StatelessWidget {
  const AdviceCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Soft, rounded-square icon badge.
class AdviceIconBadge extends StatelessWidget {
  const AdviceIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 46,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Top summary card: severity icon, title, a metric pill and the objective.
class AdviceSummaryCard extends StatelessWidget {
  const AdviceSummaryCard({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.metricIcon,
    required this.metricLabel,
    required this.metricValue,
    required this.objectiveLabel,
    required this.objectiveText,
    required this.extraPoints,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final IconData metricIcon;
  final String metricLabel;
  final String metricValue;
  final String objectiveLabel;
  final String objectiveText;
  final List<String> extraPoints;

  @override
  Widget build(BuildContext context) {
    final trimmedMetric = metricValue.trim();
    final hasMetric = trimmedMetric.isNotEmpty && trimmedMetric != '-';

    return AdviceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdviceIconBadge(icon: icon, color: accentColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.primaryBlue,
                    fontSize: 18,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          if (hasMetric) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(metricIcon, color: accentColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    metricLabel,
                    style: AppTypography.body.copyWith(
                      color: AppColors.text.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    trimmedMetric,
                    style: AppTypography.bodyBold.copyWith(
                      color: accentColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (objectiveText.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              objectiveLabel.toUpperCase(),
              style: AppTypography.bodyBold.copyWith(
                color: accentColor,
                fontSize: 12,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              objectiveText,
              style: AppTypography.body.copyWith(
                color: AppColors.text,
                height: 1.4,
              ),
            ),
          ],
          ...extraPoints.map(
            (point) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      point,
                      style: AppTypography.body.copyWith(
                        color: AppColors.text,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card listing advice items, each preceded by a small badge icon.
class AdviceListCard extends StatelessWidget {
  const AdviceListCard({
    super.key,
    required this.headerIcon,
    required this.accentColor,
    required this.title,
    required this.bulletIcon,
    required this.items,
  });

  final IconData headerIcon;
  final Color accentColor;
  final String title;
  final IconData bulletIcon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return AdviceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdviceIconBadge(icon: headerIcon, color: accentColor, size: 40),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.primaryBlue,
                    fontSize: 16,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(bulletIcon, color: accentColor, size: 15),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        items[i],
                        style: AppTypography.body.copyWith(
                          color: AppColors.text,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Collapsible "notes" card.
class AdviceNotesCard extends StatefulWidget {
  const AdviceNotesCard({super.key, required this.title, required this.note});

  final String title;
  final String note;

  @override
  State<AdviceNotesCard> createState() => _AdviceNotesCardState();
}

class _AdviceNotesCardState extends State<AdviceNotesCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return AdviceCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: Semantics(
              button: true,
              expanded: _open,
              label: widget.title,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      const AdviceIconBadge(
                        icon: Icons.sticky_note_2_rounded,
                        color: AppColors.primaryBlue,
                        size: 40,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: AppTypography.bodyBold.copyWith(
                                color: AppColors.primaryBlue,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _open
                                  ? context.l10n.text('Tocca per chiudere')
                                  : context.l10n.text('Tocca per leggere'),
                              style: AppTypography.body.copyWith(
                                color: AppColors.text.withValues(alpha: 0.55),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: const Icon(
                          Icons.expand_more_rounded,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: _open
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Divider(
                        height: 1,
                        color: AppColors.primaryBlue.withValues(alpha: 0.10),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        child: Text(
                          widget.note,
                          style: AppTypography.body.copyWith(
                            color: AppColors.text.withValues(alpha: 0.8),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
