import 'package:artrosi_cane/core/config/app_config.dart';
import 'package:artrosi_cane/core/providers/supabase_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  Future<void> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      clientId: _googleClientIdForCurrentPlatform(),
      serverClientId: AppConfig.googleWebClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('Accesso Google annullato');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AuthException(
        'Token Google non disponibile (idToken). Verifica client ID iOS/web.',
      );
    }
    if (accessToken == null || accessToken.isEmpty) {
      throw const AuthException(
        'Token Google non disponibile (accessToken). Verifica la configurazione Google.',
      );
    }

    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    final user = response.user ?? _client.auth.currentUser;
    final userId = user?.id;
    if (userId == null) {
      throw const AuthException('Accesso Google fallito, nessuna sessione');
    }

    await _upsertProfile(
      id: userId,
      email: user?.email ?? googleUser.email,
      nickname: _extractNickname(user?.userMetadata) ?? googleUser.displayName,
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
    for (final key in const ['nickname', 'full_name', 'name']) {
      final value = metadata[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String? _googleClientIdForCurrentPlatform() {
    if (kIsWeb) {
      return null;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppConfig.googleIosClientId;
    }
    return null;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});
