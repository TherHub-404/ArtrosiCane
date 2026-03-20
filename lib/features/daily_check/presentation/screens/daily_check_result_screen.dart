import 'package:artrosi_cane/core/widgets/non_medical_disclaimer.dart';
import 'package:artrosi_cane/features/daily_check/domain/entities/daily_check_models.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class DailyCheckResultScreen extends StatelessWidget {
  const DailyCheckResultScreen({
    super.key,
    required this.result,
    required this.dogName,
  });

  final DailyCheckResult result;
  final String dogName;

  @override
  Widget build(BuildContext context) {
    final palette = _palette(result.semaphore);
    final isBibbioneRoute =
        result.recommendation.routeTag == 'bibbione' ||
        result.recommendation.routeTag == 'bibione';
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primaryBlue,
        title: const Text(
          'Semaforo Giornata',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: palette),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: palette.first.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _semaphoreLabel(result.semaphore),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    result.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.08,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.subtitle,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$dogName · Score ${result.score} (raw ${result.rawScore})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _resultCard(
              title: '2 micro-azioni',
              icon: Icons.check_circle_outline_rounded,
              children: result.recommendation.actions
                  .map((text) => _bullet(text))
                  .toList(),
            ),
            const SizedBox(height: 10),
            _resultCard(
              title: '1 cosa da evitare',
              icon: Icons.remove_circle_outline_rounded,
              children: [_bullet(result.recommendation.avoid)],
            ),
            const SizedBox(height: 10),
            _resultCard(
              title: 'Percorso consigliato',
              icon: Icons.map_outlined,
              children: [
                _bullet(
                  isBibbioneRoute
                      ? 'Percorso Bibione consigliato oggi.'
                      : 'Percorso standard consigliato oggi.',
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    if (isBibbioneRoute) {
                      context.push('/walks-overview');
                    } else {
                      context.push(
                        '/walks',
                        extra: {'grade': '', 'name': dogName},
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: BorderSide(
                      color: AppColors.primaryBlue.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Text('Apri percorso'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _resultCard(
              title: 'Esercizio video (20–40 sec)',
              icon: Icons.play_circle_outline_rounded,
              children: [
                _bullet(result.recommendation.videoLabel),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    final uri = Uri.parse(result.recommendation.videoUrl);
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: BorderSide(
                      color: AppColors.primaryBlue.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Text('Apri video'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                ),
              ),
              child: const Text(
                'Domani bastano 20 secondi: l’app capisce il recupero del tuo cane.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const NonMedicalDisclaimer(),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stato di oggi salvato.')),
                  );
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ctaApricot,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text(
                  'Salva stato di oggi',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: AppColors.ctaApricot),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.3,
                color: Color(0xFF233250),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _palette(DailySemaphore semaphore) {
    switch (semaphore) {
      case DailySemaphore.verde:
        return const [Color(0xFF22A06B), Color(0xFF3DBE85)];
      case DailySemaphore.giallo:
        return const [Color(0xFFF2A93B), Color(0xFFF7BE5E)];
      case DailySemaphore.rosso:
        return const [Color(0xFFD64545), Color(0xFFE76868)];
    }
  }

  String _semaphoreLabel(DailySemaphore semaphore) {
    switch (semaphore) {
      case DailySemaphore.verde:
        return 'SEMAFORO VERDE';
      case DailySemaphore.giallo:
        return 'SEMAFORO GIALLO';
      case DailySemaphore.rosso:
        return 'SEMAFORO ROSSO';
    }
  }
}
