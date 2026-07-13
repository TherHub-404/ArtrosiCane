import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:artrosi_cane/core/config/app_config.dart';
import 'package:artrosi_cane/core/linking/feature_flags_controller.dart';
import 'package:artrosi_cane/core/logging/app_logger.dart';
import 'package:artrosi_cane/core/providers/shared_prefs_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _deepLinkChannelName = 'com.company.app/deeplink';
const _deviceIdStorageKey = 'invite_device_id';
const _installReferrerConsumedKey = 'install_referrer_consumed';

final linkServiceProvider = Provider<LinkService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final flagsController = ref.read(featureFlagsControllerProvider.notifier);

  final service = LinkService(
    appLinks: AppLinks(),
    methodChannel: const MethodChannel(_deepLinkChannelName),
    httpClient: http.Client(),
    prefs: prefs,
    flagsController: flagsController,
    apiBaseUrl: AppConfig.inviteApiBaseUrl,
    inviteHost: AppConfig.inviteDomain,
    invitePath: AppConfig.invitePath,
  );

  ref.onDispose(service.dispose);
  return service;
});

class LinkService {
  LinkService({
    required AppLinks appLinks,
    required MethodChannel methodChannel,
    required http.Client httpClient,
    required SharedPreferences prefs,
    required FeatureFlagsController flagsController,
    required String apiBaseUrl,
    required String inviteHost,
    required String invitePath,
  }) : _appLinks = appLinks,
       _methodChannel = methodChannel,
       _httpClient = httpClient,
       _prefs = prefs,
       _flagsController = flagsController,
       _apiBaseUri = Uri.parse(apiBaseUrl),
       _inviteHost = inviteHost.toLowerCase(),
       _invitePath = _normalizePath(invitePath);

  static const Set<String> _appleAppClipHosts = <String>{
    'appclip.apple.com',
    'apps.apple.com',
  };

  final AppLinks _appLinks;
  final MethodChannel _methodChannel;
  final http.Client _httpClient;
  final SharedPreferences _prefs;
  final FeatureFlagsController _flagsController;
  final Uri _apiBaseUri;
  final String _inviteHost;
  final String _invitePath;

  final Set<String> _inFlightTokens = <String>{};

  StreamSubscription<Uri>? _linkSub;
  bool _started = false;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;

    _methodChannel.setMethodCallHandler(_handleMethodChannelCall);

