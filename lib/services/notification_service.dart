import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class Notifs {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialised = false;

  static Future<void> _ensureInit() async {
    if (_initialised) return;
    tzdata.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _initialised = true;
  }

  static Future<void> schedRem(DateTime nextPayDate) async {
    await _ensureInit(); // init on first call, after runApp

    // request exact alarm permission on android 12+
    final plugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await plugin?.requestExactAlarmsPermission();
    if (granted != true) {
      debugPrint('exact alarm permission denied, skipping notif');
      return;
    }

    debugPrint('exact alarms granted: $granted');

    await _plugin.cancel(id: 1);

    final now = DateTime.now();
    final remDate = now.add(const Duration(minutes: 2));
    if (remDate.isBefore(now)) return;

    debugPrint('scheduling payment reminder for $remDate');
    debugPrint('remDate: $remDate, now: ${DateTime.now()}, isFuture: ${remDate.isAfter(DateTime.now())}');
    await _plugin.zonedSchedule(
      id: 1, // can be cancelled/replaced
      title: 'TMA payment due soon',
      body: 'Your monthly tuition payment is due in 2 days.',
      scheduledDate: tz.TZDateTime.from(remDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'payment_reminders',
          'Payment Reminders',
          channelDescription: 'Reminds students of upcoming tuition payments',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelRem() async {
    await _ensureInit();
    await _plugin.cancel(id: 1);
  }
}