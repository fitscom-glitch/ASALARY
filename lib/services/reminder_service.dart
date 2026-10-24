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

  /// Các tên biểu tượng thử lần lượt: plugin báo `invalid_icon` nếu không tìm thấy tài nguyên,
  /// khi đó khởi tạo lỗi và mọi thông báo (kể cả đặt lịch) đều không chạy.
  /// Cuối cùng dùng biểu tượng ứng dụng, luôn có sẵn, để thông báo vẫn hoạt động.
  static const _iconCandidates = ['ic_stat_asalary', '@drawable/ic_stat_asalary', '@mipmap/ic_launcher'];

  Future<void> _init() async {
    if (_ready) return;
    Object? last;
    for (final icon in _iconCandidates) {
      try {
        await _plugin.initialize(InitializationSettings(android: AndroidInitializationSettings(icon)));
        _ready = true;
        return;
      } catch (e) {
        last = e;
      }
    }
    throw last ?? StateError('Không khởi tạo được thông báo');
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Lỗi gần nhất khi xin quyền / kiểm tra quyền (để hiện cho người dùng thay vì nuốt mất).
  String? lastError;

  /// Thông báo của ứng dụng hiện có đang được bật trong hệ thống không (không hiện hộp thoại xin quyền).
  Future<bool> notificationsEnabled() async {
    try {
      await _init();
      return await _android?.areNotificationsEnabled() ?? true;
    } catch (e) {
      lastError = '$e';
      return false;
    }
  }

  /// Xin quyền hiện thông báo (Android 13 trở lên). Trả về true nếu được phép.
  ///
  /// Kết quả cuối cùng luôn dựa vào trạng thái thật của hệ thống (areNotificationsEnabled), vì
  /// requestNotificationsPermission có thể trả về false/null khi quyền đã được cấp từ trước
  /// hoặc người dùng vừa bật trong Cài đặt Android (hộp thoại xin quyền không hiện lại).
  Future<bool> requestPermission() async {
    lastError = null;
    try {
      await _init();
      final android = _android;
      if (android == null) return true;
      if (await android.areNotificationsEnabled() ?? false) return true;
      try {
        if (await android.requestNotificationsPermission() ?? false) return true;
      } catch (e) {
        // Ví dụ "đang có yêu cầu quyền khác": vẫn kiểm tra lại trạng thái thật bên dưới.
        lastError = '$e';
      }
      final enabled = await android.areNotificationsEnabled() ?? false;
      if (enabled) lastError = null;
      return enabled;
    } catch (e) {
      lastError = '$e';
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
    // Đổi giờ địa phương sang cùng thời điểm theo UTC: không cần cơ sở dữ liệu múi giờ.
    final when = tz.TZDateTime.from(at, tz.UTC);
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