    await _refreshFromStoredToken();
    await _consumeBufferedNativeLinks();
    await _consumeInitialAppLinks();
    await _consumePlayInstallReferrer();

    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) => _handleIncomingUrl(uri.toString(), source: 'app_links_stream'),
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.debug('uriLinkStream error: $error');
      },
    );
  }

  Future<void> _consumePlayInstallReferrer() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    if (_prefs.getBool(_installReferrerConsumedKey) == true) {
      return;
    }

    try {
      final details = await PlayInstallReferrer.installReferrer;
      final raw = details.installReferrer?.trim();
      await _prefs.setBool(_installReferrerConsumedKey, true);

      if (raw == null || raw.isEmpty) {
        return;
      }

      final params = Uri.splitQueryString(raw);
      final token = params['token']?.trim();
      final location = params['location']?.trim().toLowerCase();

      if ((token == null || token.isEmpty) &&
          (location == null || location.isEmpty)) {
        return;
      }

      if (location != null && location.isNotEmpty) {
        await _flagsController.persistInviteLocationFromLink(location);
      }
      if (token != null && token.isNotEmpty) {
        await _syncToken(token, source: 'play_install_referrer');
      }
    } catch (error) {
      AppLogger.debug('Play install referrer unavailable: $error');
    }
  }

  Future<void> dispose() async {
    await _linkSub?.cancel();
    _httpClient.close();
  }

  Future<dynamic> _handleMethodChannelCall(MethodCall call) async {
    if (call.method != 'onDeepLink') {
      return null;
    }

    final args = call.arguments;
    if (args is! String || args.isEmpty) {
      return null;
    }

    await _handleIncomingUrl(args, source: 'ios_method_channel');
    return null;
  }

  Future<void> _consumeBufferedNativeLinks() async {
    try {
      final links = await _methodChannel.invokeListMethod<dynamic>(
        'consumeInitialLinks',
      );
      if (links == null) {
        return;
      }

      for (final link in links) {
        if (link is String && link.isNotEmpty) {
          await _handleIncomingUrl(link, source: 'ios_buffered');
        }
      }
    } catch (error) {
      AppLogger.debug('Unable to consume buffered native links: $error');
    }
  }

  Future<void> _consumeInitialAppLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri == null) {
        return;
      }

      await _handleIncomingUrl(
        initialUri.toString(),
        source: 'app_links_initial',
      );
    } catch (error) {
      AppLogger.debug('Unable to get initial app link: $error');
    }
  }

  Future<void> _refreshFromStoredToken() async {
    final storedToken = _flagsController.getStoredToken();
    if (storedToken == null) {
      return;
    }

    await _syncToken(storedToken, source: 'startup_stored_token');
  }

  Future<void> _handleIncomingUrl(
    String rawUrl, {
    required String source,
  }) async {
    final inviteLink = _parseInviteLink(rawUrl);
    if (inviteLink == null) {
      AppLogger.debug(
        'Ignored deep link (not matching invite format): $rawUrl',
      );
      return;
    }

    await _flagsController.persistInviteLocationFromLink(inviteLink.location);

    if (inviteLink.token == null || inviteLink.token!.isEmpty) {
      AppLogger.debug('Invite context updated without token ($source)');
      return;
    }

    await _syncToken(inviteLink.token!, source: source);
  }

  Future<void> _syncToken(String token, {required String source}) async {
    if (_inFlightTokens.contains(token)) {
      return;
    }

    _inFlightTokens.add(token);
    _flagsController.setLoading(true);

    try {
      final flags = await _redeemOrFetchFlags(token);
      await _flagsController.persistFlags(token: token, flags: flags);
      AppLogger.debug('Flags updated for token ($source)');
    } catch (error) {
      _flagsController.setError(
        'Unable to refresh feature flags',
        token: token,
      );
      AppLogger.debug('Token sync failed ($source): $error');
    } finally {
      _flagsController.setLoading(false);
      _inFlightTokens.remove(token);
    }
  }

  _ParsedInviteLink? _parseInviteLink(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      return null;
    }

    if (uri.scheme.toLowerCase() != 'https') {
      return null;
    }

    if (uri.host.toLowerCase() != _inviteHost) {
      final normalizedHost = uri.host.toLowerCase();
      if (!_appleAppClipHosts.contains(normalizedHost) ||
          !_isRecognizedAppleAppClipLink(uri)) {
        return null;
      }

      final token = (uri.queryParameters['t'] ?? uri.queryParameters['token'])
          ?.trim();
      final location =
          (uri.queryParameters['location'] ?? uri.queryParameters['loc'])
              ?.trim()
              .toLowerCase();

      if ((token == null || token.isEmpty) &&
          (location == null || location.isEmpty)) {
        return null;
      }

      return _ParsedInviteLink(
        token: (token == null || token.isEmpty) ? null : token,
        location: (location == null || location.isEmpty) ? null : location,
      );
    }

    final normalizedPath = _normalizePath(uri.path);
    final isInviteRoot = normalizedPath == _invitePath;
    final isInviteSubpath = normalizedPath.startsWith('$_invitePath/');
    if (!isInviteRoot && !isInviteSubpath) {
      return null;
    }

    String? token = (uri.queryParameters['t'] ?? uri.queryParameters['token'])
        ?.trim();
    String? location =
        (uri.queryParameters['location'] ?? uri.queryParameters['loc'])
            ?.trim()
            .toLowerCase();

    // Fallback: support path-based format /i/{token}/{location?}
    if ((token == null || token.isEmpty) && isInviteSubpath) {
      final inviteSegments = _invitePath
          .split('/')
          .where((segment) => segment.isNotEmpty)
          .length;
      final tailSegments = uri.pathSegments.skip(inviteSegments).toList();
      if (tailSegments.isNotEmpty) {
        token = Uri.decodeComponent(tailSegments.first).trim();
      }
      if ((location == null || location.isEmpty) && tailSegments.length > 1) {
        location = Uri.decodeComponent(tailSegments[1]).trim().toLowerCase();
      }
    }

    if ((token == null || token.isEmpty) &&
        (location == null || location.isEmpty)) {
      return null;
    }

    return _ParsedInviteLink(
      token: (token == null || token.isEmpty) ? null : token,
      location: (location == null || location.isEmpty) ? null : location,
    );
  }

  bool _isRecognizedAppleAppClipLink(Uri uri) {
    final bundleId =
        (uri.queryParameters['p'] ?? uri.queryParameters['app-clip-bundle-id'])
            ?.trim()
            .toLowerCase();
    if (bundleId == null || bundleId.isEmpty) {
      return false;
    }
    return bundleId == 'com.artrosicase.artrosicane.clip';
  }

  Future<Map<String, dynamic>> _redeemOrFetchFlags(String token) async {
    final redeemUri = _endpointUri('/redeem');
    final deviceId = await _getOrCreateDeviceId();
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final redeemResponse = await _httpClient
        .post(
          redeemUri,
          headers: headers,
          body: jsonEncode(<String, dynamic>{
            'token': token,
            'deviceId': deviceId,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (_isSuccess(redeemResponse.statusCode)) {
      final payload = _decodeJsonMap(redeemResponse.body);
      return _extractFlags(payload);
    }

    if (<int>{400, 404, 409, 410, 422}.contains(redeemResponse.statusCode)) {
      return _fetchFlags(token);
    }

    throw StateError('Redeem failed with HTTP ${redeemResponse.statusCode}');
  }

  Future<Map<String, dynamic>> _fetchFlags(String token) async {
    final flagsUri = _endpointUri(
      '/flags',
      queryParameters: <String, String>{'token': token},
    );
    final response = await _httpClient
        .get(
          flagsUri,
          headers: const <String, String>{'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    if (!_isSuccess(response.statusCode)) {
      throw StateError('Flags fetch failed with HTTP ${response.statusCode}');
    }

    final payload = _decodeJsonMap(response.body);
    return _extractFlags(payload);
  }

  Future<String> _getOrCreateDeviceId() async {
    final existing = _prefs.getString(_deviceIdStorageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final id = const Uuid().v4();
    await _prefs.setString(_deviceIdStorageKey, id);
    return id;
  }

  Map<String, dynamic> _decodeJsonMap(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }

    throw const FormatException('Expected JSON object response');
  }

  Map<String, dynamic> _extractFlags(Map<String, dynamic> payload) {
    final rawFlags = payload['flags'] ?? payload;
    if (rawFlags is! Map) {
      throw const FormatException('Missing "flags" object in backend response');
    }

    return rawFlags.map((key, value) => MapEntry(key.toString(), value));
  }

  Uri _endpointUri(String endpoint, {Map<String, String>? queryParameters}) {
    final normalizedBasePath = _apiBaseUri.path.endsWith('/')
        ? _apiBaseUri.path.substring(0, _apiBaseUri.path.length - 1)
        : _apiBaseUri.path;
    final normalizedEndpoint = endpoint.startsWith('/')
        ? endpoint
        : '/$endpoint';

    return _apiBaseUri.replace(
      path: '$normalizedBasePath$normalizedEndpoint',
      queryParameters: queryParameters,
    );
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  static String _normalizePath(String path) {
    if (path.isEmpty) {
      return '/';
    }
    final withLeadingSlash = path.startsWith('/') ? path : '/$path';
    if (withLeadingSlash.length > 1 && withLeadingSlash.endsWith('/')) {
      return withLeadingSlash.substring(0, withLeadingSlash.length - 1);
    }
    return withLeadingSlash;
  }
}

class _ParsedInviteLink {
  const _ParsedInviteLink({required this.token, required this.location});

  final String? token;
  final String? location;
}
