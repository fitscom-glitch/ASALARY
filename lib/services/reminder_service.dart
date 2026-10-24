import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show
        AndroidFlutterLocalNotificationsPlugin,
        AndroidInitializationSettings,
        AndroidNotificationCategory,
        AndroidNotificationDetails,
        AndroidScheduleMode,
        AudioAttributesUsage,
        FlutterLocalNotificationsPlugin,
        Importance,
        InitializationSettings,
        NotificationDetails,
        NotificationVisibility,
        Priority,
        UriAndroidNotificationSound;
import 'package:timezone/timezone.dart' as tz;

import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/data/models/reminder_config.dart';

/// Đặt lịch thông báo có chuông (flutter_local_notifications).
class ReminderService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    await _plugin.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('@drawable/ic_stat_asalary')),
    );
    _ready = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Xin quyền hiện thông báo và quyền báo thức chính xác (Android 13+). Trả về true nếu được phép.
  Future<bool> requestPermission() async {
    try {
      await _init();
      final notifGranted = await _android?.requestNotificationsPermission() ?? true;
      final exactAlarmGranted = await _android?.requestExactAlarmsPermission() ?? true;
      return notifGranted && exactAlarmGranted;
    } catch (_) {
      return false;
    }
  }

  NotificationDetails _details() => NotificationDetails(
        android: AndroidNotificationDetails(
          'shift_reminders',
          tr('Nhắc giờ vào ca / ra ca'),
          channelDescription: tr('Chuông báo giờ vào ca và ra ca'),
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          sound: const UriAndroidNotificationSound('content://settings/system/alarm_alert'),
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
      );

  Future<void> showTest() async {
    await _init();
    await _plugin.show(
      999,
      tr('Nhắc nhở'),
      tr('Đây là thông báo thử. Nếu nghe chuông, nhắc giờ đã hoạt động.'),
      _details(),
    );
  }

  Future<void> _schedule(int id, String title, String body, DateTime at, AndroidScheduleMode mode) async {
    // Sửa lỗi múi giờ: Sử dụng tz.local để khớp với giờ thực tế của thiết bị thay vì tz.UTC.
    final when = tz.TZDateTime(
      tz.local,
      at.year,
      at.month,
      at.day,
      at.hour,
      at.minute,
      at.second,
    );
    
    try {
      await _plugin.zonedSchedule(id, title, body, when, _details(), androidScheduleMode: mode);
    } catch (_) {
      // Thiếu quyền báo thức chính xác: dùng chế độ gần đúng thay vì bỏ lỡ.
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// Đặt lại toàn bộ lịch nhắc cho [_horizonDays] ngày tới. Trả về số thông báo đã đặt.
  ///
  /// [holidays] là các ngày lễ đã đánh dấu: ngày đó chỉ chạy nhắc nhở có chọn "Lễ".
  Future<int> sync(ReminderConfig cfg, Set<String> holidays) async {
    await _init();
    await _plugin.cancelAll();
    if (!cfg.anyEnabled) return 0;

    var mode = AndroidScheduleMode.exactAllowWhileIdle;
    try {
      if (await _android?.canScheduleExactNotifications() == false) {
        mode = AndroidScheduleMode.inexactAllowWhileIdle;
      }
    } catch (_) {}

    final body = tr('Đã đến giờ chấm công. Đừng quên bấm "Vào ca" hoặc "Ra ca".');
    final now = DateTime.now();
    var id = 1;
    for (var i = 0; i < _horizonDays; i++) {
      final day = DateTime(now.year, now.month, now.day + i);
      for (var idx = 0; idx < cfg.items.length; idx++) {
        final r = cfg.items[idx];
        if (!r.enabled || !r.firesOn(day, holidays)) continue;
        final at = DateTime(day.year, day.month, day.day, r.minutes ~/ 60, r.minutes % 60);
        if (!at.isAfter(now)) continue;
        if (id > _maxScheduled) return id - 1; // Android giới hạn số báo thức đặt trước
        await _schedule(id++, tr(r.title(idx)), body, at, mode);
      }
    }
    return id - 1;
  }

  static const _horizonDays = 30;
  static const _maxScheduled = 400;
}
