import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Manages the daily transaction reminder notification.
///
/// Usage:
///   await NotificationService.init();          // once at app start
///   await NotificationService.schedule();      // when toggle turned ON
///   await NotificationService.cancel();        // when toggle turned OFF
class NotificationService {
  NotificationService._();

  static const _channelId = 'daily_reminder';
  static const _channelName = 'Pengingat Harian';
  static const _notifId = 1;

  // Default reminder time: 20:00
  static const _hour = 20;
  static const _minute = 0;

  static final _plugin = FlutterLocalNotificationsPlugin();

  /// Call once in main() before runApp().
  static Future<void> init() async {
    tz_data.initializeTimeZones();

    // Try to set local timezone from system
    try {
      final localTz = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      // Fallback: use UTC offset to approximate
      final offset = DateTime.now().timeZoneOffset;
      final sign = offset.isNegative ? '-' : '+';
      final hh = offset.inHours.abs().toString().padLeft(2, '0');
      try {
        tz.setLocalLocation(tz.getLocation('Etc/GMT${sign == '+' ? '-' : '+'}${offset.inHours.abs()}'));
      } catch (e2) {
        // If all fails, stay with UTC — notification time will be offset
        assert(hh.isNotEmpty); // suppress unused var warning
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

  /// Schedule a daily notification at [_hour]:[_minute] local time.
  /// Requests permission on first call.
  static Future<void> schedule() async {
    await _requestPermissions();
    await cancel(); // clear any existing schedule

    final scheduledDate = _nextOccurrence(_hour, _minute);

    await _plugin.zonedSchedule(
      _notifId,
      'Cuan Flow 💰',
      'Jangan lupa catat transaksi hari ini!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
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

  /// Cancel the daily reminder.
  static Future<void> cancel() async {
    await _plugin.cancel(_notifId);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

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
    // Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // iOS
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }
}
