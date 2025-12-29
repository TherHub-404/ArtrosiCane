import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final fileEnv = _loadDotEnv();
  final dogApiKey = _readEnv('DOG_API_KEY', fileEnv);
  final supabaseUrl = _readEnv('SUPABASE_URL', fileEnv);
  final anonKey = _readEnv('SUPABASE_ANON_KEY', fileEnv);
  final serviceKey =
      _readEnvMulti(['SUPABASE_SERVICE_ROLE', 'SUPABASE_SERVICE_ROLE_KEY'], fileEnv);
  final libreEndpoint =
      _readEnv('LIBRETRANSLATE_ENDPOINT', fileEnv, required: false) ??
          'https://libretranslate.com/translate';
  final libreApiKey =
      _readEnv('LIBRETRANSLATE_API_KEY', fileEnv, required: false);

  final breeds = await _fetchDogBreeds(dogApiKey);
  await _fillMissingImages(breeds, dogApiKey);
  stdout.writeln('Fetched ${breeds.length} breeds from TheDogAPI.');

  final translated = await _translateBreeds(
    breeds,
    endpoint: libreEndpoint,
    apiKey: libreApiKey,
  );

  await _upsertDogBreeds(
    supabaseUrl: supabaseUrl,
    anonKey: anonKey,
    serviceKey: serviceKey,
    breeds: translated,
  );
  stdout.writeln('Supabase breeds table updated successfully.');
}

Future<List<Map<String, dynamic>>> _fetchDogBreeds(String apiKey) async {
  final client = HttpClient();
  final request =
      await client.getUrl(Uri.parse('https://api.thedogapi.com/v1/breeds'));
  request.headers.set('x-api-key', apiKey);

  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode != 200) {
    throw HttpException(
      'Failed to fetch dog breeds: ${response.statusCode} $body',
    );
  }

  final raw = jsonDecode(body) as List<dynamic>;
  final names = <String>{};
  final mapped = <Map<String, dynamic>>[];
  for (final item in raw) {
    final data = item as Map<String, dynamic>;
    final name = (data['name'] as String?)?.trim();
    if (name == null || name.isEmpty) continue;
    if (names.add(name)) {
      final image = data['image'] as Map<String, dynamic>?;
      mapped.add({
        'name': name,
        'image_url': image != null ? image['url'] as String? : null,
        'reference_image_id': data['reference_image_id'],
      });
    }
  }
  return mapped;
}

Future<void> _fillMissingImages(
  List<Map<String, dynamic>> breeds,
  String apiKey,
) async {
  final client = HttpClient();
  for (final breed in breeds) {
    if ((breed['image_url'] as String?)?.isNotEmpty == true) continue;
    final refId = breed['reference_image_id'] as String?;
    if (refId == null || refId.isEmpty) continue;
    final url = await _fetchImageUrlById(client, apiKey: apiKey, imageId: refId);
    if (url != null) {
      breed['image_url'] = url;
    }
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }
  client.close();
}

Future<String?> _fetchImageUrlById(
  HttpClient client, {
  required String apiKey,
  required String imageId,
}) async {
  try {
    final req = await client.getUrl(Uri.parse('https://api.thedogapi.com/v1/images/$imageId'));
    req.headers.set('x-api-key', apiKey);
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();
    if (resp.statusCode != 200) {
      stderr.writeln('Image lookup failed for $imageId: ${resp.statusCode} $body');
      return null;
    }
    final data = jsonDecode(body) as Map<String, dynamic>;
    return data['url'] as String?;
  } catch (e) {
    stderr.writeln('Image lookup error for $imageId: $e');
    return null;
  }
}

Future<List<Map<String, dynamic>>> _translateBreeds(
  List<Map<String, dynamic>> breeds, {
  required String endpoint,
  String? apiKey,
}) async {
  final overridesFile = File('tool/dog_breeds_it.csv');
  Map<String, String> overrides = {};
  if (overridesFile.existsSync()) {
    final lines = overridesFile.readAsLinesSync();
    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final parts = line.split(',');
      if (parts.length >= 2) {
        final en = parts[0].trim();
        final it = parts.sublist(1).join(',').trim();
        overrides[en] = it;
      }
    }
    stdout.writeln('Loaded ${overrides.length} breed overrides from CSV');
  }

  final client = HttpClient();
  final translated = <Map<String, dynamic>>[];
  for (final breed in breeds) {
    final name = breed['name'] as String? ?? '';
    final override = overrides[name];
    String? nameIt = override;
    if (nameIt == null || nameIt.isEmpty) {
      nameIt = await _translateText(
        client,
        endpoint: endpoint,
        apiKey: apiKey,
        text: name,
        source: 'en',
        target: 'it',
      );
    }
    translated.add({
      'name': name,
      'name_it': nameIt ?? name,
      'image_url': breed['image_url'],
    });
    stdout.writeln('Translated: $name -> ${nameIt ?? name}');
    // Piccolo delay per non saturare le API pubbliche
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
  client.close();
  return translated;
}

Future<String?> _translateText(
  HttpClient client, {
  required String endpoint,
  String? apiKey,
  required String text,
  required String source,
  required String target,
}) async {
  try {
    final uri = Uri.parse(endpoint);
    final request = await client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    final payload = {
      'q': text,
      'source': source,
      'target': target,
      'format': 'text',
      if (apiKey != null && apiKey.isNotEmpty) 'api_key': apiKey,
    };
    request.add(utf8.encode(jsonEncode(payload)));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      stderr.writeln('Translate failed for "$text": ${response.statusCode} $body');
      return null;
    }
    final data = jsonDecode(body) as Map<String, dynamic>;
    return data['translatedText'] as String?;
  } catch (e) {
    stderr.writeln('Translate error for "$text": $e');
    return null;
  }
}

Future<void> _upsertDogBreeds({
  required String supabaseUrl,
  required String anonKey,
  required String serviceKey,
  required List<Map<String, dynamic>> breeds,
}) async {
  final client = HttpClient();
  final uri =
      Uri.parse('$supabaseUrl/rest/v1/breeds?on_conflict=name&select=id');
  final request = await client.postUrl(uri);
  request.headers.contentType = ContentType.json;
  request.headers.set('apikey', anonKey);
  request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $serviceKey');
  request.headers.set('Prefer', 'resolution=merge-duplicates');
  request.add(utf8.encode(jsonEncode(breeds)));

  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode >= 300) {
    throw HttpException(
      'Failed to upsert into Supabase: ${response.statusCode} $body',
    );
  }
}

Map<String, String> _loadDotEnv() {
  final file = File('.env');
  if (!file.existsSync()) return {};
  final lines = file.readAsLinesSync();
  final Map<String, String> env = {};
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final idx = trimmed.indexOf('=');
    if (idx <= 0) continue;
    final key = trimmed.substring(0, idx).trim();
    final value = trimmed.substring(idx + 1).trim();
    env[key] = value;
  }
  return env;
}

String _readEnv(String key, Map<String, String> fileEnv, {bool required = true}) {
  final value = Platform.environment[key] ?? fileEnv[key];
  if ((value == null || value.isEmpty) && required) {
    stderr.writeln('Environment variable $key is required (set in .env or shell).');
    exit(1);
  }
  return value ?? '';
}

String _readEnvMulti(List<String> keys, Map<String, String> fileEnv) {
  for (final key in keys) {
    final value = Platform.environment[key] ?? fileEnv[key];
    if (value != null && value.isNotEmpty) return value;
  }
  stderr.writeln('Environment variable ${keys.join(" or ")} is required (set in .env or shell).');
  exit(1);
}
