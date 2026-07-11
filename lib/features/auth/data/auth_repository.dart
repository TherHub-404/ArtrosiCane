import 'dart:convert';

import 'package:artrosi_cane/core/config/app_config.dart';
import 'package:artrosi_cane/core/providers/supabase_provider.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;
  bool _didFreshStartCurrentUser = false;

  String _t(String key, [Map<String, String> params = const {}]) =>
      AppLocalizations.current.text(key, params);

  Future<void> signUp({
    required String email,
    required String password,
    String? nickname,
  }) async {
    _didFreshStartCurrentUser = false;
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: nickname != null && nickname.isNotEmpty
            ? {'nickname': nickname}
            : null,
      );
      final userId = response.user?.id;
      if (userId == null) {
        throw const AuthException(
          'Registrazione fallita, nessun utente creato',
        );
      }

      await _prepareFreshStartIfProfileSoftDeleted(
        userId: userId,
        email: email,
        nickname: nickname,
      );
      await _upsertProfile(id: userId, email: email, nickname: nickname);
    } on AuthException catch (error) {
      if (!_isAlreadyRegisteredError(error)) {
        rethrow;
      }

      await signIn(email: email, password: password);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    _didFreshStartCurrentUser = false;
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    final userId = user?.id;
    if (userId == null) {
      throw AuthException(_t('Accesso fallito, nessuna sessione'));
    }

    await _prepareFreshStartIfProfileSoftDeleted(
      userId: userId,
      email: email,
      nickname: _extractNickname(user?.userMetadata),
    );
    await _upsertProfile(
      id: userId,
      email: email,
      nickname: _extractNickname(user?.userMetadata),
    );
  }

  Future<void> signInWithGoogle() async {
    _didFreshStartCurrentUser = false;
    try {
      final googleSignIn = GoogleSignIn(
        clientId: _googleClientIdForCurrentPlatform(),
        serverClientId: AppConfig.googleWebClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException(_t('Accesso Google annullato'));
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      if (idToken == null || idToken.isEmpty) {
        throw AuthException(
          _t(
            'Token Google non disponibile (idToken). Verifica client ID Android/iOS e Web client ID del progetto.',
          ),
        );
      }
      if (accessToken == null || accessToken.isEmpty) {
        throw AuthException(
          _t(
            'Token Google non disponibile (accessToken). Verifica la configurazione Google Sign-In del progetto.',
          ),
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
        throw AuthException(_t('Accesso Google fallito, nessuna sessione'));
      }

      final nickname =
          _extractNickname(user?.userMetadata) ?? googleUser.displayName;
      final avatarUrl =
          _extractAvatar(user?.userMetadata) ?? googleUser.photoUrl;

      await _prepareFreshStartIfProfileSoftDeleted(
        userId: userId,
        email: user?.email ?? googleUser.email,
        nickname: nickname,
      );
      await _upsertProfile(
        id: userId,
        email: user?.email ?? googleUser.email,
        nickname: nickname,
      );
      await _updateAuthMetadata(nickname: nickname, avatarUrl: avatarUrl);
    } on AuthException {
      rethrow;
    } on PlatformException catch (error) {
      throw _googleAuthExceptionFromMessage(
        '${error.code} ${error.message ?? ''}'.trim(),
      );
    } catch (error) {
      throw _googleAuthExceptionFromMessage(error.toString());
    }
  }

  Future<void> signInWithApple() async {
    _didFreshStartCurrentUser = false;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      throw AuthException(_t('Accesso Apple disponibile solo su iOS'));
    }

    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw AuthException(
          _t(
            'Accesso Apple non disponibile su questo dispositivo o simulatore. Prova su un iPhone reale e verifica che la capability "Sign In with Apple" sia attiva in Xcode e nell\'App ID Apple.',
          ),
        );
      }

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
        throw AuthException(_t('Token Apple non disponibile (identityToken).'));
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      final user = response.user ?? _client.auth.currentUser;
      final userId = user?.id;
      if (userId == null) {
        throw AuthException(_t('Accesso Apple fallito, nessuna sessione'));
      }

      final email = user?.email ?? credential.email;
      if (email == null || email.isEmpty) {
        throw AuthException(_t('Email Apple non disponibile.'));
      }

      final nickname =
          _extractNickname(user?.userMetadata) ?? _appleDisplayName(credential);
      final avatarUrl = _extractAvatar(user?.userMetadata);

      await _prepareFreshStartIfProfileSoftDeleted(
        userId: userId,
        email: email,
        nickname: nickname,
      );
      await _upsertProfile(id: userId, email: email, nickname: nickname);
      await _updateAuthMetadata(nickname: nickname, avatarUrl: avatarUrl);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AuthException(_t('Accesso Apple annullato'));
      }
      switch (e.code) {
        case AuthorizationErrorCode.failed:
        case AuthorizationErrorCode.unknown:
        case AuthorizationErrorCode.notInteractive:
          throw AuthException(
            _t(
              'Accesso Apple non riuscito. Su simulatore iOS questo flusso puo fallire anche con configurazione corretta. Prova su un iPhone reale. Se il problema resta, verifica la capability "Sign In with Apple" in Xcode e nell\'App ID Apple.',
            ),
          );
        case AuthorizationErrorCode.invalidResponse:
        case AuthorizationErrorCode.notHandled:
          throw AuthException(
            _t(
              'Accesso Apple fallito: risposta non valida dal servizio Apple. {{message}}',
              {'message': e.message},
            ),
          );
        case AuthorizationErrorCode.canceled:
          throw AuthException(_t('Accesso Apple annullato'));
      }
    } on SignInWithAppleNotSupportedException {
      throw AuthException(
        _t(
          'Accesso Apple non supportato in questo ambiente. Prova su un iPhone reale e verifica la configurazione Apple del progetto.',
        ),
      );
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
      throw AuthException(_t('Compila tutti i campi prima di prenotare.'));
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
      throw AuthException(
        _t('Prenotazione non disponibile in questo momento. Riprova a breve.'),
      );
    }
  }

  Future<void> softDeleteAccountWithDogs() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw AuthException(_t('Utente non autenticato'));
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

  Future<bool> signOutIfCurrentUserSoftDeleted() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final isSoftDeleted = await _isProfileSoftDeleted(userId);
    if (!isSoftDeleted) return false;
    await _client.auth.signOut();
    return true;
  }

  /// Verifies the server still knows the current user. Returns true if the
  /// user has been hard-deleted (or the session is otherwise invalid) and we
  /// have signed out as a result.
  Future<bool> signOutIfCurrentUserHardDeleted() async {
    if (_client.auth.currentUser == null) return false;
    try {
      await _client.auth.getUser();
      return false;
    } on AuthException {
      try {
        await _client.auth.signOut();
      } catch (_) {
        // Already gone server-side — local cleanup is what matters.
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static const List<String> _localUserStateKeys = <String>[
    'onboardingCompleted',
    'dogProfile',
    'quizProgress',
    'lastResult',
    'lastResultSyncedSignature',
    'lastUserId',
  ];

  /// Wipes user-scoped local state and signs out from Supabase.
  Future<void> signOutAndClearLocalState(SharedPreferences prefs) async {
    for (final key in _localUserStateKeys) {
      await prefs.remove(key);
    }
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Already signed out / session not available — local cleanup done.
    }
  }

  bool consumeFreshStartFlag() {
    final value = _didFreshStartCurrentUser;
    _didFreshStartCurrentUser = false;
    return value;
  }

  /// Returns true when the current user's profile row is marked as a
  /// website-migrated account that still has a temporary password. The flag
  /// is cleared by [finalizeMigratedPassword] once the user chooses a new
  /// permanent password.
  Future<bool> isCurrentUserWebMigrated() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final row = await _client
          .from('profiles')
          .select('is_web_migrated')
          .eq('auth_user_id', userId)
          .maybeSingle();
      if (row is! Map<String, dynamic>) return false;
      final flag = row['is_web_migrated'];
      return flag is bool && flag;
    } catch (error) {
      if (_isMissingColumnError(error) || _isMissingSchemaObjectError(error)) {
        return false;
      }
      return false;
    }
  }

  /// Sets a new permanent password for a user who logged in with the
  /// temporary, website-migrated password and clears the `is_web_migrated`
  /// flag so future logins skip this step.
  Future<void> finalizeMigratedPassword({required String newPassword}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw AuthException(_t('Utente non autenticato'));
    }

    await _client.auth.updateUser(UserAttributes(password: newPassword));

    try {
      await _client
          .from('profiles')
          .update({'is_web_migrated': false})
          .eq('auth_user_id', userId);
    } catch (error) {
      if (_isMissingColumnError(error) || _isMissingSchemaObjectError(error)) {
        return;
      }
      rethrow;
    }
  }

  /// Calls the Postgres `claim_profile` RPC which:
  /// - returns the profile.id of the row owned by `auth.uid()`, after
  ///   either binding a website-pre-populated row (matched by email)
  ///   or creating a new row.
  /// Idempotent.
  Future<String?> claimProfile() async {
    try {
      final result = await _client.rpc('claim_profile');
      if (result is String && result.isNotEmpty) return result;
      return null;
    } catch (error) {
      // Non-blocking: if RPC fails (network, permissions), the existing
      // app flow will still work via _upsertProfile.
      return null;
    }
  }

  Future<void> _upsertProfile({
    required String id,
    required String email,
    String? nickname,
  }) async {
    // Bind any pre-populated profile row to this auth user (or create
    // a fresh one with id = auth.uid()).
    await claimProfile();

    // Then patch nickname if explicitly provided. We never overwrite an
    // existing remote nickname with NULL/empty (so values pre-populated
    // by the marketing website are preserved).
    if (nickname != null && nickname.isNotEmpty) {
      try {
        await _client
            .from('profiles')
            .update({'nickname': nickname})
            .eq('auth_user_id', id);
      } catch (_) {
        // Non-blocking nickname patch.
      }
    }
  }

  Future<void> _prepareFreshStartIfProfileSoftDeleted({
    required String userId,
    required String email,
    String? nickname,
  }) async {
    final isSoftDeleted = await _isProfileSoftDeleted(userId);
    if (!isSoftDeleted) return;

    await _softDeleteRows(
      table: 'dogs',
      filters: {'owner_id': userId},
      deletedAt: DateTime.now().toUtc().toIso8601String(),
    );
    await _purgeUserAppData(userId);
    await _restoreProfileAsFreshStart(
      userId: userId,
      email: email,
      nickname: nickname,
    );
    _didFreshStartCurrentUser = true;
  }

  Future<bool> _isProfileSoftDeleted(String userId) async {
    final queryAttempts = <Future<dynamic> Function()>[
      () => _client
          .from('profiles')
          .select('is_deleted, deleted_at')
          .eq('id', userId)
          .maybeSingle(),
      () => _client
          .from('profiles')
          .select('status')
          .eq('id', userId)
          .maybeSingle(),
      () => _client
          .from('profiles')
          .select('active')
          .eq('id', userId)
          .maybeSingle(),
    ];

    for (final attempt in queryAttempts) {
      try {
        final row = await attempt();
        if (row is! Map<String, dynamic>) return false;
        final isDeleted = row['is_deleted'];
        if (isDeleted is bool && isDeleted) return true;
        if (row['deleted_at'] != null) return true;
        final status = row['status'];
        if (status is String && status.toLowerCase() == 'deleted') return true;
        final active = row['active'];
        if (active is bool && !active) return true;
        return false;
      } catch (error) {
        if (!_isMissingColumnError(error)) {
          rethrow;
        }
      }
    }

    return false;
  }

  Future<void> _purgeUserAppData(String userId) async {
    final resultIds = await _loadQuizResultIds(userId);
    if (resultIds.isNotEmpty) {
      await _deleteRowsByOrFilter(
        table: 'quiz_answers',
        column: 'result_id',
        ids: resultIds,
      );
    }

    await _deleteRows(table: 'quiz_results', filters: {'owner_id': userId});
    await _deleteRows(table: 'app_events', filters: {'owner_id': userId});
    await _deleteRows(table: 'daily_logs', filters: {'owner_id': userId});
  }

  Future<List<String>> _loadQuizResultIds(String userId) async {
    try {
      final rows = await _client
          .from('quiz_results')
          .select('id')
          .eq('owner_id', userId);
      return (rows as List<dynamic>)
          .map((row) => (row as Map<String, dynamic>)['id'] as String?)
          .whereType<String>()
          .toList();
    } catch (error) {
      if (_isMissingSchemaObjectError(error)) {
        return const <String>[];
      }
      rethrow;
    }
  }

  Future<void> _deleteRows({
    required String table,
    required Map<String, dynamic> filters,
  }) async {
    try {
      dynamic query = _client.from(table).delete();
      filters.forEach((column, value) {
        query = query.eq(column, value);
      });
      await query;
    } catch (error) {
      if (_isMissingSchemaObjectError(error)) {
        return;
      }
      rethrow;
    }
  }

  Future<void> _deleteRowsByOrFilter({
    required String table,
    required String column,
    required List<String> ids,
  }) async {
    if (ids.isEmpty) return;
    try {
      final filter = ids.map((id) => '$column.eq.$id').join(',');
      await _client.from(table).delete().or(filter);
    } catch (error) {
      if (_isMissingSchemaObjectError(error)) {
        return;
      }
      rethrow;
    }
  }

  Future<void> _restoreProfileAsFreshStart({
    required String userId,
    required String email,
    String? nickname,
  }) async {
    final basePayload = <String, dynamic>{
      'id': userId,
      'auth_user_id': userId,
      'email': email,
      'nickname': nickname,
    }..removeWhere((key, value) => value == null);

    final payloadAttempts = <Map<String, dynamic>>[
      {...basePayload, 'is_deleted': false, 'deleted_at': null},
      {...basePayload, 'is_deleted': false},
      {...basePayload, 'deleted_at': null},
      {...basePayload, 'status': 'active'},
      {...basePayload, 'active': true},
      basePayload,
    ];

    for (final payload in payloadAttempts) {
      try {
        await _client.from('profiles').upsert(payload);
        return;
      } catch (error) {
        if (!_isMissingColumnError(error)) {
          rethrow;
        }
      }
    }
  }

  bool _isAlreadyRegisteredError(AuthException error) {
    final text = error.message.toLowerCase();
    return text.contains('already registered') ||
        text.contains('already been registered') ||
        text.contains('user already registered') ||
        text.contains('already exists');
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

  AuthException _googleAuthExceptionFromMessage(String rawMessage) {
    final message = rawMessage.trim();
    final normalized = message.toLowerCase();

    if (normalized.contains('canceled') ||
        normalized.contains('cancelled') ||
        normalized.contains('sign_in_canceled') ||
        normalized.contains('12501')) {
      return AuthException(_t('Accesso Google annullato'));
    }

    if (normalized.contains('network') ||
        normalized.contains('socketexception') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('timeout')) {
      return AuthException(
        _t(
          'Accesso Google non riuscito per un problema di connessione. Controlla la rete e riprova.',
        ),
      );
    }

    if (normalized.contains('10') ||
        normalized.contains('developer_error') ||
        normalized.contains('12500') ||
        normalized.contains('api exception: 10') ||
        normalized.contains(
          'com.google.android.gms.common.api.apiexception: 10',
        )) {
      return AuthException(
        _t(
          'Accesso Google non disponibile. Verifica la configurazione Android del progetto: SHA-1/SHA-256, package name e Web client ID associato a Google Sign-In.',
        ),
      );
    }

    if (normalized.contains('sign_in_failed') ||
        normalized.contains('clientconfigurationerror') ||
        normalized.contains('invalid_audience') ||
        normalized.contains('id token')) {
      return AuthException(
        _t(
          'Accesso Google non riuscito. La configurazione di Google Sign-In sembra incompleta o non valida. Controlla client ID, file di configurazione e impostazioni Firebase/Google Cloud.',
        ),
      );
    }

    if (normalized.contains('play services') ||
        normalized.contains('service_missing') ||
        normalized.contains('service_version_update_required') ||
        normalized.contains('service_disabled')) {
      return AuthException(
        _t(
          'Accesso Google non disponibile su questo dispositivo. Controlla che Google Play Services sia installato e aggiornato, oppure prova su un altro dispositivo Android.',
        ),
      );
    }

    return AuthException(
      _t(
        'Accesso Google non riuscito. Se il problema resta, verifica la configurazione Google del progetto e riprova. Dettagli: {{message}}',
        {'message': message},
      ),
    );
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
    return _t('Non siamo riusciti a prenotare la videocall. Riprova tra poco.');
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
      _t(
        'Soft delete non supportata sulla tabella "{{table}}". Aggiungi almeno una colonna tra deleted_at o is_deleted.',
        {'table': table},
      ),
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

  bool _isMissingSchemaObjectError(Object error) {
    if (_isMissingColumnError(error)) return true;
    if (error is! PostgrestException) return false;

    final code = error.code?.toUpperCase();
    if (code == '42P01' || code == 'PGRST205') {
      return true;
    }

    final text = [
      error.message,
      error.details,
      error.hint,
    ].whereType<String>().join(' ').toLowerCase();
    return (text.contains('relation') && text.contains('does not exist')) ||
        (text.contains('could not find') && text.contains('schema cache'));
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});
