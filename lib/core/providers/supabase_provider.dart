import 'package:artrosi_cane/core/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

SupabaseClient? maybeSupabaseClient() {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
}

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 2),
  );
}
