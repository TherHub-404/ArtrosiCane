import 'package:artrosi_cane/core/widgets/app_text.dart';
import 'package:artrosi_cane/features/onboarding/domain/entities/breed.dart';
import 'package:artrosi_cane/features/onboarding/domain/entities/dog_profile.dart';
import 'package:artrosi_cane/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:artrosi_cane/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DogProfilePage extends ConsumerStatefulWidget {
  const DogProfilePage({
    super.key,
    this.onProfileChanged,
    this.showValidationErrors = false,
  });

  final Function(DogProfile)? onProfileChanged;
  final bool showValidationErrors;

  @override
  ConsumerState<DogProfilePage> createState() => _DogProfilePageState();
}

class _DogProfilePageState extends ConsumerState<DogProfilePage>
    with AutomaticKeepAliveClientMixin {
  final _nameController = TextEditingController();

  AgeGroup _ageGroup = AgeGroup.adulto;
  final DogSize _size = DogSize.media;
  double _weightKg = 20;
  String? _selectedBreedId;
  String? _selectedBreedName;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyChanges());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  double _ageYearsForGroup(AgeGroup group) {
    switch (group) {
      case AgeGroup.cucciolo:
        return 0.5;
      case AgeGroup.adulto:
        return 4;
      case AgeGroup.senior:
        return 9;
    }
  }

  void _notifyChanges() {
    final profile = DogProfile(
      name: _nameController.text.isEmpty ? null : _nameController.text.trim(),
      ageYears: _ageYearsForGroup(_ageGroup),
      weightKg: _weightKg,
      breedId: _selectedBreedId,
      breedName: _selectedBreedName,
      ageGroup: _ageGroup,
      size: _size,
    );
    widget.onProfileChanged?.call(profile);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 700;
        final verticalGap = isCompact ? AppSpacing.md : AppSpacing.xl;
        final bottomSafeInset = MediaQuery.of(context).padding.bottom;
        final missingName =
            widget.showValidationErrors && _nameController.text.trim().isEmpty;
        final missingBreed =
            widget.showValidationErrors &&
            (_selectedBreedId == null || _selectedBreedId!.trim().isEmpty);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg + bottomSafeInset,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              AppText.h1(
                'Raccontaci del tuo cane',
                color: AppColors.primaryBlue,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppText.body(
                'Queste informazioni ci aiuteranno a personalizzare i consigli per il tuo amico a quattro zampe.',
                color: AppColors.text.withValues(alpha: 0.6),
              ),
              SizedBox(height: verticalGap),

              // Name Field
              TextFormField(
                controller: _nameController,
                autofocus: true,
                onChanged: (_) {
                  setState(() {});
                  _notifyChanges();
                },
                decoration: InputDecoration(
                  hintText: '🐶 Come si chiama il tuo cane?',
                  errorText: missingName ? 'Campo obbligatorio' : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: missingName
                          ? Colors.red.shade400
                          : AppColors.borderSoft,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: missingName
                          ? Colors.red.shade400
                          : AppColors.borderSoft,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: missingName
                          ? Colors.red.shade500
                          : AppColors.primaryBlue,
                      width: 1.4,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
              SizedBox(height: verticalGap),

              // Age group
              AppText.body('Età', bold: true, color: AppColors.text),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _AgeGroupOption(
                      title: 'Cucciolo',
                      subtitle: '(0–1)',
                      selected: _ageGroup == AgeGroup.cucciolo,
                      onTap: () {
                        setState(() => _ageGroup = AgeGroup.cucciolo);
                        _notifyChanges();
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _AgeGroupOption(
                      title: 'Adulto',
                      subtitle: '(1–7)',
                      selected: _ageGroup == AgeGroup.adulto,
                      onTap: () {
                        setState(() => _ageGroup = AgeGroup.adulto);
                        _notifyChanges();
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _AgeGroupOption(
                      title: 'Senior',
                      subtitle: '(7+)',
                      selected: _ageGroup == AgeGroup.senior,
                      onTap: () {
                        setState(() => _ageGroup = AgeGroup.senior);
                        _notifyChanges();
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: verticalGap),

              // Weight slider
              AppText.body(
                'Peso: ${_weightKg.toStringAsFixed(1)} kg',
                bold: true,
                color: AppColors.text,
              ),
              const SizedBox(height: AppSpacing.sm),
              Slider(
                min: 1,
                max: 80,
                divisions: 79,
                value: _weightKg,
                activeColor: AppColors.ctaApricot,
                onChanged: (value) {
                  setState(() => _weightKg = value);
                  _notifyChanges();
                },
              ),
              SizedBox(height: verticalGap),

              // Breed selector bottom sheet
              AppText.body('Razza', bold: true, color: AppColors.text),
              const SizedBox(height: AppSpacing.sm),
              _BreedPickerField(
                selectedLabel: _selectedBreedName,
                hasError: missingBreed,
                onTap: () async {
                  final breeds = await ref
                      .read(breedListProvider.future)
                      .catchError((_) => <Breed>[]);
                  if (!mounted || breeds.isEmpty) return;
                  final picked = await _showBreedPicker(this.context, breeds);
                  if (!mounted) return;
                  if (picked != null) {
                    setState(() {
                      _selectedBreedId = picked.id;
                      _selectedBreedName = picked.nameIt?.isNotEmpty == true
                          ? picked.nameIt
                          : picked.name;
                    });
                    _notifyChanges();
                  }
                },
              ),
              if (missingBreed) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Seleziona una razza per continuare.',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              SizedBox(height: verticalGap),
            ],
          ),
        );
      },
    );
  }

  Future<Breed?> _showBreedPicker(
    BuildContext context,
    List<Breed> breeds,
  ) async {
    return showModalBottomSheet<Breed>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final controller = TextEditingController();
        final valueNotifier = ValueNotifier<List<Breed>>(breeds);
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
                'Cerca la razza',
                style: AppTypography.h1.copyWith(fontSize: 20),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Digita per cercare',
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
                    valueNotifier.value = breeds;
                  } else {
                    valueNotifier.value = breeds
                        .where(
                          (b) => (b.nameIt ?? '').toLowerCase().contains(q),
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
                          color: AppColors.text.withValues(alpha: 0.6),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final breed = filtered[index];
                        final label = breed.nameIt?.isNotEmpty == true
                            ? breed.nameIt!
                            : breed.name;
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

class _AgeGroupOption extends StatelessWidget {
  const _AgeGroupOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected ? AppColors.primaryBlue : Colors.white;
    final border = selected ? AppColors.primaryBlue : AppColors.borderSoft;
    final textColor = selected ? Colors.white : AppColors.text;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 1.2),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.bodyBold.copyWith(
                  color: textColor,
                  fontSize: 13,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: textColor.withValues(alpha: 0.9),
                  fontSize: 11,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreedPickerField extends StatelessWidget {
  const _BreedPickerField({
    required this.selectedLabel,
    required this.onTap,
    this.hasError = false,
  });

  final String? selectedLabel;
  final VoidCallback onTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasError ? Colors.red.shade400 : AppColors.borderSoft,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedLabel ?? 'Seleziona razza',
                style: AppTypography.body.copyWith(
                  color: selectedLabel == null
                      ? AppColors.text.withValues(alpha: 0.6)
                      : AppColors.text,
                  fontWeight: selectedLabel == null
                      ? FontWeight.w500
                      : FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.ctaApricot),
          ],
        ),
      ),
    );
  }
}
