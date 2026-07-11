import 'package:artrosi_cane/core/widgets/app_text.dart';
import 'package:artrosi_cane/features/home/data/dog_remote_repository.dart';
import 'package:artrosi_cane/features/home/presentation/providers/home_providers.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DeletePetDialog extends ConsumerWidget {
  const DeletePetDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dogsAsync = ref.watch(userDogsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.custom(
                  context.l10n.text('Rimuovi Cane'),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.text),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            dogsAsync.when(
              data: (dogs) {
                if (dogs.isEmpty) {
                  // Chiudi il dialog se non ci sono cani da mostrare
                  Future.microtask(() {
                    if (context.mounted) {
                      context.pop();
                    }
                  });
                  return const SizedBox.shrink();
                }
                return SizedBox(
                  height: 200, // Limit height
                  child: ListView.separated(
                    itemCount: dogs.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final dog = dogs[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: dog.breedImageUrl != null
                              ? NetworkImage(dog.breedImageUrl!)
                              : null,
                          child: dog.breedImageUrl == null
                              ? const Icon(Icons.pets)
                              : null,
                        ),
                        title: Text(
                          dog.name ?? context.l10n.text('Senza nome'),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  context.l10n.text('Conferma eliminazione'),
                                ),
                                content: Text(
                                  context.l10n.text(
                                    'Sei sicuro di voler eliminare {{dogName}}?',
                                    {'dogName': dog.name ?? ''},
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(context.l10n.text('Annulla')),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                      context.l10n.text('Elimina'),
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              try {
                                final repo = ref.read(
                                  dogRemoteRepositoryProvider,
                                );
                                await repo.deleteDog(dog.id!);
                                ref.invalidate(userDogsProvider);

                                if (context.mounted) {
                                  context
                                      .pop(); // Close the dialog after delete
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.l10n.text(
                                          '{{dogName}} rimosso.',
                                          {'dogName': dog.name ?? ''},
                                        ),
                                      ),
                                    ),
                                  );
                                  // If it was the last dog, we might want to close the dialog or show empty state
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.l10n.text('Errore: {{error}}', {
                                          'error': e.toString(),
                                        }),
                                      ),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(context.l10n.text('Errore nel caricamento.')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
