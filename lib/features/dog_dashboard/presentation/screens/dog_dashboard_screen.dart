import 'package:artrosi_cane/core/widgets/app_banner.dart';
import 'package:artrosi_cane/features/dog_dashboard/presentation/widgets/dog_edit_sheet.dart';
import 'package:artrosi_cane/features/home/data/dog_remote_repository.dart';
import 'package:artrosi_cane/features/home/presentation/providers/home_providers.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:artrosi_cane/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DogDashboardScreen extends ConsumerStatefulWidget {
  const DogDashboardScreen({super.key, required this.dogData});

  final Map<String, dynamic> dogData; // Using Map for now, will switch to Dog entity later

  @override
  ConsumerState<DogDashboardScreen> createState() => _DogDashboardScreenState();
}

class _DogDashboardScreenState extends ConsumerState<DogDashboardScreen> {
  late String _name;
  late String _breed;
  late String _ageText;
  late String _weightText;
  late String _imagePath;
  late String _arthrosisGrade;
  String? _dogId;

  @override
  void initState() {
    super.initState();
    final data = widget.dogData;
    _name = (data['name'] ?? 'Il tuo cane').toString();
    _breed = (data['breed'] ?? 'Razza non indicata').toString();
    _ageText = (data['age'] ?? 'N/A').toString();
    _weightText = (data['weight'] ?? 'N/A').toString();
    _imagePath = (data['imagePath'] ?? 'assets/first-dog.png').toString();
    _arthrosisGrade = (data['arthrosisGrade'] ?? 'Non rilevato').toString();
    _dogId = data['id']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => DogEditSheet(
                  initialName: _name,
                  initialAge: _ageText,
                  initialWeight: _weightText,
                  initialImagePath: _imagePath,
                  onSave: (newName, newAge, newWeight, newImage) async {
                    final dogId = _dogId;
                    if (dogId == null || dogId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Errore: ID cane non trovato')),
                      );
                      return false;
                    }

                    final parsedAge = double.tryParse(newAge.replaceAll(',', '.'));
                    if (parsedAge == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Inserisci un’età valida.')),
                      );
                      return false;
                    }

                    final parsedWeight = double.tryParse(newWeight.replaceAll(',', '.'));
                    if (parsedWeight == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Inserisci un peso valido.')),
                      );
                      return false;
                    }

