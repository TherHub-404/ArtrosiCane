import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class DailyQuickCheckNotificationService {
  const DailyQuickCheckNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _notificationId = 1600;
  static const String _channelId = 'daily_quick_check_reminders';
  static bool _initialized = false;

  static Future<void> initializeAndScheduleDailyReminder() async {
    if (!_supportsLocalNotifications) return;
    if (!_initialized) {
      await _initializePlugin();
      await _configureLocalTimezone();
      _initialized = true;
    }

    await _requestPermissions();
    await _scheduleFor16EveryDay();
  }

  static bool get _supportsLocalNotifications {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static Future<void> _initializePlugin() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
  }

  static Future<void> _configureLocalTimezone() async {
    tz.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Fallback to default timezone if device name cannot be resolved.
    }
  }

  static Future<void> _requestPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> _scheduleFor16EveryDay() async {
    final l10n = AppLocalizations.current;
    await _plugin.cancel(_notificationId);

    await _plugin.zonedSchedule(
      _notificationId,
      l10n.text('Diario giornaliero'),
      l10n.text(
        'Sono le 16: è il momento di compilare il Diario giornaliero del tuo cane.',
      ),
      _next16(),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          l10n.text('Promemoria Diario giornaliero'),
          channelDescription: l10n.text(
            'Promemoria giornaliero alle 16:00 per compilare il Diario giornaliero.',
          ),
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _next16() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 16);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
