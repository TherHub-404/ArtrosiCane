import 'package:artrosi_cane/features/daily_check/data/daily_check_repository.dart';
import 'package:artrosi_cane/features/daily_check/domain/entities/daily_check_models.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

const Color _verde = Color(0xFF3FAE6A);
const Color _giallo = Color(0xFFE6B655);
const Color _rosso = Color(0xFFD0524C);

class DailyCheckHistoryScreen extends ConsumerStatefulWidget {
  const DailyCheckHistoryScreen({
    super.key,
    required this.dogId,
    required this.dogName,
  });

  final String dogId;
  final String dogName;

  @override
  ConsumerState<DailyCheckHistoryScreen> createState() =>
      _DailyCheckHistoryScreenState();
}

class _DailyCheckHistoryScreenState
    extends ConsumerState<DailyCheckHistoryScreen> {
  late Future<List<DailyLogEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<DailyLogEntry>> _load() {
    return ref
        .read(dailyCheckRepositoryProvider)
        .fetchHistory(dogId: widget.dogId);
  }

  Future<void> _refresh() async {
    final entries = await _load();
    if (!mounted) return;
    setState(() {
      _future = Future.value(entries);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: ClipPath(
          clipper: _AppBarWaveClipper(),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.ctaApricot, Color(0xFFFFCC80)],
              ),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 80,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.primaryBlue,
                  size: 28,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: Text(
                l10n.text('Diario di {{dogName}}', {'dogName': widget.dogName}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: _refresh,
        child: FutureBuilder<List<DailyLogEntry>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                padding: EdgeInsets.only(top: topInset + 110 + AppSpacing.lg),
                children: const [
                  SizedBox(height: 80),
                  Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              );
            }
            if (snapshot.hasError) {
              return _ErrorView(onRetry: _refresh, error: snapshot.error);
            }
            final entries = snapshot.data ?? const <DailyLogEntry>[];
            if (entries.isEmpty) {
              return _EmptyView(dogName: widget.dogName, topInset: topInset);
            }
            return _HistoryContent(
              entries: entries,
              dogName: widget.dogName,
              topInset: topInset,
            );
          },
        ),
      ),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({
    required this.entries,
    required this.dogName,
    required this.topInset,
  });

  final List<DailyLogEntry> entries;
  final String dogName;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groups = _groupByMonth(entries);
    final stats = _computeStats(entries);

    return ListView(
      padding: EdgeInsets.only(
        top: topInset + 110 + AppSpacing.md,
        bottom: AppSpacing.xl,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _ChartCard(entries: entries, stats: stats),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              const Icon(
                Icons.history_rounded,
                size: 18,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.text('Tutti i tuoi check'),
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryBlue,
                ),
              ),
              const Spacer(),
              Text(
                l10n.text('{{n}} totali', {'n': entries.length.toString()}),
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final group in groups) ...[
          _MonthHeader(label: group.label),
          for (final entry in group.entries)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: _DayCard(
                entry: entry,
                onTap: () => _openDetail(context, entry, dogName),
              ),
            ),
        ],
      ],
    );
  }

  void _openDetail(BuildContext context, DailyLogEntry entry, String dogName) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _DetailSheet(entry: entry, dogName: dogName),
    );
  }

  List<_MonthGroup> _groupByMonth(List<DailyLogEntry> entries) {
    final l10n = AppLocalizations.current;
    final lang = l10n.locale.languageCode;
    final out = <_MonthGroup>[];
    String? currentKey;
    List<DailyLogEntry> bucket = [];
    String? currentLabel;
    for (final e in entries) {
      final key = '${e.createdAt.year}-${e.createdAt.month}';
      if (key != currentKey) {
        if (bucket.isNotEmpty && currentLabel != null) {
          out.add(_MonthGroup(label: currentLabel, entries: bucket));
        }
        bucket = [];
        currentKey = key;
        final month = DateFormat.yMMMM(lang).format(e.createdAt);
        currentLabel = month.isEmpty
            ? key
            : month[0].toUpperCase() + month.substring(1);
      }
      bucket.add(e);
    }
    if (bucket.isNotEmpty && currentLabel != null) {
      out.add(_MonthGroup(label: currentLabel, entries: bucket));
    }
    return out;
  }

  _HistoryStats _computeStats(List<DailyLogEntry> entries) {
    if (entries.isEmpty) return const _HistoryStats(0, 0, 0, 0);
    int verde = 0, giallo = 0, rosso = 0;
    for (final e in entries) {
      switch (e.semaphore) {
        case DailySemaphore.verde:
          verde++;
          break;
        case DailySemaphore.giallo:
          giallo++;
          break;
        case DailySemaphore.rosso:
          rosso++;
          break;
      }
    }
    return _HistoryStats(entries.length, verde, giallo, rosso);
  }
}

