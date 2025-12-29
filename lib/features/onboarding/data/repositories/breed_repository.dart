import 'package:artrosi_cane/features/onboarding/domain/entities/breed.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BreedRepository {
  BreedRepository(this._client);

  final SupabaseClient _client;

  Future<List<Breed>> fetchBreeds() async {
    final response = await _client
        .from('breeds')
        .select('id, name, name_it')
        .order('name')
        .limit(500); // assicurati di ricevere tutte le razze
    final list = response as List<dynamic>;
    return list
        .map((item) => Breed(
              id: item['id'] as String,
              name: item['name'] as String,
              nameIt: item['name_it'] as String?,
            ))
        .toList();
  }
}

final breedRepositoryProvider = Provider<BreedRepository>((ref) {
  final client = Supabase.instance.client;
  return BreedRepository(client);
});
