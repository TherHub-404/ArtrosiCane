import 'package:artrosi_cane/l10n/app_locale.dart';

class Breed {
  const Breed({
    required this.id,
    required this.name,
    this.nameIt,
    this.nameFr,
    this.nameDe,
  });

  final String id;
  final String name;
  final String? nameIt;
  final String? nameFr;
  final String? nameDe;

  bool get isMixedBreed => name == mixedBreedCanonicalName;

  static const String mixedBreedCanonicalName = 'Mixed breed';

  String localizedName(AppLanguage language) {
    final localized = switch (language) {
      AppLanguage.italian => nameIt,
      AppLanguage.french => nameFr,
      AppLanguage.german => nameDe,
      AppLanguage.english => name,
    };
    if (localized != null && localized.isNotEmpty) return localized;
    if (nameIt != null && nameIt!.isNotEmpty) return nameIt!;
    return name;
  }
}