                    try {
                      final repo = ref.read(dogRemoteRepositoryProvider);
                      await repo.updateDog(
                        dogId: dogId,
                        name: newName.trim(),
                        ageYears: parsedAge,
                        weightKg: parsedWeight,
                      );
                      ref.invalidate(userDogsProvider);
                      if (!mounted) return true;
                      setState(() {
                        _name = newName.trim();
                        _ageText = newAge.trim();
                        _weightText = newWeight.trim();
                        if (newImage != null) {
                          _imagePath = newImage;
                        }
                      });
                      AppBanner.showSuccess(context, 'Profilo aggiornato.');
                      return true;
                    } catch (e) {
                      if (!mounted) return false;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Errore durante il salvataggio: $e')),
                      );
                      return false;
                    }
                  },
                  onDelete: () async {
                    // Confirm delete
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Elimina profilo'),
                        content: Text('Sei sicuro di voler eliminare il profilo di $_name? Questa azione non può essere annullata.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annulla'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final dogId = _dogId;
                      if (dogId == null) {
                         // Should not happen if data is consistent, but safety check
                         if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Errore: ID cane non trovato')),
                           );
                         }
                         return;
                      }

                      try {
                        // Close the sheet first
                        Navigator.of(ctx).pop(); 

                        final repo = ref.read(dogRemoteRepositoryProvider);
                        await repo.deleteDog(dogId);
                        
                        // Refresh list
                        ref.invalidate(userDogsProvider);

                        if (context.mounted) {
                          // Go back to home
                          context.go('/home');
                          AppBanner.showSuccess(context, 'Profilo eliminato.');
                        }
                      } catch (e) {
                         if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
                           );
                         }
                      }
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Image
            _buildHeader(_imagePath),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Info
                  Text(
                    _name,
                    style: AppTypography.h1.copyWith(color: AppColors.primaryBlue),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _breed,
                    style: AppTypography.body.copyWith(
                      color: AppColors.text.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Stats Row
                  Row(
                    children: [
                      _buildStatCard('Età', '$_ageText anni', Icons.cake),
                      const SizedBox(width: AppSpacing.md),
                      _buildStatCard('Peso', '$_weightText kg', Icons.monitor_weight),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Arthrosis Grade Section
                  _buildArthrosisSection(context, _arthrosisGrade),
                  const SizedBox(height: AppSpacing.xl),

                  // Personalized Advice
                  _buildAdviceSection(context),
                  
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String imagePath) {
    return SizedBox(
      height: 340, // Increased height slightly
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            bottom: 20, // Leave space for the wave overlap
            child: imagePath.startsWith('http')
                ? Image.network(imagePath, fit: BoxFit.cover)
                : Image.asset(imagePath, fit: BoxFit.cover),
          ),
          Positioned.fill(
            bottom: 20,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          // White Wave Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: ClipPath(
              clipper: const _HeaderWaveClipper(),
              child: Container(
                color: AppColors.background,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.body.copyWith(
                    color: AppColors.text.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.bodyBold.copyWith(color: AppColors.primaryBlue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArthrosisSection(BuildContext context, String grade) {
    final mapped = _mapRisk(grade);
    final isUnknown = mapped.label == null;
    final bgColor = isUnknown ? const Color(0xFFFFF3E0) : mapped.background;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grado Artrosi',
                style: AppTypography.h1.copyWith(
                  color: mapped.textColor,
                  fontSize: 24,
                ),
              ),
              Icon(
                isUnknown ? Icons.warning_amber_rounded : Icons.health_and_safety,
                color: AppColors.primaryBlue,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mapped.label ?? 'Non ancora valutato',
            style: AppTypography.h1.copyWith(
              color: mapped.textColor,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                context.push('/quiz', extra: {
                  'skipIntro': true,
                  'dog': widget.dogData,
                });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUnknown ? AppColors.ctaApricot : Colors.white,
                  foregroundColor: isUnknown ? Colors.white : AppColors.ctaApricot,
                  elevation: isUnknown ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  isUnknown ? 'Fai il test' : 'Rifai il test',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceSection(BuildContext context) {
    final gradeString = _arthrosisGrade;
    final riskCategory = _riskCategory(gradeString);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Consigli Personalizzati',
          style: AppTypography.h1.copyWith(
            color: AppColors.ctaApricot,
            fontSize: 24, // Custom size for h3 equivalent
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildWalkCard(context, riskCategory, gradeString),
        const SizedBox(height: AppSpacing.md),
        _buildExerciseCard(context, riskCategory, gradeString),
      ],
    );
  }

  Widget _buildExerciseCard(BuildContext context, _RiskCategory category, String gradeString) {
    final subtitle = _exerciseCardSubtitle(category);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push('/exercise', extra: {
            'grade': gradeString,
            'name': _name.isNotEmpty ? _name : 'Il tuo cane',
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.fitness_center, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esercizio fisico consigliato',
                      style: AppTypography.bodyBold.copyWith(color: AppColors.primaryBlue, fontSize: 16),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.primaryBlue),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: AppTypography.body.copyWith(color: AppColors.text.withOpacity(0.8)),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.touch_app, size: 18, color: AppColors.ctaApricot),
                  const SizedBox(width: 6),
                  Text(
                    'Tocca per aprire i dettagli',
                    style: AppTypography.bodyBold.copyWith(
                      color: AppColors.ctaApricot,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _exerciseCardSubtitle(_RiskCategory category) {
    switch (category) {
      case _RiskCategory.none:
        return 'Idee per attività e gioco in sicurezza';
      case _RiskCategory.mild:
        return 'Esercizi a basso impatto e sessioni brevi';
      case _RiskCategory.severe:
        return 'Movimento dolce per mantenere la mobilità';
      case _RiskCategory.unknown:
        return 'Apri i consigli per esercizi su misura';
    }
  }

  _RiskCategory _riskCategory(String grade) {
    final normalized = grade.toLowerCase();
    if (normalized.contains('grave') || normalized.contains('alto')) return _RiskCategory.severe;
    if (normalized.contains('lieve') || normalized.contains('medio')) return _RiskCategory.mild;
    if (normalized.contains('nessun') || normalized.contains('basso')) return _RiskCategory.none;
    return _RiskCategory.unknown;
  }

  Widget _buildWalkCard(BuildContext context, _RiskCategory category, String gradeString) {
    final summary = _walkSummary(category);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push('/walks', extra: {
            'grade': gradeString,
            'name': _name.isNotEmpty ? _name : 'Il tuo cane',
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.map_outlined, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Passeggiate consigliate',
                      style: AppTypography.bodyBold.copyWith(color: AppColors.primaryBlue, fontSize: 16),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.primaryBlue),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Scopri cosa gli esperti consigliano per la salute del tuo cane',
                style: AppTypography.body.copyWith(color: AppColors.text.withOpacity(0.8)),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.touch_app, size: 18, color: AppColors.ctaApricot),
                  const SizedBox(width: 6),
                  Text(
                    'Tocca per aprire i dettagli',
                    style: AppTypography.bodyBold.copyWith(
                      color: AppColors.ctaApricot,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _WalkSummary _walkSummary(_RiskCategory category) {
    switch (category) {
      case _RiskCategory.none:
        return _WalkSummary(
          title: 'Nessun segno di artrosi: 10–20 min liberi.',
          details: 'Varia terreni e stimoli (parco, bosco, lungomare).',
        );
      case _RiskCategory.mild:
        return _WalkSummary(
          title: 'Artrosi lieve: 10–20 min, meglio uscite brevi.',
          details: 'Prato/sterrato regolare; limita asfalto lungo e sabbia.',
        );
      case _RiskCategory.severe:
        return _WalkSummary(
          title: 'Artrosi avanzata: 5–10 min su prato, più volte al giorno.',
          details: 'Evita superfici dure o irregolari; percorsi piatti e prevedibili.',
        );
      case _RiskCategory.unknown:
      default:
        return _WalkSummary(
          title: 'Fai il test per consigli mirati sulle passeggiate.',
        );
    }
  }

  _RiskMapping _mapRisk(String grade) {
    final normalized = grade.toLowerCase();
    if (normalized.contains('alto') || normalized.contains('grave')) {
      return _RiskMapping(
        label: 'Artrosi Grave',
        textColor: Colors.red.shade700,
        background: Colors.white,
      );
    }
    if (normalized.contains('medio') || normalized.contains('lieve')) {
      return _RiskMapping(
        label: 'Artrosi Lieve',
        textColor: Colors.orange.shade700,
        background: Colors.white,
      );
    }
    if (normalized.contains('nessun') || normalized.contains('basso')) {
      return _RiskMapping(
        label: 'Nessun Livello di artrosi',
        textColor: Colors.green.shade700,
        background: Colors.white,
      );
    }
    // Unknown / not tested
    return _RiskMapping(
      label: null,
      textColor: AppColors.primaryBlue,
      background: Colors.white,
    );
  }
}

class _RiskMapping {
  _RiskMapping({
    required this.label,
    required this.textColor,
    required this.background,
  });

  final String? label;
  final Color textColor;
  final Color background;
}

enum _RiskCategory { none, mild, severe, unknown }

class _WalkSummary {
  _WalkSummary({required this.title, this.details});
  final String title;
  final String? details;
}

class _HeaderWaveClipper extends CustomClipper<Path> {
  const _HeaderWaveClipper();

  @override
  Path getClip(Size size) {
    var path = Path();
    // Start from the bottom left, but go up to the wave start height
    // We want the white part to be at the bottom.
    // So we draw the shape of the WHITE overlay.
    
    // Start at (0, 40) - lower down
    path.moveTo(0, 40);

    // Go to (0, 0) is not what we want if we want the wave to be the top edge of this container.
    // The container is the white overlay.
    // So the top edge of this container should be the wave.
    
    // Let's make a nice S-curve
    // Start high on the left
    path.lineTo(0, 20); 

    // Curve down then up
    final firstControlPoint = Offset(size.width * 0.25, 50);
    final firstEndPoint = Offset(size.width * 0.5, 30);
    
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    final secondControlPoint = Offset(size.width * 0.75, 10);
    final secondEndPoint = Offset(size.width, 40);
    
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    // Close the path at the bottom
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
