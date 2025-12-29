import 'package:artrosi_cane/features/onboarding/domain/entities/dog_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DogSupabaseRepository {
  DogSupabaseRepository(this._client);

  final SupabaseClient _client;

  Future<String?> upsertDog(DogProfile profile) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    if ((profile.name ?? '').trim().isEmpty) return null;

    // Try to find an existing dog for this owner with the same name
    final existing = await _client
        .from('dogs')
        .select('id')
        .eq('owner_id', userId)
        .eq('name', profile.name!)
        .limit(1)
        .maybeSingle();

    final payload = {
      'owner_id': userId,
      'name': profile.name,
      'age_years': profile.ageYears,
      'weight_kg': profile.weightKg,
      'breed_id': profile.breedId,
    };

    if (existing != null && existing['id'] != null) {
      final id = existing['id'] as String;
      await _client.from('dogs').update(payload).eq('id', id);
      return id;
    } else {
      final inserted = await _client.from('dogs').insert(payload).select('id').maybeSingle();
      return inserted?['id'] as String?;
    }
  }
}

final dogSupabaseRepositoryProvider = Provider<DogSupabaseRepository>((ref) {
  final client = Supabase.instance.client;
  return DogSupabaseRepository(client);
});
