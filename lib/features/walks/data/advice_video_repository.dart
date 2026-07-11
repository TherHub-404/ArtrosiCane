import 'package:artrosi_cane/core/bootstrap/app_bootstrap.dart';
import 'package:artrosi_cane/core/providers/supabase_provider.dart';
import 'package:artrosi_cane/features/walks/domain/advice_video.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdviceVideoRepository {
  const AdviceVideoRepository();

  /// Fetches the active advice videos ordered by their [AdviceVideo.position].
  ///
  /// Resolves the Supabase client lazily so a not-yet-initialised instance
  /// surfaces as a normal async error (handled by the UI) instead of a
  /// synchronous crash.
  Future<List<AdviceVideo>> fetchActive() async {
    final client = maybeSupabaseClient();
    if (client == null) {
      throw StateError('Supabase non ancora inizializzato');
    }

    final rows = await client
        .from('advice_videos')
        .select('id, title, description, storage_path, position')
        .eq('is_active', true)
        .order('position', ascending: true);

    final list = <AdviceVideo>[];
    for (final row in (rows as List<dynamic>? ?? const <dynamic>[])) {
      list.add(AdviceVideo.fromRow(Map<String, dynamic>.from(row as Map)));
    }
    return list;
  }
}

final adviceVideoRepositoryProvider = Provider<AdviceVideoRepository>((ref) {
  return const AdviceVideoRepository();
});

/// Active advice videos for the walks tab. Waits for app bootstrap (which
/// initialises Supabase) before querying. Refresh with
/// `ref.invalidate(adviceVideosProvider)`.
final adviceVideosProvider = FutureProvider<List<AdviceVideo>>((ref) async {
  await ref.watch(appBootstrapProvider.future);
  return ref.watch(adviceVideoRepositoryProvider).fetchActive();
});
