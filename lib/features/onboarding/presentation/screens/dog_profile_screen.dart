import 'package:artrosi_cane/core/widgets/app_text.dart';
import 'package:artrosi_cane/features/onboarding/domain/entities/breed.dart';
import 'package:artrosi_cane/features/onboarding/domain/entities/dog_profile.dart';
import 'package:artrosi_cane/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:artrosi_cane/l10n/app_locale.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';
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
  static const bool _screenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');
  final _nameController = TextEditingController();

  AgeGroup _ageGroup = AgeGroup.adulto;
  final DogSize _size = DogSize.media;
  double _weightKg = 20;
  String? _selectedBreedId;
  String? _selectedBreedName;
  bool _isMixedBreed = false;

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
          _selectedBreedName = mixed.localizedName(language);
        });
      } catch (_) {
        return;
      }
    } else {
      setState(() {
        _isMixedBreed = false;
        _selectedBreedId = null;
        _selectedBreedName = null;
      });
    }
    _notifyChanges();
  }

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
    final l10n = context.l10n;
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
                l10n.text('Raccontaci del tuo cane'),
                color: AppColors.primaryBlue,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppText.body(
                l10n.text(
                  'Queste informazioni ci aiuteranno a personalizzare i consigli per il tuo amico a quattro zampe.',
                ),
                color: AppColors.text.withValues(alpha: 0.6),
              ),
              SizedBox(height: verticalGap),

              // Name Field
              TextFormField(
                controller: _nameController,
                autofocus: !_screenshotMode,
                onChanged: (_) {
                  setState(() {});
                  _notifyChanges();
                },
                decoration: InputDecoration(
                  hintText: l10n.text('🐶 Come si chiama il tuo cane?'),
                  errorText: missingName
                      ? l10n.text('Campo obbligatorio')
                      : null,
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
              AppText.body(l10n.text('Età'), bold: true, color: AppColors.text),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _AgeGroupOption(
                      title: l10n.text('Cucciolo'),
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
                      title: l10n.text('Adulto'),
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
                      title: l10n.text('Senior'),
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
                l10n.text('Peso: {{weight}} kg', {
                  'weight': _weightKg.toStringAsFixed(1),
                }),
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
              AppText.body(
                l10n.text('Razza'),
                bold: true,
                color: AppColors.text,
              ),
              const SizedBox(height: AppSpacing.xs),
              _MixedBreedCheckbox(
                value: _isMixedBreed,
                onChanged: _toggleMixedBreed,
              ),
              const SizedBox(height: AppSpacing.xs),
              _BreedPickerField(
                selectedLabel: _selectedBreedName,
                hasError: missingBreed,
                disabled: _isMixedBreed,
                onTap: () async {
                  final breeds = await ref
                      .read(breedListProvider.future)
                      .catchError((_) => <Breed>[]);
                  if (!mounted || breeds.isEmpty) return;
                  final picked = await _showBreedPicker(this.context, breeds);
                  if (!mounted) return;
                  if (picked != null) {
                    final language = AppLanguage.fromLocale(
                      Localizations.localeOf(context),
                    );
                    setState(() {
                      _selectedBreedId = picked.id;
                      _selectedBreedName = picked.localizedName(language);
                    });
                    _notifyChanges();
                  }
                },
              ),
              if (missingBreed) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.text('Seleziona una razza per continuare.'),
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
                context.l10n.text('Razza'),
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
                          color: AppColors.text.withValues(alpha: 0.6),
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
              style: AppTypography.body.copyWith(
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

class _BreedPickerField extends StatelessWidget {
  const _BreedPickerField({
    required this.selectedLabel,
    required this.onTap,
    this.hasError = false,
    this.disabled = false,
  });

  final String? selectedLabel;
  final VoidCallback onTap;
  final bool hasError;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = selectedLabel == null;
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: disabled ? const Color(0xFFF1F2F6) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? Colors.red.shade400 : AppColors.borderSoft,
              width: 1.2,
            ),
            boxShadow: disabled
                ? null
                : [
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
                  selectedLabel ?? context.l10n.text('Seleziona razza'),
                  style: AppTypography.body.copyWith(
                    color: isPlaceholder
                        ? AppColors.text.withValues(alpha: 0.6)
                        : AppColors.text,
                    fontWeight: isPlaceholder
                        ? FontWeight.w500
                        : FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.ctaApricot,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
