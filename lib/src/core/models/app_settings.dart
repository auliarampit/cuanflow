class AppSettings {
  AppSettings({
    required this.localeCode,
    required this.dailyNotification,
    required this.notificationHour,
    required this.notificationMinute,
    required this.themeMode,
    required this.pinSecurity,
    this.reminder1Enabled = true,
    this.reminder2Enabled = true,
    this.reminder3Enabled = true,
    this.budgetAlertEnabled = true,
  });

  final String localeCode;
  // Kept for backward-compat JSON round-trip; new UI uses reminder1/2/3Enabled.
  final bool dailyNotification;
  final int notificationHour;
  final int notificationMinute;

  /// 'system' | 'light' | 'dark'
  final String themeMode;
  final bool pinSecurity;

  /// Pengingat harian pukul 09:00
  final bool reminder1Enabled;

  /// Pengingat harian pukul 15:00
  final bool reminder2Enabled;

  /// Pengingat harian pukul 21:00
  final bool reminder3Enabled;

  /// Notifikasi peringatan saat budget pengeluaran hampir habis (>80%)
  final bool budgetAlertEnabled;

  factory AppSettings.defaults() {
    return AppSettings(
      localeCode: 'id',
      dailyNotification: true,
      notificationHour: 20,
      notificationMinute: 0,
      themeMode: 'dark',
      pinSecurity: true,
      reminder1Enabled: true,
      reminder2Enabled: true,
      reminder3Enabled: true,
      budgetAlertEnabled: true,
    );
  }

  AppSettings copyWith({
    String? localeCode,
    bool? dailyNotification,
    int? notificationHour,
    int? notificationMinute,
    String? themeMode,
    bool? pinSecurity,
    bool? reminder1Enabled,
    bool? reminder2Enabled,
    bool? reminder3Enabled,
    bool? budgetAlertEnabled,
  }) {
    return AppSettings(
      localeCode: localeCode ?? this.localeCode,
      dailyNotification: dailyNotification ?? this.dailyNotification,
      notificationHour: notificationHour ?? this.notificationHour,
      notificationMinute: notificationMinute ?? this.notificationMinute,
      themeMode: themeMode ?? this.themeMode,
      pinSecurity: pinSecurity ?? this.pinSecurity,
      reminder1Enabled: reminder1Enabled ?? this.reminder1Enabled,
      reminder2Enabled: reminder2Enabled ?? this.reminder2Enabled,
      reminder3Enabled: reminder3Enabled ?? this.reminder3Enabled,
      budgetAlertEnabled: budgetAlertEnabled ?? this.budgetAlertEnabled,
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
      'reminder1Enabled': reminder1Enabled,
      'reminder2Enabled': reminder2Enabled,
      'reminder3Enabled': reminder3Enabled,
      'budgetAlertEnabled': budgetAlertEnabled,
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

    // Migrasi dari single dailyNotification ke 3 slot: jika slot belum ada di
    // JSON, default-kan ke nilai dailyNotification lama supaya perilaku tidak berubah.
    final hadDailyNotif = jsonMap['dailyNotification'] as bool? ?? false;

    return AppSettings(
      localeCode: jsonMap['localeCode'] as String? ?? 'id',
      dailyNotification: hadDailyNotif,
      notificationHour: jsonMap['notificationHour'] as int? ?? 20,
      notificationMinute: jsonMap['notificationMinute'] as int? ?? 0,
      themeMode: resolvedThemeMode,
      pinSecurity: jsonMap['pinSecurity'] as bool? ?? true,
      reminder1Enabled: jsonMap['reminder1Enabled'] as bool? ?? hadDailyNotif,
      reminder2Enabled: jsonMap['reminder2Enabled'] as bool? ?? hadDailyNotif,
      reminder3Enabled: jsonMap['reminder3Enabled'] as bool? ?? hadDailyNotif,
      budgetAlertEnabled: jsonMap['budgetAlertEnabled'] as bool? ?? true,
    );
  }
}
