import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/savings_group.dart';
import '../utils/gap_date_format.dart';

/// Mahalliy eslatmalar — har bir qurilmada GAP kuni oldidan va kuni.
class GapNotificationService {
  GapNotificationService._();
  static final GapNotificationService instance = GapNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (kIsWeb) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Tashkent'));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        'gap_reminders',
        'GAP eslatmalari',
        description: 'Keyingi jamg\'arma kuni haqida xabar',
        importance: Importance.high,
      ),
    );
    _ready = true;
  }

  int _idFor(String groupId, int slot) =>
      (groupId.hashCode.abs() % 100000) * 10 + slot;

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          'gap_reminders',
          'GAP eslatmalari',
          channelDescription: 'Keyingi jamg\'arma kuni haqida xabar',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  Future<void> cancelForGroup(String groupId) async {
    if (!_ready) return;
    for (var i = 0; i < 3; i++) {
      await _plugin.cancel(_idFor(groupId, i));
    }
  }

  Future<void> scheduleForGroup(SavingsGroup group) async {
    if (!_ready || group.isClosed) return;
    final due = group.nextGapDueDate;
    if (due == null) return;

    await cancelForGroup(group.id);
    final dueOnly = gapDateOnly(due);
    final now = tz.TZDateTime.now(tz.local);

    final dayOf = tz.TZDateTime(
      tz.local,
      dueOnly.year,
      dueOnly.month,
      dueOnly.day,
      9,
    );
    if (dayOf.isAfter(now)) {
      await _zoned(
        _idFor(group.id, 0),
        'GAP bugun',
        '"${group.name}" — bugun jamg\'arma kuni. To\'lovlarni unutmang.',
        dayOf,
      );
    }

    final dayBefore = dayOf.subtract(const Duration(days: 1));
    if (dayBefore.isAfter(now)) {
      await _zoned(
        _idFor(group.id, 1),
        'GAP ertaga',
        '"${group.name}" — ertaga jamg\'arma: ${formatGapDate(dueOnly)}',
        dayBefore,
      );
    }

    final threeDays = dayOf.subtract(const Duration(days: 3));
    if (threeDays.isAfter(now)) {
      await _zoned(
        _idFor(group.id, 2),
        'GAP yaqinlashmoqda',
        '"${group.name}" — ${formatGapDate(dueOnly)} kuni jamg\'arma',
        threeDays,
      );
    }
  }

  Future<void> _zoned(
    int id,
    String title,
    String body,
    tz.TZDateTime when,
  ) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('GAP notification schedule failed: $e');
    }
  }

  Future<void> syncAll(Iterable<SavingsGroup> groups) async {
    if (!_ready) return;
    for (final g in groups) {
      if (g.isClosed || g.nextGapDueDate == null) {
        await cancelForGroup(g.id);
      } else {
        await scheduleForGroup(g);
      }
    }
  }
}
