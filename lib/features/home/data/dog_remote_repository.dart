import 'package:artrosi_cane/features/onboarding/domain/entities/dog_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DogRemoteRepository {
  DogRemoteRepository(this._client);

  final SupabaseClient _client;

  Future<List<DogProfile>> fetchDogs() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('dogs')
        .select('id, name, age_years, weight_kg, breed_id, breeds(name, name_it, image_url)')
        .eq('owner_id', userId)
        .order('created_at', ascending: true);

    final list = (response as List<dynamic>?) ?? <dynamic>[];
    final dogs = list.map((item) {
      final map = item as Map<String, dynamic>;
      final breedMap = map['breeds'] as Map<String, dynamic>?;
      return DogProfile(
        id: map['id'] as String?,
        name: map['name'] as String?,
        ageYears: (map['age_years'] as num?)?.toDouble(),
        weightKg: (map['weight_kg'] as num?)?.toDouble(),
        breedId: map['breed_id'] as String?,
        breedName: breedMap != null
            ? ((breedMap['name_it'] as String?)?.isNotEmpty == true
                ? breedMap['name_it'] as String?
                : breedMap['name'] as String?)
            : null,
        breedImageUrl: breedMap != null ? breedMap['image_url'] as String? : null,
      );
    }).toList();

    // Fetch latest quiz results for this owner (latest per dog)
    final results = await _client
        .from('quiz_results')
        .select('dog_id, risk_level, score')
        .eq('owner_id', userId)
        .order('created_at', ascending: false);

    final latestByDog = <String, Map<String, dynamic>>{};
    for (final row in (results as List<dynamic>? ?? <dynamic>[])) {
      final map = row as Map<String, dynamic>;
      final dogId = map['dog_id'] as String?;
      if (dogId == null) continue;
      // Keep the first (latest) occurrence per dog_id
      latestByDog.putIfAbsent(dogId, () => map);
    }

    for (var i = 0; i < dogs.length; i++) {
      final dog = dogs[i];
      final latest = dog.id != null ? latestByDog[dog.id!] : null;
      if (latest == null) continue;

      dogs[i] = DogProfile(
        id: dog.id,
        name: dog.name,
        ageYears: dog.ageYears,
        weightKg: dog.weightKg,
        breedId: dog.breedId,
        breedName: dog.breedName,
        breedImageUrl: dog.breedImageUrl,
        riskLevel: latest['risk_level'] as String?,
        riskScore: latest['score'] as int?,
        ageGroup: dog.ageGroup,
        size: dog.size,
      );
    }

    return dogs;
  }


  Future<void> addDog({
    required String name,
    required double ageYears,
    required double weightKg,
    String? breedId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    // For now, we'll just insert basic info. 
    // If breedName is provided, we might want to find the breed_id, but for simplicity let's assume null for now or handle it later.
    // Or if we want to support breed text, we might need to adjust the DB or lookup logic.
    // Let's just insert without breed_id for now if it's a free text field, or maybe we can try to find it.
    
    await _client.from('dogs').insert({
      'owner_id': userId,
      'name': name,
      'age_years': ageYears,
      'weight_kg': weightKg,
      'breed_id': breedId,
    });
  }

  Future<void> deleteDog(String dogId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _client.from('dogs').delete().eq('id', dogId).eq('owner_id', userId);
  }
}

final dogRemoteRepositoryProvider = Provider<DogRemoteRepository>((ref) {
  final client = Supabase.instance.client;
  return DogRemoteRepository(client);
});
