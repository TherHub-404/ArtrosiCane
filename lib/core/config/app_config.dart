import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig._();

  static String get supabaseUrl {
    final value = dotenv.env['SUPABASE_URL'];
    if (value == null || value.isEmpty) {
      throw StateError('SUPABASE_URL missing in .env');
    }
    return value;
  }

  static String get supabaseAnonKey {
    final value = dotenv.env['SUPABASE_ANON_KEY'];
    if (value == null || value.isEmpty) {
      throw StateError('SUPABASE_ANON_KEY missing in .env');
    }
    return value;
  }

  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  static String? get demoEmail => _optional('DEMO_EMAIL');

  static String? get demoPassword => _optional('DEMO_PASSWORD');

  static String get inviteApiBaseUrl =>
      _optional('INVITE_API_BASE_URL') ?? 'https://api.example.com';

  static String get inviteDomain =>
      _optional('INVITE_DOMAIN') ?? 'artrosicane.vercel.app';

  static String get invitePath => _optional('INVITE_PATH') ?? '/i';

  static String? _optional(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) return null;
    return value;
  }
}
