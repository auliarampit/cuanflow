class AppSettings {
  AppSettings({
    required this.localeCode,
    required this.dailyNotification,
    required this.themeMode,
    required this.pinSecurity,
  });

  final String localeCode;
  final bool dailyNotification;

  /// 'system' | 'light' | 'dark'
  final String themeMode;
  final bool pinSecurity;

  factory AppSettings.defaults() {
    return AppSettings(
      localeCode: 'id',
      dailyNotification: false,
      themeMode: 'dark',
      pinSecurity: true,
    );
  }

  AppSettings copyWith({
    String? localeCode,
    bool? dailyNotification,
    String? themeMode,
    bool? pinSecurity,
  }) {
    return AppSettings(
      localeCode: localeCode ?? this.localeCode,
      dailyNotification: dailyNotification ?? this.dailyNotification,
      themeMode: themeMode ?? this.themeMode,
      pinSecurity: pinSecurity ?? this.pinSecurity,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'localeCode': localeCode,
      'dailyNotification': dailyNotification,
      'themeMode': themeMode,
      'pinSecurity': pinSecurity,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> jsonMap) {
    // Backward-compat: migrasi dari boolean darkTheme lama
    String resolvedThemeMode;
    if (jsonMap.containsKey('themeMode')) {
      resolvedThemeMode = jsonMap['themeMode'] as String? ?? 'dark';
    } else {
      final darkTheme = jsonMap['darkTheme'] as bool? ?? true;
      resolvedThemeMode = darkTheme ? 'dark' : 'light';
    }

    return AppSettings(
      localeCode: jsonMap['localeCode'] as String? ?? 'id',
      dailyNotification: jsonMap['dailyNotification'] as bool? ?? false,
      themeMode: resolvedThemeMode,
      pinSecurity: jsonMap['pinSecurity'] as bool? ?? true,
    );
  }
}
