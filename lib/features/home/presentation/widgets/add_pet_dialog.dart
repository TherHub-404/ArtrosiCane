import 'package:artrosi_cane/core/widgets/app_text.dart';
import 'package:artrosi_cane/features/home/data/dog_remote_repository.dart';
import 'package:artrosi_cane/features/home/presentation/providers/home_providers.dart';
import 'package:artrosi_cane/core/widgets/app_banner.dart';
import 'package:artrosi_cane/features/onboarding/domain/entities/breed.dart';
import 'package:artrosi_cane/features/onboarding/presentation/providers/onboarding_providers.dart';
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
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _addPet() async {
    if (_nameController.text.isEmpty || _ageController.text.isEmpty || _weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila tutti i campi obbligatori')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(dogRemoteRepositoryProvider);
      await repo.addDog(
        name: _nameController.text,
        ageYears: double.tryParse(_ageController.text) ?? 0,
        weightKg: double.tryParse(_weightController.text) ?? 0,
        breedId: _selectedBreedId,
      );

      // Refresh the list
      ref.invalidate(userDogsProvider);

      if (mounted) {
        context.pop();
        AppBanner.showSuccess(context, 'Cane aggiunto con successo!');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
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
                  AppText.custom('Aggiungi Cane', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.text),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              
              _buildTextField('Nome', _nameController),
              const SizedBox(height: AppSpacing.md),
              _BreedPickerField(
                label: 'Razza',
                selectedLabel: _selectedBreedLabel,
                onTap: _openBreedPicker,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: _buildTextField('Età (anni)', _ageController, isNumber: true)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _buildTextField('Peso (kg)', _weightController, isNumber: true)),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addPet,
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
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Aggiungi',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.custom(label, color: AppColors.text.withOpacity(0.6), fontSize: 12),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          const SnackBar(content: Text('Nessuna razza disponibile.')),
        );
        return;
      }

      final picked = await _showBreedPicker(context, breeds);
      if (picked != null) {
        setState(() {
          _selectedBreedId = picked.id;
          _selectedBreedLabel =
              picked.nameIt?.isNotEmpty == true ? picked.nameIt : picked.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore caricamento razze: $e')),
        );
      }
    }
  }

  Future<Breed?> _showBreedPicker(BuildContext context, List<Breed> breeds) async {
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
                  prefixIcon: const Icon(Icons.search, color: AppColors.ctaApricot),
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
                        .where((b) => (b.nameIt ?? '').toLowerCase().contains(q))
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
                        final label =
                            breed.nameIt?.isNotEmpty == true ? breed.nameIt! : breed.name;
                        return ListTile(
                          title: Text(
                            label,
                            style: AppTypography.bodyBold.copyWith(fontSize: 16),
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
  });

  final String label;
  final String? selectedLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.custom(label, color: AppColors.text.withOpacity(0.6), fontSize: 12),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.pets_rounded, color: AppColors.ctaApricot.withOpacity(0.9)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedLabel ?? 'Seleziona razza',
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
    );
  }
}
