class AppSettings {
  AppSettings({
    required this.localeCode,
    required this.dailyNotification,
    required this.notificationHour,
    required this.notificationMinute,
    required this.themeMode,
    required this.pinSecurity,
  });

  final String localeCode;
  final bool dailyNotification;
  final int notificationHour;
  final int notificationMinute;

  /// 'system' | 'light' | 'dark'
  final String themeMode;
  final bool pinSecurity;

  factory AppSettings.defaults() {
    return AppSettings(
      localeCode: 'id',
      dailyNotification: true,
      notificationHour: 20,
      notificationMinute: 0,
      themeMode: 'dark',
      pinSecurity: true,
    );
  }

  AppSettings copyWith({
    String? localeCode,
    bool? dailyNotification,
    int? notificationHour,
    int? notificationMinute,
    String? themeMode,
    bool? pinSecurity,
  }) {
    return AppSettings(
      localeCode: localeCode ?? this.localeCode,
      dailyNotification: dailyNotification ?? this.dailyNotification,
      notificationHour: notificationHour ?? this.notificationHour,
      notificationMinute: notificationMinute ?? this.notificationMinute,
      themeMode: themeMode ?? this.themeMode,
      pinSecurity: pinSecurity ?? this.pinSecurity,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'localeCode': localeCode,
      'dailyNotification': dailyNotification,
      'notificationHour': notificationHour,
      'notificationMinute': notificationMinute,
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
      notificationHour: jsonMap['notificationHour'] as int? ?? 20,
      notificationMinute: jsonMap['notificationMinute'] as int? ?? 0,
      themeMode: resolvedThemeMode,
      pinSecurity: jsonMap['pinSecurity'] as bool? ?? true,
    );
  }
}