class _MonthGroup {
  const _MonthGroup({required this.label, required this.entries});
  final String label;
  final List<DailyLogEntry> entries;
}

class _HistoryStats {
  const _HistoryStats(this.total, this.verde, this.giallo, this.rosso);
  final int total;
  final int verde;
  final int giallo;
  final int rosso;
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: AppColors.text.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.entry, required this.onTap});

  final DailyLogEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = _semaphoreColor(entry.semaphore);
    final lang = l10n.locale.languageCode;
    final dayLabel = DateFormat.EEEE(lang).format(entry.createdAt);
    final dateLabel = DateFormat('d MMM', lang).format(entry.createdAt);
    final timeLabel = DateFormat.Hm(lang).format(entry.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: color.withValues(alpha: 0.18), width: 1),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${dayLabel[0].toUpperCase()}${dayLabel.substring(1)} '
                      '· $dateLabel',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.text('Score {{score}} · {{time}}', {
                        'score': entry.score.toString(),
                        'time': timeLabel,
                      }),
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        color: AppColors.text.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
              _SemaphoreChip(semaphore: entry.semaphore),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primaryBlue.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SemaphoreChip extends StatelessWidget {
  const _SemaphoreChip({required this.semaphore});
  final DailySemaphore semaphore;

  @override
  Widget build(BuildContext context) {
    final color = _semaphoreColor(semaphore);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _semaphoreLabel(context, semaphore),
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w800,
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.entries, required this.stats});

  final List<DailyLogEntry> entries;
  final _HistoryStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final last30 = _aggregateLastDays(entries, 30);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.show_chart_rounded,
                size: 18,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.text('Andamento ultimi 30 giorni'),
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.text(
              'Ogni barra è un giorno: il colore mostra il semaforo, l\'altezza lo score.',
            ),
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              color: AppColors.text.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 130,
            child: CustomPaint(
              painter: _BarChartPainter(buckets: last30),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LegendDot(color: _verde, label: l10n.text('Verde')),
              _LegendDot(color: _giallo, label: l10n.text('Giallo')),
              _LegendDot(color: _rosso, label: l10n.text('Rosso')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _StatItem(
                  value: stats.verde,
                  label: l10n.text('Verde'),
                  color: _verde,
                ),
                Container(width: 1, height: 28, color: AppColors.borderSoft),
                _StatItem(
                  value: stats.giallo,
                  label: l10n.text('Giallo'),
                  color: _giallo,
                ),
                Container(width: 1, height: 28, color: AppColors.borderSoft),
                _StatItem(
                  value: stats.rosso,
                  label: l10n.text('Rosso'),
                  color: _rosso,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.text.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.text.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({required this.buckets});

  /// 30 buckets, oldest → newest. null = no check that day.
  final List<DailyLogEntry?> buckets;

  @override
  void paint(Canvas canvas, Size size) {
    final n = buckets.length;
    if (n == 0) return;
    const minScore = 0;
    const maxScore = 10;
    const paddingTop = 8.0;
    const paddingBottom = 18.0;
    final usableHeight = size.height - paddingTop - paddingBottom;
    final slotWidth = size.width / n;
    final barWidth = slotWidth * 0.55;

    // Baseline
    final baselinePaint = Paint()
      ..color = AppColors.borderSoft
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - paddingBottom),
      Offset(size.width, size.height - paddingBottom),
      baselinePaint,
    );

    for (int i = 0; i < n; i++) {
      final entry = buckets[i];
      final centerX = slotWidth * (i + 0.5);

      if (entry == null) {
        final empty = Paint()
          ..color = AppColors.borderSoft.withValues(alpha: 0.6);
        canvas.drawCircle(
          Offset(centerX, size.height - paddingBottom - 1),
          1.6,
          empty,
        );
        continue;
      }

      final clampedScore = entry.score.clamp(minScore, maxScore);
      final ratio = maxScore == 0 ? 0.0 : clampedScore / maxScore;
      // Minimum visible bar so very-low scores still show up
      final h = (usableHeight * ratio).clamp(8.0, usableHeight);
      final color = _semaphoreColor(entry.semaphore);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - barWidth / 2,
          size.height - paddingBottom - h,
          barWidth,
          h,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(rrect, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.buckets != buckets;
}

List<DailyLogEntry?> _aggregateLastDays(List<DailyLogEntry> entries, int days) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Right edge = max(today, latest entry day) so timezone drift or future
  // timestamps (e.g. naive-UTC writes) are still rendered.
  DateTime endDay = today;
  for (final e in entries) {
    final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
    if (d.isAfter(endDay)) endDay = d;
  }
  final start = endDay.subtract(Duration(days: days - 1));

  // Bucket entries by day. Keep the WORST check of the day (rosso > giallo
  // > verde, then highest score) so critical days are never hidden by a
  // later "good" check.
  final byDay = <String, DailyLogEntry>{};
  for (final e in entries) {
    final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
    if (d.isBefore(start) || d.isAfter(endDay)) continue;
    final key = '${d.year}-${d.month}-${d.day}';
    final existing = byDay[key];
    if (existing == null || _isWorse(e, existing)) {
      byDay[key] = e;
    }
  }
  final out = <DailyLogEntry?>[];
  for (int i = 0; i < days; i++) {
    final d = start.add(Duration(days: i));
    final key = '${d.year}-${d.month}-${d.day}';
    out.add(byDay[key]);
  }
  return out;
}

/// Returns true if [a] is worse than [b] (more severe semaphore, then
/// higher score as a tiebreaker).
bool _isWorse(DailyLogEntry a, DailyLogEntry b) {
  final sa = a.semaphore.index; // verde=0, giallo=1, rosso=2
  final sb = b.semaphore.index;
  if (sa != sb) return sa > sb;
  return a.score > b.score;
}

Color _semaphoreColor(DailySemaphore s) {
  switch (s) {
    case DailySemaphore.verde:
      return _verde;
    case DailySemaphore.giallo:
      return _giallo;
    case DailySemaphore.rosso:
      return _rosso;
  }
}

String _semaphoreLabel(BuildContext context, DailySemaphore s) {
  switch (s) {
    case DailySemaphore.verde:
      return context.l10n.text('Verde');
    case DailySemaphore.giallo:
      return context.l10n.text('Giallo');
    case DailySemaphore.rosso:
      return context.l10n.text('Rosso');
  }
}

String _semaphoreNarrative(BuildContext context, DailySemaphore s) {
  switch (s) {
    case DailySemaphore.verde:
      return context.l10n.text('Buona giornata, attività regolare.');
    case DailySemaphore.giallo:
      return context.l10n.text('Da osservare, gestisci con cautela.');
    case DailySemaphore.rosso:
      return context.l10n.text('Giornata di protezione, riduci i carichi.');
  }
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.entry, required this.dogName});

  final DailyLogEntry entry;
  final String dogName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = l10n.locale.languageCode;
    final color = _semaphoreColor(entry.semaphore);
    final dateLabel = DateFormat('EEEE d MMMM', lang).format(entry.createdAt);
    final timeLabel = DateFormat.Hm(lang).format(entry.createdAt);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSoft,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withValues(alpha: 0.78)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _semaphoreLabel(context, entry.semaphore).toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _semaphoreNarrative(context, entry.semaphore),
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.text('{{dog}} · score {{score}}', {
                      'dog': dogName,
                      'score': entry.score.toString(),
                    }),
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '${dateLabel[0].toUpperCase()}${dateLabel.substring(1)} · $timeLabel',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.text.withValues(alpha: 0.62),
              ),
            ),
            if (entry.actions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _DetailSection(
                icon: Icons.check_circle_outline_rounded,
                title: l10n.text('Azioni consigliate'),
                color: AppColors.primaryBlue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final a in entry.actions)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _BulletText(text: a),
                      ),
                  ],
                ),
              ),
            ],
            if (entry.avoid.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _DetailSection(
                icon: Icons.do_not_disturb_alt_rounded,
                title: l10n.text('Da evitare'),
                color: AppColors.ctaApricot,
                child: _BulletText(text: entry.avoid),
              ),
            ],
            if (entry.videoLabel.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _DetailSection(
                icon: Icons.play_circle_outline_rounded,
                title: l10n.text('Video consigliato'),
                color: AppColors.primaryBlue,
                child: Text(
                  entry.videoLabel,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13.5,
                    color: AppColors.text.withValues(alpha: 0.78),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 8),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.ctaApricot,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13.5,
              color: AppColors.text.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.dogName, required this.topInset});
  final String dogName;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topInset + 110 + AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.beigeAccent,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            size: 40,
            color: AppColors.ctaApricot,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.text('Il diario di {{dogName}} è ancora vuoto', {
            'dogName': dogName,
          }),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.text(
            'Rispondi a "Come stai oggi?" ogni giorno: qui troverai semafori, score e consigli per ricostruire la sua storia.',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            height: 1.5,
            color: AppColors.text.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry, this.error});
  final VoidCallback onRetry;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: AppColors.text.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.text('Impossibile caricare il diario.'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: TextButton(
            onPressed: onRetry,
            child: Text(l10n.text('Riprova')),
          ),
        ),
      ],
    );
  }
}

class _AppBarWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 24);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height,
      size.width,
      size.height - 24,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
