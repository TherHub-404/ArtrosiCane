/// A single advice video shown in the "Passeggiate" reels tab.
///
/// Content is dynamic: rows live in the `advice_videos` Postgres table and
/// are managed from the web dashboard. [title] and [description] are keyed by
/// language code (it/en/fr/de) with an Italian fallback.
class AdviceVideo {
  const AdviceVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.storagePath,
    required this.position,
  });

  factory AdviceVideo.fromRow(Map<String, dynamic> row) {
    return AdviceVideo(
      id: row['id']?.toString() ?? '',
      title: _asStringMap(row['title']),
      description: _asStringMap(row['description']),
      storagePath: row['storage_path']?.toString() ?? '',
      position: (row['position'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final Map<String, String> title;
  final Map<String, String> description;
  final String storagePath;
  final int position;

  static const String _baseUrl =
      'https://iexlrcmfahywhvvpjalg.supabase.co/storage/v1/object/public/advice-videos';

  /// Public playback URL of the video file in Supabase Storage.
  String get url => '$_baseUrl/$storagePath';

  String titleFor(String languageCode) => _pick(title, languageCode);

  String descriptionFor(String languageCode) =>
      _pick(description, languageCode);

  static String _pick(Map<String, String> map, String languageCode) {
    final value = map[languageCode];
    if (value != null && value.isNotEmpty) return value;
    return map['it'] ?? '';
  }

  static Map<String, String> _asStringMap(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), val?.toString() ?? ''),
      );
    }
    return const <String, String>{};
  }
}
