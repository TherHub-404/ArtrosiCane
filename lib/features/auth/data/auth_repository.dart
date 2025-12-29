import 'package:artrosi_cane/core/providers/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  /// Returns true if email confirmation is required (no session created).
  Future<bool> signUp({
    required String email,
    required String password,
    String? nickname,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: nickname != null && nickname.isNotEmpty ? {'nickname': nickname} : null,
    );
    final userId = response.user?.id;
    if (userId == null) {
      throw const AuthException('Registrazione fallita, nessun utente creato');
    }

    if (response.session != null) {
      await _upsertProfile(
        id: userId,
        email: email,
        nickname: nickname,
      );
    }

    return response.session == null;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(email: email, password: password);
    final user = response.user;
    final userId = user?.id;
    if (userId == null) {
      throw const AuthException('Accesso fallito, nessuna sessione');
    }

    await _upsertProfile(
      id: userId,
      email: email,
      nickname: _extractNickname(user?.userMetadata),
    );
  }

  Future<void> _upsertProfile({
    required String id,
    required String email,
    String? nickname,
  }) async {
    await _client.from('profiles').upsert({
      'id': id,
      'email': email,
      if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
    });
  }

  String? _extractNickname(Map<String, dynamic>? metadata) {
    if (metadata == null) return null;
    final value = metadata['nickname'];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});
