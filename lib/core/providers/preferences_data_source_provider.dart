import 'package:artrosi_cane/core/data/preferences_data_source.dart';
import 'package:artrosi_cane/core/providers/shared_prefs_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final preferencesDataSourceProvider = Provider<PreferencesDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PreferencesDataSource(prefs);
});
