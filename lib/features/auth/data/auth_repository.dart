import 'dart:convert';

import 'package:artrosi_cane/core/config/app_config.dart';
import 'package:artrosi_cane/core/providers/supabase_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
      data: nickname != null && nickname.isNotEmpty
          ? {'nickname': nickname}
          : null,
    );
    final userId = response.user?.id;
    if (userId == null) {
      throw const AuthException('Registrazione fallita, nessun utente creato');
    }

    if (response.session != null) {
      await _upsertProfile(id: userId, email: email, nickname: nickname);
    }

    return response.session == null;
  }

  Future<void> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
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

    final nickname =
        _extractNickname(user?.userMetadata) ?? googleUser.displayName;
    final avatarUrl = _extractAvatar(user?.userMetadata) ?? googleUser.photoUrl;

    await _upsertProfile(
      id: userId,
      email: user?.email ?? googleUser.email,
      nickname: nickname,
    );
    await _updateAuthMetadata(nickname: nickname, avatarUrl: avatarUrl);
  }

  Future<void> signInWithApple() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      throw const AuthException('Accesso Apple disponibile solo su iOS');
    }

    try {
      final rawNonce = _client.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException(
          'Token Apple non disponibile (identityToken).',
        );
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      final user = response.user ?? _client.auth.currentUser;
      final userId = user?.id;
      if (userId == null) {
        throw const AuthException('Accesso Apple fallito, nessuna sessione');
      }

      final email = user?.email ?? credential.email;
      if (email == null || email.isEmpty) {
        throw const AuthException('Email Apple non disponibile.');
      }

      final nickname =
          _extractNickname(user?.userMetadata) ?? _appleDisplayName(credential);
      final avatarUrl = _extractAvatar(user?.userMetadata);

      await _upsertProfile(id: userId, email: email, nickname: nickname);
      await _updateAuthMetadata(nickname: nickname, avatarUrl: avatarUrl);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthException('Accesso Apple annullato');
      }
      throw AuthException('Accesso Apple fallito: ${e.message}');
    }
  }

  Future<void> scheduleVideoCallRequest({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? dogName,
  }) async {
    final normalizedFirstName = firstName.trim();
    final normalizedLastName = lastName.trim();
    final normalizedEmail = email.trim();
    final normalizedPhone = phone.trim();
    final normalizedDogName = dogName?.trim();

    if (normalizedFirstName.isEmpty ||
        normalizedLastName.isEmpty ||
        normalizedEmail.isEmpty ||
        normalizedPhone.isEmpty) {
      throw const AuthException('Compila tutti i campi prima di prenotare.');
    }

    final startAt = DateTime.now().add(const Duration(hours: 2));
    final endAt = startAt.add(const Duration(minutes: 30));

    try {
      final response = await _client.functions.invoke(
        'schedule-video-call',
        body: {
          'firstName': normalizedFirstName,
          'lastName': normalizedLastName,
          'email': normalizedEmail,
          'phone': normalizedPhone,
          'dogName': normalizedDogName,
          'startAt': startAt.toIso8601String(),
          'endAt': endAt.toIso8601String(),
          'timeZone': 'Europe/Rome',
        },
      );

      final status = response.status;
      final data = response.data;
      final hasOkFalse = data is Map && data['ok'] == false;
      if (status < 200 || status >= 300 || hasOkFalse) {
        throw AuthException(_extractBookingError(data));
      }
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        'Prenotazione non disponibile in questo momento. Riprova a breve.',
      );
    }
  }

  Future<void> softDeleteAccountWithDogs() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Utente non autenticato');
    }

    final deletedAt = DateTime.now().toUtc().toIso8601String();

    await _softDeleteRows(
      table: 'dogs',
      filters: {'owner_id': userId},
      deletedAt: deletedAt,
    );
    await _softDeleteRows(
      table: 'profiles',
      filters: {'id': userId},
      deletedAt: deletedAt,
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

  String? _extractAvatar(Map<String, dynamic>? metadata) {
    if (metadata == null) return null;
    for (final key in const [
      'avatar_url',
      'picture',
      'photo_url',
      'avatarUrl',
      'profile_image_url',
      'profileImage',
    ]) {
      final value = metadata[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  Future<void> _updateAuthMetadata({
    String? nickname,
    String? avatarUrl,
  }) async {
    final normalizedNickname = nickname?.trim();
    final normalizedAvatar = avatarUrl?.trim();
    final data = <String, dynamic>{};

    if (normalizedNickname != null && normalizedNickname.isNotEmpty) {
      data['nickname'] = normalizedNickname;
      data['name'] = normalizedNickname;
      data['full_name'] = normalizedNickname;
    }
    if (normalizedAvatar != null && normalizedAvatar.isNotEmpty) {
      data['avatar_url'] = normalizedAvatar;
      data['picture'] = normalizedAvatar;
      data['photo_url'] = normalizedAvatar;
    }
    if (data.isEmpty) return;

    try {
      await _client.auth.updateUser(UserAttributes(data: data));
    } catch (_) {
      // Best effort metadata enrichment.
    }
  }

  String? _appleDisplayName(AuthorizationCredentialAppleID credential) {
    final nameParts = [credential.givenName, credential.familyName]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (nameParts.isEmpty) return null;
    return nameParts.join(' ');
  }

  String? _googleClientIdForCurrentPlatform() {
    if (kIsWeb) {
      return AppConfig.googleWebClientId;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppConfig.googleIosClientId;
    }
    return null;
  }

  String _extractBookingError(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['error'] ?? data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    if (data is String && data.isNotEmpty) {
      return data;
    }
    return 'Non siamo riusciti a prenotare la videocall. Riprova tra poco.';
  }

  Future<void> _softDeleteRows({
    required String table,
    required Map<String, dynamic> filters,
    required String deletedAt,
  }) async {
    final payloadAttempts = <Map<String, dynamic>>[
      {'deleted_at': deletedAt, 'is_deleted': true},
      {'deleted_at': deletedAt},
      {'is_deleted': true},
      {'status': 'deleted'},
      {'active': false},
    ];

    for (final payload in payloadAttempts) {
      try {
        dynamic query = _client.from(table).update(payload);
        filters.forEach((column, value) {
          query = query.eq(column, value);
        });
        await query;
        return;
      } catch (error) {
        if (!_isMissingColumnError(error)) {
          rethrow;
        }
      }
    }

    throw AuthException(
      'Soft delete non supportata sulla tabella "$table". '
      'Aggiungi almeno una colonna tra deleted_at o is_deleted.',
    );
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
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});
