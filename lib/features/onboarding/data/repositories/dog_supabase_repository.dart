import 'dart:io';
import 'dart:typed_data';

import 'package:artrosi_cane/features/onboarding/domain/entities/dog_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class DogSupabaseRepository {
  DogSupabaseRepository(this._client);

  final SupabaseClient _client;
  static const String diagnosisFilesBucket = 'dog-diagnosis-files';
  static const String _localDiagnosisRefPrefix = 'local://';
  static const Uuid _uuid = Uuid();

  Future<String?> upsertDog(DogProfile profile) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    if ((profile.name ?? '').trim().isEmpty) return null;
    final diagnosisFiles = await _resolveDiagnosisFiles(
      profile.diagnosisFiles,
      userId: userId,
    );

    final payload = {
      'owner_id': userId,
      'name': profile.name,
      'age_years': profile.ageYears,
      'weight_kg': profile.weightKg,
      'breed_id': profile.breedId,
      'age_group': profile.ageGroup.name,
      'size': profile.size.name,
      'diagnosis_status': profile.diagnosisStatus?.name,
      'diagnosis_answered_at': profile.diagnosisAnsweredAt?.toIso8601String(),
      'diagnosis_date': profile.diagnosisDate,
      'diagnosis_vet': profile.diagnosisVet,
      'diagnosis_files': diagnosisFiles,
      'diagnosis_care_notes': profile.diagnosisCareNotes,
    };

    final profileId = profile.id?.trim();
    if (profileId != null && profileId.isNotEmpty) {
      await _client
          .from('dogs')
          .update(payload)
          .eq('id', profileId)
          .eq('owner_id', userId);
      return profileId;
    }

    final inserted = await _client
        .from('dogs')
        .insert(payload)
        .select('id')
        .maybeSingle();
    return inserted?['id'] as String?;
  }

  Future<void> updateDiagnosisForDog({
    required String dogId,
    required ArthrosisDiagnosisStatus? diagnosisStatus,
    required DateTime? diagnosisAnsweredAt,
    required String? diagnosisDate,
    required String? diagnosisVet,
    required List<String> diagnosisFiles,
    required String? diagnosisCareNotes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    final resolvedFiles = await _resolveDiagnosisFiles(
      diagnosisFiles,
      userId: userId,
    );

    await _client
        .from('dogs')
        .update({
          'diagnosis_status': diagnosisStatus?.name,
          'diagnosis_answered_at': diagnosisAnsweredAt?.toIso8601String(),
          'diagnosis_date': diagnosisDate,
          'diagnosis_vet': diagnosisVet,
          'diagnosis_files': resolvedFiles,
          'diagnosis_care_notes': diagnosisCareNotes,
        })
        .eq('id', dogId)
        .eq('owner_id', userId);
  }

  Future<String> uploadDiagnosisFile({
    required Uint8List bytes,
    required String originalFileName,
  }) async {
    final userId = _client.auth.currentUser?.id;
    final safeFileName = _sanitizeFileName(originalFileName);
    if (userId == null) {
      return _saveDiagnosisFileLocally(
        bytes: bytes,
        safeFileName: safeFileName,
      );
    }

    final objectPath = '$userId/${_uuid.v4()}_$safeFileName';
    await _client.storage
        .from(diagnosisFilesBucket)
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentTypeForName(safeFileName),
          ),
        );
    return objectPath;
  }

  Future<void> deleteDiagnosisFile(String objectPath) async {
    if (_isLocalDiagnosisRef(objectPath)) {
      await _deleteLocalDiagnosisFile(objectPath);
      return;
    }
    await _client.storage.from(diagnosisFilesBucket).remove([objectPath]);
  }

  Future<DogProfile> resolvePendingDiagnosisFiles(DogProfile profile) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return profile;
    if (!profile.diagnosisFiles.any(_isLocalDiagnosisRef)) return profile;
    final resolved = await _resolveDiagnosisFiles(
      profile.diagnosisFiles,
      userId: userId,
    );
    return profile.copyWith(diagnosisFiles: resolved);
  }

  String _sanitizeFileName(String input) {
    final collapsed = input.trim().replaceAll(RegExp(r'\s+'), '_');
    final sanitized = collapsed.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    if (sanitized.isEmpty) {
      return 'file.bin';
    }
    return sanitized;
  }

  String _contentTypeForName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpeg') || lower.endsWith('.jpg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  Future<String> _saveDiagnosisFileLocally({
    required Uint8List bytes,
    required String safeFileName,
  }) async {
    final supportDir = await getApplicationSupportDirectory();
    final stagingDir = Directory('${supportDir.path}/diagnosis-pending-files');
    if (!await stagingDir.exists()) {
      await stagingDir.create(recursive: true);
    }

    final localFile = File('${stagingDir.path}/${_uuid.v4()}_$safeFileName');
    await localFile.writeAsBytes(bytes, flush: true);
    return '$_localDiagnosisRefPrefix${localFile.path}';
  }

  bool _isLocalDiagnosisRef(String ref) {
    return ref.startsWith(_localDiagnosisRefPrefix);
  }

  String _localPathFromRef(String ref) {
    return ref.substring(_localDiagnosisRefPrefix.length);
  }

  Future<void> _deleteLocalDiagnosisFile(String ref) async {
    final localPath = _localPathFromRef(ref).trim();
    if (localPath.isEmpty) return;
    final file = File(localPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  String _extractFileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final chunks = normalized.split('/');
    if (chunks.isEmpty) return 'file.bin';
    final fileName = chunks.last.trim();
    if (fileName.isEmpty) return 'file.bin';
    return fileName;
  }

  Future<List<String>> _resolveDiagnosisFiles(
    List<String> refs, {
    required String userId,
  }) async {
    final resolved = <String>{};
    for (final ref in refs) {
      final candidate = ref.trim();
      if (candidate.isEmpty) continue;

      if (_isLocalDiagnosisRef(candidate)) {
        final localPath = _localPathFromRef(candidate).trim();
        if (localPath.isEmpty) continue;

        final localFile = File(localPath);
        if (!await localFile.exists()) {
          throw Exception('Referto locale non trovato: $localPath');
        }

        final bytes = await localFile.readAsBytes();
        if (bytes.isEmpty) {
          throw Exception('Referto locale vuoto: $localPath');
        }

        final localFileName = _sanitizeFileName(_extractFileName(localPath));
        final objectPath = '$userId/${_uuid.v4()}_$localFileName';
        await _client.storage
            .from(diagnosisFilesBucket)
            .uploadBinary(
              objectPath,
              bytes,
              fileOptions: FileOptions(
                contentType: _contentTypeForName(localFileName),
              ),
            );

        resolved.add(objectPath);

        try {
          await localFile.delete();
        } catch (_) {
          // Non-blocking cleanup.
        }
        continue;
      }

      resolved.add(candidate);
    }
    return resolved.toList();
  }
}

final dogSupabaseRepositoryProvider = Provider<DogSupabaseRepository>((ref) {
  final client = Supabase.instance.client;
  return DogSupabaseRepository(client);
});
