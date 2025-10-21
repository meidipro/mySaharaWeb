/// Language model for the app
class Language {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Language && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}

/// Available languages in the app
class AppLanguages {
  static const Language english = Language(
    code: 'en',
    name: 'English',
    nativeName: 'English',
    flag: '🇬🇧',
  );

  static const Language bengali = Language(
    code: 'bn',
    name: 'Bengali',
    nativeName: 'বাংলা',
    flag: '🇧🇩',
  );

  static const List<Language> all = [english, bengali];

  static Language fromCode(String code) {
    return all.firstWhere(
      (lang) => lang.code == code,
      orElse: () => english,
    );
  }
}
