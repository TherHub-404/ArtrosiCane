import 'dart:async';

import 'package:artrosi_cane/core/bootstrap/app_bootstrap.dart';
import 'package:artrosi_cane/core/logging/app_logger.dart';
import 'package:artrosi_cane/core/providers/shared_prefs_provider.dart';
import 'package:artrosi_cane/core/providers/supabase_provider.dart';
import 'package:artrosi_cane/features/auth/data/auth_repository.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:artrosi_cane/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps the app body and reacts whenever the current Supabase user is
/// removed (hard delete, soft delete, or session invalidation): clears local
/// state and routes to /auth so the user has to log in again.
class SessionGuard extends ConsumerStatefulWidget {
  const SessionGuard({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends ConsumerState<SessionGuard>
    with WidgetsBindingObserver {
  StreamSubscription<AuthState>? _authSub;
  RealtimeChannel? _profileChannel;
  String? _watchedUserId;
  bool _isHandlingDeletion = false;
  bool _wired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _wireOnceWhenReady() {
    if (_wired) return;
    final client = maybeSupabaseClient();
    if (client == null) return;
    _wired = true;
    _authSub = client.auth.onAuthStateChange.listen(_handleAuthEvent);
    _watchProfile(client.auth.currentUser?.id);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    _disposeProfileChannel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _wired) {
      _verifySessionOnResume();
    }
  }

  void _handleAuthEvent(AuthState data) {
    final event = data.event;
    final userId = data.session?.user.id;
    switch (event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
      case AuthChangeEvent.initialSession:
        _watchProfile(userId);
        break;
      case AuthChangeEvent.signedOut:
        _disposeProfileChannel();
        _watchedUserId = null;
        _redirectToAuth();
        break;
      default:
        break;
    }
  }

  void _watchProfile(String? userId) {
    if (userId == null) {
      _disposeProfileChannel();
      _watchedUserId = null;
      return;
    }
    if (_watchedUserId == userId && _profileChannel != null) return;

    _disposeProfileChannel();
    _watchedUserId = userId;

    final client = ref.read(supabaseClientProvider);
    final channel = client.channel('session_guard_profile_$userId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'profiles',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: userId,
      ),
      callback: _onProfileUpdate,
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'profiles',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: userId,
      ),
      callback: _onProfileDelete,
    );

    channel.subscribe((status, error) {
      if (error != null) {
        AppLogger.debug('SessionGuard channel error: $error');
      }
    });

    _profileChannel = channel;
  }

  void _onProfileUpdate(PostgresChangePayload payload) {
    final newRecord = payload.newRecord;
    final isDeleted = newRecord['is_deleted'];
    final deletedAt = newRecord['deleted_at'];
    final status = newRecord['status'];
    final active = newRecord['active'];

    final markedDeleted =
        (isDeleted is bool && isDeleted) ||
        (deletedAt != null && deletedAt.toString().isNotEmpty) ||
        (status is String && status.toLowerCase() == 'deleted') ||
        (active is bool && !active);

    if (markedDeleted) {
      _handleDeletion(reason: 'profile_soft_deleted');
    }
  }

  void _onProfileDelete(PostgresChangePayload _) {
    _handleDeletion(reason: 'profile_hard_deleted');
  }

  Future<void> _verifySessionOnResume() async {
    if (_isHandlingDeletion) return;
    final repo = ref.read(authRepositoryProvider);
    try {
      final softDeleted = await repo.signOutIfCurrentUserSoftDeleted();
      if (softDeleted) {
        await _handleDeletion(reason: 'profile_soft_deleted_on_resume');
        return;
      }
      final hardDeleted = await repo.signOutIfCurrentUserHardDeleted();
      if (hardDeleted) {
        await _handleDeletion(reason: 'session_invalid_on_resume');
      }
    } catch (error, stackTrace) {
      AppLogger.debug(
        'SessionGuard resume verification failed: $error\n$stackTrace',
      );
    }
  }

  Future<void> _handleDeletion({required String reason}) async {
    if (_isHandlingDeletion) return;
    _isHandlingDeletion = true;

    AppLogger.debug('SessionGuard triggered sign-out: $reason');

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      'postAuthInfoMessage',
      AppLocalizations.current.text(
        'Il tuo account non e piu attivo. Accedi di nuovo per continuare.',
      ),
    );
    final repo = ref.read(authRepositoryProvider);
    await repo.signOutAndClearLocalState(prefs);

    _disposeProfileChannel();
    _watchedUserId = null;

    _redirectToAuth();
    _isHandlingDeletion = false;
  }

  void _redirectToAuth() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final router = ref.read(appRouterProvider);
        router.go('/auth');
      } catch (error) {
        AppLogger.debug('SessionGuard router redirect failed: $error');
      }
    });
  }

  void _disposeProfileChannel() {
    final ch = _profileChannel;
    if (ch == null) return;
    try {
      ref.read(supabaseClientProvider).removeChannel(ch);
    } catch (_) {
      // Channel may already be gone.
    }
    _profileChannel = null;
  }

  @override
  Widget build(BuildContext context) {
    // Wire listeners only after bootstrap (which calls Supabase.initialize)
    // has completed. Reading Supabase.instance before that throws.
    final bootstrap = ref.watch(appBootstrapProvider);
    if (bootstrap.hasValue) {
      _wireOnceWhenReady();
    }
    return widget.child;
  }
}
