import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Manages daily reminder notifications (3 slots) and budget alert notifications.
///
/// Usage:
///   await NotificationService.init();             // once at app start
///   await NotificationService.scheduleReminders(slot1: true, slot2: false, slot3: true);
///   await NotificationService.cancelAll();
///   await NotificationService.showBudgetAlert(budgetName: 'Makan', percent: 85);
class NotificationService {
  NotificationService._();

  static const _reminderChannelId = 'daily_reminder';
  static const _reminderChannelName = 'Pengingat Harian';
  static const _budgetChannelId = 'budget_alert';
  static const _budgetChannelName = 'Peringatan Budget';

  // Reminder slot IDs: 1 = 09:00, 2 = 15:00, 3 = 21:00
  static const _reminder1Id = 1;
  static const _reminder2Id = 2;
  static const _reminder3Id = 3;
  static const _budgetAlertId = 100;

  static const _reminderIds = [_reminder1Id, _reminder2Id, _reminder3Id];

  static final _plugin = FlutterLocalNotificationsPlugin();

  /// Call once in main() before runApp().
  static Future<void> init() async {
    tz_data.initializeTimeZones();

    try {
      final localTz = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      final offset = DateTime.now().timeZoneOffset;
      final hh = offset.inHours.abs().toString().padLeft(2, '0');
      try {
        tz.setLocalLocation(tz.getLocation(
            'Etc/GMT${offset.isNegative ? '+' : '-'}${offset.inHours.abs()}'));
      } catch (e2) {
        assert(hh.isNotEmpty);
      }
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  /// Schedule daily reminder notifications for each enabled slot.
  /// Waktu per slot bisa dikustomisasi; default: 09:00, 15:00, 21:00.
  static Future<void> scheduleReminders({
    bool slot1 = true,
    bool slot2 = true,
    bool slot3 = true,
    int slot1Hour = 9,
    int slot1Minute = 0,
    int slot2Hour = 15,
    int slot2Minute = 0,
    int slot3Hour = 21,
    int slot3Minute = 0,
  }) async {
    await _requestPermissions();
    final slots = [slot1, slot2, slot3];
    final hours = [slot1Hour, slot2Hour, slot3Hour];
    final minutes = [slot1Minute, slot2Minute, slot3Minute];
    for (var i = 0; i < 3; i++) {
      await _plugin.cancel(_reminderIds[i]);
      if (slots[i]) {
        await _scheduleReminder(_reminderIds[i], hours[i], minutes[i]);
      }
    }
  }

  /// Kirim notifikasi percobaan segera (untuk verifikasi dari settings screen).
  static Future<void> sendTestNotification() async {
    await _requestPermissions();
    await _plugin.show(
      98,
      'Cuan Flow 💰',
      'Notifikasi berhasil! Pengingat akan muncul di waktu yang kamu pilih.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannelId,
          _reminderChannelName,
          channelDescription: 'Notifikasi pengingat catat transaksi harian',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Cek apakah notifikasi diizinkan di sistem (Android 13+).
  /// Selalu true di iOS karena permission di-request saat jadwal.
  static Future<bool> hasPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? true;
    }
    return true;
  }

  /// Cancel all daily reminders.
  static Future<void> cancelAll() async {
    for (final id in _reminderIds) {
      await _plugin.cancel(id);
    }
  }

  /// Show an immediate budget alert notification.
  static Future<void> showBudgetAlert({
    required String budgetName,
    required int percent,
  }) async {
    final message = percent >= 100
        ? 'Budget "$budgetName" sudah melebihi batas! ($percent%)'
        : 'Budget "$budgetName" sudah terpakai $percent% — hampir habis!';

    await _plugin.show(
      _budgetAlertId,
      'Peringatan Budget 📊',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _budgetChannelId,
          _budgetChannelName,
          channelDescription: 'Notifikasi peringatan budget mendekati batas',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // ── Legacy compat — kept so any existing call sites compile ───────────────

  /// @deprecated Gunakan [scheduleReminders] untuk multi-slot.
  static Future<void> schedule({
    int hour = 20,
    int minute = 0,
  }) async {
    await _requestPermissions();
    await _scheduleReminder(_reminder1Id, hour, minute);
  }

  /// @deprecated Gunakan [cancelAll].
  static Future<void> cancel() => _plugin.cancel(_reminder1Id);

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Future<void> _scheduleReminder(int id, int hour, int minute) async {
    final scheduledDate = _nextOccurrence(hour, minute);
    await _plugin.zonedSchedule(
      id,
      'Cuan Flow 💰',
      'Jangan lupa catat transaksi hari ini!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannelId,
          _reminderChannelName,
          channelDescription: 'Notifikasi pengingat catat transaksi harian',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextOccurrence(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }
}
