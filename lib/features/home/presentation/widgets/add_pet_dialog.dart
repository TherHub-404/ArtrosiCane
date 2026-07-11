import 'package:artrosi_cane/core/utils/haptics.dart';
import 'package:artrosi_cane/core/widgets/app_text.dart';
import 'package:artrosi_cane/features/home/data/dog_remote_repository.dart';
import 'package:artrosi_cane/features/home/presentation/providers/home_providers.dart';
import 'package:artrosi_cane/core/widgets/app_banner.dart';
import 'package:artrosi_cane/features/onboarding/domain/entities/breed.dart';
import 'package:artrosi_cane/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:artrosi_cane/l10n/app_locale.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:artrosi_cane/theme/app_typography.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AddPetDialog extends ConsumerStatefulWidget {
  const AddPetDialog({super.key});

  @override
  ConsumerState<AddPetDialog> createState() => _AddPetDialogState();
}

class _AddPetDialogState extends ConsumerState<AddPetDialog> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  String? _selectedBreedId;
  String? _selectedBreedLabel;
  bool _isMixedBreed = false;
  bool _isLoading = false;
  bool _startDiagnosisAfterCreate = false;

  Future<void> _toggleMixedBreed(bool checked) async {
    if (checked) {
      try {
        final breeds = await ref.read(breedListProvider.future);
        final mixed = breeds.where((b) => b.isMixedBreed).firstOrNull;
        if (mixed == null || !mounted) return;
        final language = AppLanguage.fromLocale(
          Localizations.localeOf(context),
        );
        setState(() {
          _isMixedBreed = true;
          _selectedBreedId = mixed.id;
          _selectedBreedLabel = mixed.localizedName(language);
        });
      } catch (_) {
        return;
      }
    } else {
      setState(() {
        _isMixedBreed = false;
        _selectedBreedId = null;
        _selectedBreedLabel = null;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _addPet() async {
    final name = _nameController.text.trim();
    final age = double.tryParse(_ageController.text.replaceAll(',', '.'));
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (name.isEmpty || age == null || weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.text('Compila correttamente nome, età e peso'),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(dogRemoteRepositoryProvider);
      final dog = await repo.addDog(
        name: name,
        ageYears: age,
        weightKg: weight,
        breedId: _selectedBreedId,
      );

      // Refresh the list
      ref.invalidate(userDogsProvider);

      if (!mounted) return;
      final router = GoRouter.of(context);
      context.pop();

      if (_startDiagnosisAfterCreate) {
        await router.push(
          '/quiz',
          extra: {
            'skipIntro': false,
            'startFromDiagnosis': true,
            'dog': {
              'id': dog.id,
              'name': dog.name,
              'breed': dog.breedName,
              'breedId': dog.breedId,
              'imagePath': dog.breedImageUrl,
              'age': dog.ageYears,
              'weight': dog.weightKg,
            },
          },
        );
      } else {
        AppBanner.showSuccess(
          context,
          context.l10n.text('Cane aggiunto con successo!'),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.text('Errore: {{error}}', {'error': e.toString()}),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText.custom(
                    context.l10n.text('Aggiungi Cane'),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.text),
                    onPressed: () {
                      Haptics.tap();
                      context.pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              _buildTextField(context.l10n.text('Nome'), _nameController),
              const SizedBox(height: AppSpacing.md),
              _BreedPickerField(
                label: context.l10n.text('Razza'),
                selectedLabel: _selectedBreedLabel,
                onTap: _openBreedPicker,
                disabled: _isMixedBreed,
              ),
              const SizedBox(height: AppSpacing.xs),
              _MixedBreedCheckbox(
                value: _isMixedBreed,
                onChanged: _toggleMixedBreed,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      context.l10n.text('Età (anni)'),
                      _ageController,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildTextField(
                      context.l10n.text('Peso (kg)'),
                      _weightController,
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CheckboxListTile(
                  value: _startDiagnosisAfterCreate,
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _startDiagnosisAfterCreate = value ?? false;
                          });
                        },
                  title: Text(
                    context.l10n.text('Avvia il quiz salute articolare'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  activeColor: AppColors.ctaApricot,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Haptics.strong();
                          _addPet();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ctaApricot,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _startDiagnosisAfterCreate
                              ? context.l10n.text('Aggiungi e scegli diagnosi')
                              : context.l10n.text('Aggiungi'),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.custom(
          label,
          color: AppColors.text.withOpacity(0.6),
          fontSize: 12,
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openBreedPicker() async {
    try {
      final breeds = await ref.read(breedListProvider.future);
      if (!mounted) return;

      if (breeds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.text('Nessuna razza disponibile.')),
          ),
        );
        return;
      }

      final picked = await _showBreedPicker(context, breeds);
      if (picked != null) {
        final language = AppLanguage.fromLocale(
          Localizations.localeOf(context),
        );
        setState(() {
          _selectedBreedId = picked.id;
          _selectedBreedLabel = picked.localizedName(language);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.text('Errore caricamento razze: {{error}}', {
                'error': e.toString(),
              }),
            ),
          ),
        );
      }
    }
  }

  Future<Breed?> _showBreedPicker(
    BuildContext context,
    List<Breed> breeds,
  ) async {
    final language = AppLanguage.fromLocale(Localizations.localeOf(context));
    final sortedBreeds = [...breeds]
      ..sort(
        (a, b) => a
            .localizedName(language)
            .toLowerCase()
            .compareTo(b.localizedName(language).toLowerCase()),
      );
    return showModalBottomSheet<Breed>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final controller = TextEditingController();
        final valueNotifier = ValueNotifier<List<Breed>>(sortedBreeds);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: AppSpacing.lg,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l10n.text('Cerca la razza'),
                style: AppTypography.h1.copyWith(fontSize: 20),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: context.l10n.text('Digita per cercare'),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.ctaApricot,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (query) {
                  final q = query.toLowerCase().trim();
                  if (q.isEmpty) {
                    valueNotifier.value = sortedBreeds;
                  } else {
                    valueNotifier.value = sortedBreeds
                        .where(
                          (b) => b
                              .localizedName(language)
                              .toLowerCase()
                              .contains(q),
                        )
                        .toList();
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: ValueListenableBuilder<List<Breed>>(
                  valueListenable: valueNotifier,
                  builder: (context, filtered, _) {
                    if (filtered.isEmpty) {
                      return Center(
                        child: AppText.body(
                          'Nessun risultato',
                          color: AppColors.text.withOpacity(0.6),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final breed = filtered[index];
                        final label = breed.localizedName(language);
                        return ListTile(
                          title: Text(
                            label,
                            style: AppTypography.bodyBold.copyWith(
                              fontSize: 16,
                            ),
                          ),
                          onTap: () => Navigator.of(context).pop(breed),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }
}

class _BreedPickerField extends StatelessWidget {
  const _BreedPickerField({
    required this.label,
    required this.selectedLabel,
    required this.onTap,
    this.disabled = false,
  });

  final String label;
  final String? selectedLabel;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.custom(
            label,
            color: AppColors.text.withOpacity(0.6),
            fontSize: 12,
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: disabled ? null : onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: disabled
                    ? const Color(0xFFEDEEF2)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.pets_rounded,
                    color: AppColors.ctaApricot.withOpacity(0.9),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedLabel ?? context.l10n.text('Seleziona razza'),
                      style: TextStyle(
                        color: selectedLabel == null
                            ? AppColors.text.withOpacity(0.5)
                            : AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppColors.text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MixedBreedCheckbox extends StatelessWidget {
  const _MixedBreedCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.ctaApricot,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              context.l10n.text('Razza mista'),
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
