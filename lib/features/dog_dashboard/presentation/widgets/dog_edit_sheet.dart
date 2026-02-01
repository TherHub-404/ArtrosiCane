import 'package:artrosi_cane/core/widgets/app_text.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class DogEditSheet extends StatefulWidget {
  const DogEditSheet({
    super.key,
    required this.initialName,
    required this.initialAge,
    required this.initialWeight,
    this.initialImagePath,
    required this.onSave,
    required this.onDelete,
  });

  final String initialName;
  final String initialAge;
  final String initialWeight;
  final String? initialImagePath;
  final Future<bool> Function(String name, String age, String weight, String? imagePath) onSave;
  final VoidCallback onDelete;

  @override
  State<DogEditSheet> createState() => _DogEditSheetState();
}

class _DogEditSheetState extends State<DogEditSheet> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _ageController = TextEditingController(text: widget.initialAge);
    _weightController = TextEditingController(text: widget.initialWeight);
    _imagePath = widget.initialImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.custom('Modifica Profilo', fontSize: 24, fontWeight: FontWeight.bold),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Photo Upload
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _openImagePickerSheet,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildAvatar(),
                  ),
                ),
                const SizedBox(height: 8),
                AppText.custom('Cambia foto', color: AppColors.primaryBlue, fontSize: 12),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Form Fields
          _buildTextField('Nome', _nameController),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _buildTextField('Età (anni)', _ageController, isNumber: true)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _buildTextField('Peso (kg)', _weightController, isNumber: true)),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final ok = await widget.onSave(
                  _nameController.text,
                  _ageController.text,
                  _weightController.text,
                  _imagePath,
                );
                if (ok && mounted) {
                  context.pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Salva Modifiche',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Delete Button
          Center(
            child: TextButton(
              onPressed: widget.onDelete,
              child: const Text(
                'Elimina profilo',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
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

  Widget _buildAvatar() {
    final placeholder = Container(
      color: AppColors.background,
      child: const Icon(Icons.camera_alt, color: AppColors.primaryBlue, size: 32),
    );

    if (_imagePath == null || _imagePath!.isEmpty) {
      return placeholder;
    }
    if (_imagePath!.startsWith('http')) {
      return Image.network(
        _imagePath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }
    final file = File(_imagePath!);
    if (!file.existsSync()) return placeholder;
    return Image.file(file, fit: BoxFit.cover);
  }

  void _openImagePickerSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
                icon: const Icon(Icons.photo_camera_rounded, color: AppColors.primaryBlue),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
                icon: const Icon(Icons.photo_library_rounded, color: AppColors.primaryBlue),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imagePath = pickedFile.path;
        });
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      final isPermissionDenied =
          e.code == 'camera_access_denied' || e.code == 'photo_access_denied';
      final msg = isPermissionDenied
          ? 'Serve il permesso per usare fotocamera o libreria.'
          : 'Impossibile aprire fotocamera/galleria.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }
}
