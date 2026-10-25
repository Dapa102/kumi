import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/models.dart';

/// Schedules local reminders 15 minutes before a task's due time.
/// Notifications live entirely on the device; no server push involved.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const int _reminderOffsetMinutes = 15;
  static const String _channelId = 'kumi_task_reminders';
  static const String _channelName = 'Pengingat Tugas';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  Future<void> initialize() async {
    if (_ready) return;

    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fall back to UTC if the platform cannot report a timezone.
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(settings: settings);
    _ready = true;
  }

  Future<bool> requestPermission() async {
    await initialize();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  Future<void> scheduleTaskReminder(TaskItem task) async {
    if (task.isCompleted) {
      await cancelTaskReminder(task.id);
      return;
    }

    await initialize();
    final scheduled = task.dueTime.subtract(
      const Duration(minutes: _reminderOffsetMinutes),
    );
    if (scheduled.isBefore(DateTime.now())) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Pengingat sebelum tenggat tugas',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id: task.id,
      title: 'Tugas sebentar lagi',
      body: '${task.title} jatuh tempo dalam $_reminderOffsetMinutes menit.',
      scheduledDate: tz.TZDateTime.from(scheduled, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'task:${task.id}',
    );
  }

  Future<void> cancelTaskReminder(int taskId) async {
    await initialize();
    await _plugin.cancel(id: taskId);
  }
}
