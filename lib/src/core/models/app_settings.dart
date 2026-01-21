class AppSettings {
  AppSettings({
    required this.localeCode,
    required this.dailyNotification,
    required this.darkTheme,
    required this.pinSecurity,
  });

  final String localeCode;
  final bool dailyNotification;
  final bool darkTheme;
  final bool pinSecurity;

  factory AppSettings.defaults() {
    return AppSettings(
      localeCode: 'id',
      dailyNotification: false,
      darkTheme: true,
      pinSecurity: true,
    );
  }

  AppSettings copyWith({
    String? localeCode,
    bool? dailyNotification,
    bool? darkTheme,
    bool? pinSecurity,
  }) {
    return AppSettings(
      localeCode: localeCode ?? this.localeCode,
      dailyNotification: dailyNotification ?? this.dailyNotification,
      darkTheme: darkTheme ?? this.darkTheme,
      pinSecurity: pinSecurity ?? this.pinSecurity,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'localeCode': localeCode,
      'dailyNotification': dailyNotification,
      'darkTheme': darkTheme,
      'pinSecurity': pinSecurity,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> jsonMap) {
    return AppSettings(
      localeCode: jsonMap['localeCode'] as String? ?? 'id',
      dailyNotification: jsonMap['dailyNotification'] as bool? ?? false,
      darkTheme: jsonMap['darkTheme'] as bool? ?? true,
      pinSecurity: jsonMap['pinSecurity'] as bool? ?? true,
    );
  }
}