import 'dart:io';

import 'package:artrosi_cane/features/onboarding/domain/entities/dog_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DogRemoteRepository {
  DogRemoteRepository(this._client);

  final SupabaseClient _client;
  static const String _dogProfileImageBucket = 'dog-profile-images';
  static const String _diagnosisFilesBucketFallback = 'dog-diagnosis-files';
  static const String _storageRefPrefix = 'storage://';
  static const List<String> _dogImageColumnCandidates = <String>[
    'profile_image_url',
    'dog_image_url',
    'photo_url',
    'image_url',
    'avatar_url',
  ];
  static const List<String> _dogImageBuckets = <String>[
    _dogProfileImageBucket,
    _diagnosisFilesBucketFallback,
  ];

  String? _cachedDogImageColumn;
  bool _didResolveDogImageColumn = false;

  String _dogSelect({String? imageColumn}) {
    final columns = <String>[
      'id',
      'name',
      'age_years',
      'weight_kg',
      'breed_id',
      'age_group',
      'size',
      'diagnosis_status',
      'diagnosis_answered_at',
      'diagnosis_date',
      'diagnosis_vet',
      'diagnosis_files',
      'diagnosis_care_notes',
      if (imageColumn != null && imageColumn.isNotEmpty) imageColumn,
      'breeds(name, name_it, image_url)',
    ];
    return columns.join(', ');
  }

  Future<List<DogProfile>> fetchDogs() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final dogImageColumn = await _resolveDogImageColumn();
    final list = await _fetchActiveDogs(userId, imageColumn: dogImageColumn);

    final dogs = <DogProfile>[];
    for (final item in list) {
      final map = item as Map<String, dynamic>;
      final breedMap = map['breeds'] as Map<String, dynamic>?;
      final diagnosisStatusRaw = map['diagnosis_status'] as String?;
      final diagnosisFilesRaw = map['diagnosis_files'];
      final diagnosisFiles = diagnosisFilesRaw is List
          ? diagnosisFilesRaw.map((item) => item.toString()).toList()
          : const <String>[];
      final resolvedImageUrl = await _resolveDogImageUrl(
        map,
        imageColumn: dogImageColumn,
        breedMap: breedMap,
      );
      dogs.add(
        DogProfile(
          id: map['id'] as String?,
          name: map['name'] as String?,
          ageYears: (map['age_years'] as num?)?.toDouble(),
          weightKg: (map['weight_kg'] as num?)?.toDouble(),
          breedId: map['breed_id'] as String?,
          ageGroup: _parseAgeGroup(map['age_group'] as String?),
          size: _parseDogSize(map['size'] as String?),
          breedName: breedMap != null
              ? ((breedMap['name_it'] as String?)?.isNotEmpty == true
                    ? breedMap['name_it'] as String?
                    : breedMap['name'] as String?)
              : null,
          breedImageUrl: resolvedImageUrl,
          diagnosisStatus: _parseDiagnosisStatus(diagnosisStatusRaw),
          diagnosisAnsweredAt: DateTime.tryParse(
            map['diagnosis_answered_at']?.toString() ?? '',
          ),
          diagnosisDate: map['diagnosis_date'] as String?,
          diagnosisVet: map['diagnosis_vet'] as String?,
          diagnosisFiles: diagnosisFiles,
          diagnosisCareNotes: map['diagnosis_care_notes'] as String?,
        ),
      );
    }

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
        diagnosisStatus: dog.diagnosisStatus,
        diagnosisAnsweredAt: dog.diagnosisAnsweredAt,
        diagnosisDate: dog.diagnosisDate,
        diagnosisVet: dog.diagnosisVet,
        diagnosisFiles: dog.diagnosisFiles,
        diagnosisCareNotes: dog.diagnosisCareNotes,
      );
    }

    return dogs;
  }

  Future<DogProfile> addDog({
    required String name,
    required double ageYears,
    required double weightKg,
    String? breedId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');
    final dogImageColumn = await _resolveDogImageColumn();

    final inserted = await _client
        .from('dogs')
        .insert({
          'owner_id': userId,
          'name': name.trim(),
          'age_years': ageYears,
          'weight_kg': weightKg,
          'breed_id': breedId,
        })
        .select(_dogSelect(imageColumn: dogImageColumn))
        .single();

    final map = inserted;
    final breedMap = map['breeds'] as Map<String, dynamic>?;
    final resolvedImageUrl = await _resolveDogImageUrl(
      map,
      imageColumn: dogImageColumn,
      breedMap: breedMap,
    );
    final diagnosisFilesRaw = map['diagnosis_files'];
    final diagnosisFiles = diagnosisFilesRaw is List
        ? diagnosisFilesRaw.map((item) => item.toString()).toList()
        : const <String>[];
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
      breedImageUrl: resolvedImageUrl,
      ageGroup: _parseAgeGroup(map['age_group'] as String?),
      size: _parseDogSize(map['size'] as String?),
      diagnosisStatus: _parseDiagnosisStatus(
        map['diagnosis_status'] as String?,
      ),
      diagnosisAnsweredAt: DateTime.tryParse(
        map['diagnosis_answered_at']?.toString() ?? '',
      ),
      diagnosisDate: map['diagnosis_date'] as String?,
      diagnosisVet: map['diagnosis_vet'] as String?,
      diagnosisFiles: diagnosisFiles,
      diagnosisCareNotes: map['diagnosis_care_notes'] as String?,
    );
  }

  Future<void> deleteDog(String dogId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final deletedAt = DateTime.now().toUtc().toIso8601String();
    final payloadAttempts = <Map<String, dynamic>>[
      {'deleted_at': deletedAt, 'is_deleted': true},
      {'deleted_at': deletedAt},
      {'is_deleted': true},
      {'status': 'deleted'},
      {'active': false},
    ];

    for (final payload in payloadAttempts) {
      try {
        await _client
            .from('dogs')
            .update(payload)
            .eq('id', dogId)
            .eq('owner_id', userId);
        return;
      } catch (error) {
        if (!_isMissingColumnError(error)) {
          rethrow;
        }
      }
    }

    throw Exception(
      'Soft delete non supportata sulla tabella dogs. '
      'Aggiungi almeno una colonna tra deleted_at o is_deleted.',
    );
  }

  Future<String?> updateDog({
    required String dogId,
    required String name,
    required double ageYears,
    required double weightKg,
    String? imagePath,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final payload = <String, dynamic>{
      'name': name,
      'age_years': ageYears,
      'weight_kg': weightKg,
    };
    String? uploadedImageDisplayUrl;

    final normalizedImagePath = imagePath?.trim();
    if (normalizedImagePath != null && normalizedImagePath.isNotEmpty) {
      final shouldUploadImage = _looksLikeLocalPath(normalizedImagePath);
      if (shouldUploadImage) {
        final imageColumn = await _resolveDogImageColumn();
        if (imageColumn == null) {
          throw Exception(
            'Nessuna colonna immagine trovata nella tabella dogs: impossibile salvare la foto su Supabase.',
          );
        }
        final uploaded = await _uploadDogImage(
          userId: userId,
          dogId: dogId,
          localPath: normalizedImagePath,
        );
        payload[imageColumn] = uploaded.storageRef;
        uploadedImageDisplayUrl = uploaded.displayUrl;
      }
    }

    await _client
        .from('dogs')
        .update(payload)
        .eq('id', dogId)
        .eq('owner_id', userId)
        .select('id')
        .single();

    return uploadedImageDisplayUrl;
  }

  AgeGroup _parseAgeGroup(String? raw) {
    switch (raw) {
      case 'cucciolo':
        return AgeGroup.cucciolo;
      case 'senior':
        return AgeGroup.senior;
      case 'adulto':
      default:
        return AgeGroup.adulto;
    }
  }

  DogSize _parseDogSize(String? raw) {
    switch (raw) {
      case 'piccola':
        return DogSize.piccola;
      case 'grande':
        return DogSize.grande;
      case 'media':
      default:
        return DogSize.media;
    }
  }

  ArthrosisDiagnosisStatus? _parseDiagnosisStatus(String? raw) {
    switch (raw) {
      case 'confirmed':
        return ArthrosisDiagnosisStatus.confirmed;
      case 'notDiagnosed':
        return ArthrosisDiagnosisStatus.notDiagnosed;
      case 'unknown':
        return ArthrosisDiagnosisStatus.unknown;
      default:
        return null;
    }
  }

  Future<List<dynamic>> _fetchActiveDogs(
    String userId, {
    String? imageColumn,
  }) async {
    final select = _dogSelect(imageColumn: imageColumn);
    final queryAttempts = <Future<dynamic> Function()>[
      () => _client
          .from('dogs')
          .select(select)
          .eq('owner_id', userId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: true),
      () => _client
          .from('dogs')
          .select(select)
          .eq('owner_id', userId)
          .or('is_deleted.eq.false,is_deleted.is.null')
          .order('created_at', ascending: true),
      () => _client
          .from('dogs')
          .select(select)
          .eq('owner_id', userId)
          .or('status.neq.deleted,status.is.null')
          .order('created_at', ascending: true),
      () => _client
          .from('dogs')
          .select(select)
          .eq('owner_id', userId)
          .or('active.eq.true,active.is.null')
          .order('created_at', ascending: true),
      () => _client
          .from('dogs')
          .select(select)
          .eq('owner_id', userId)
          .order('created_at', ascending: true),
    ];

    for (var i = 0; i < queryAttempts.length; i++) {
      try {
        final response = await queryAttempts[i]();
        return (response as List<dynamic>?) ?? <dynamic>[];
      } catch (error) {
        if (!_isMissingColumnError(error) || i == queryAttempts.length - 1) {
          rethrow;
        }
      }
    }

    return <dynamic>[];
  }

  Future<String?> _resolveDogImageColumn() async {
    if (_didResolveDogImageColumn) return _cachedDogImageColumn;

    for (final candidate in _dogImageColumnCandidates) {
      try {
        await _client.from('dogs').select(candidate).limit(1);
        _cachedDogImageColumn = candidate;
        _didResolveDogImageColumn = true;
        return candidate;
      } catch (error) {
        if (!_isMissingColumnError(error)) {
          rethrow;
        }
      }
    }

    _didResolveDogImageColumn = true;
    return null;
  }

  Future<String?> _resolveDogImageUrl(
    Map<String, dynamic> dogRow, {
    required String? imageColumn,
    required Map<String, dynamic>? breedMap,
  }) async {
    final rawStoredImage = imageColumn == null
        ? null
        : _cleanString(dogRow[imageColumn]);
    final resolvedStoredImage = await _resolveStoredImageToUrl(rawStoredImage);
    if (resolvedStoredImage != null) return resolvedStoredImage;

    return _cleanString(breedMap?['image_url']);
  }

  Future<String?> _resolveStoredImageToUrl(String? value) async {
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http')) return value;

    final ref = _parseStorageRef(value);
    if (ref != null) {
      final resolved = await _buildStorageDisplayUrl(
        bucket: ref.bucket,
        objectPath: ref.path,
      );
      if (resolved.trim().isEmpty) return null;
      return resolved;
    }

    if (value.startsWith('assets/')) return null;
    return value;
  }

  _StorageRef? _parseStorageRef(String input) {
    if (!input.startsWith(_storageRefPrefix)) return null;
    final raw = input.substring(_storageRefPrefix.length);
    final separator = raw.indexOf('/');
    if (separator <= 0 || separator == raw.length - 1) return null;
    return _StorageRef(
      bucket: raw.substring(0, separator),
      path: raw.substring(separator + 1),
    );
  }

  String? _cleanString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  bool _looksLikeLocalPath(String value) {
    if (value.startsWith('http')) return false;
    if (value.startsWith('assets/')) return false;
    if (value.startsWith(_storageRefPrefix)) return false;
    return true;
  }

  Future<_UploadedDogImage> _uploadDogImage({
    required String userId,
    required String dogId,
    required String localPath,
  }) async {
    final imageFile = File(localPath);
    if (!await imageFile.exists()) {
      throw Exception('File immagine non trovato: $localPath');
    }

    final bytes = await imageFile.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('Il file immagine selezionato è vuoto.');
    }

    final extension = _extractFileExtension(localPath);
    final objectPath =
        '$userId/$dogId/${DateTime.now().microsecondsSinceEpoch}$extension';
    final contentType = _contentTypeForPath(localPath);

    for (final bucket in _dogImageBuckets) {
      try {
        await _client.storage
            .from(bucket)
            .uploadBinary(
              objectPath,
              bytes,
              fileOptions: FileOptions(contentType: contentType, upsert: true),
            );
        final url = await _buildStorageDisplayUrl(
          bucket: bucket,
          objectPath: objectPath,
        );
        return _UploadedDogImage(
          storageRef: '$_storageRefPrefix$bucket/$objectPath',
          displayUrl: url,
        );
      } catch (error) {
        if (_isStorageBucketMissing(error)) {
          continue;
        }
        rethrow;
      }
    }

    throw Exception(
      'Nessun bucket storage disponibile per salvare la foto del cane.',
    );
  }

  String _extractFileExtension(String path) {
    final normalized = path.replaceAll('\\', '/');
    final fileName = normalized.split('/').last;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == fileName.length - 1) return '.jpg';
    return fileName.substring(dotIndex).toLowerCase();
  }

  String _contentTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    if (lower.endsWith('.jpeg') || lower.endsWith('.jpg')) {
      return 'image/jpeg';
    }
    return 'application/octet-stream';
  }

  Future<String> _buildStorageDisplayUrl({
    required String bucket,
    required String objectPath,
  }) async {
    try {
      final signedUrl = await _client.storage
          .from(bucket)
          .createSignedUrl(objectPath, 60 * 60 * 24 * 30);
      if (signedUrl.trim().isNotEmpty) return signedUrl;
    } catch (error) {
      if (_isStorageObjectMissing(error) || _isStorageBucketMissing(error)) {
        return '';
      }
      rethrow;
    }

    return _client.storage.from(bucket).getPublicUrl(objectPath);
  }

  bool _isMissingColumnError(Object error) {
    if (error is! PostgrestException) return false;

    final code = error.code?.toUpperCase();
    if (code == 'PGRST204' || code == '42703') {
      return true;
    }

    final text = [
      error.message,
      error.details,
      error.hint,
    ].whereType<String>().join(' ').toLowerCase();
    return text.contains('column') && text.contains('does not exist');
  }

  bool _isStorageBucketMissing(Object error) {
    if (error is! StorageException) return false;
    final text = error.toString().toLowerCase();
    return text.contains('bucket') &&
        (text.contains('not found') || text.contains('does not exist'));
  }

  bool _isStorageObjectMissing(Object error) {
    if (error is! StorageException) return false;
    final text = error.toString().toLowerCase();
    return text.contains('not found') || text.contains('does not exist');
  }
}

class _StorageRef {
  const _StorageRef({required this.bucket, required this.path});

  final String bucket;
  final String path;
}

class _UploadedDogImage {
  const _UploadedDogImage({required this.storageRef, required this.displayUrl});

  final String storageRef;
  final String displayUrl;
}

final dogRemoteRepositoryProvider = Provider<DogRemoteRepository>((ref) {
  final client = Supabase.instance.client;
  return DogRemoteRepository(client);
});
