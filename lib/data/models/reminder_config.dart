import 'package:theo_doi_luong/core/utils/formatters.dart';

/// Một nhắc nhở (giống một báo thức): giờ, các ngày lặp lại và bật/tắt.
///
/// Ngày đã đánh dấu là ngày lễ trong Cài đặt được xem là "Lễ": ngày đó chỉ chạy
/// các nhắc nhở có chọn [holiday], bất kể thứ trong tuần.
class Reminder {
  const Reminder({
    required this.id,
    required this.minutes,
    this.days = const {1, 2, 3, 4, 5},
    this.holiday = false,
    this.enabled = true,
    this.label = '',
  });

  final int id;
  final int minutes; // phút trong ngày, 0..1439
  final Set<int> days; // 1 = thứ 2 ... 7 = chủ nhật
  final bool holiday;
  final bool enabled;
  final String label;

  /// Tên hiển thị: tên tự đặt, hoặc "Nhắc nhở N" theo vị trí trong danh sách.
  String title(int index) => label.trim().isNotEmpty ? label.trim() : 'Nhắc nhở ${index + 1}';

  bool get hasDays => days.isNotEmpty || holiday;

  /// Nhắc nhở có chạy vào ngày [day] không (có xét ngày lễ).
  bool firesOn(DateTime day, Set<String> holidays) =>
      holidays.contains(dateFmt.format(day)) ? holiday : days.contains(day.weekday);

  Reminder copyWith({int? minutes, Set<int>? days, bool? holiday, bool? enabled, String? label}) => Reminder(
        id: id,
        minutes: minutes ?? this.minutes,
        days: days ?? this.days,
        holiday: holiday ?? this.holiday,
        enabled: enabled ?? this.enabled,
        label: label ?? this.label,
      );

  String get signature => '$id:$minutes:$enabled:$holiday:${(days.toList()..sort()).join('.')}:$label';

  Map<String, Object?> toJson() => {
        'id': id,
        'minutes': minutes,
        'days': (days.toList()..sort()),
        'holiday': holiday,
        'enabled': enabled,
        'label': label,
      };

  static Reminder? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final minutes = raw['minutes'];
    if (id is! int || minutes is! int || minutes < 0 || minutes >= 1440) return null;
    final d = raw['days'];
    return Reminder(
      id: id,
      minutes: minutes,
      days: {
        if (d is List)
          for (final x in d)
            if (x is int && x >= 1 && x <= 7) x,
      },
      holiday: raw['holiday'] == true,
      enabled: raw['enabled'] != false,
      label: raw['label'] is String ? (raw['label'] as String).trim() : '',
    );
  }
}

/// Danh sách nhắc nhở của người dùng.
class ReminderConfig {
  const ReminderConfig({this.items = const []});
  final List<Reminder> items;

  bool get anyEnabled => items.any((r) => r.enabled && r.hasDays);

  int get enabledCount => items.where((r) => r.enabled).length;

  int get nextId => items.fold<int>(0, (m, r) => r.id > m ? r.id : m) + 1;

  /// Dùng để biết khi nào cần đặt lại lịch thông báo.
  String get signature => items.map((r) => r.signature).join('|');

  ReminderConfig copyWith({List<Reminder>? items}) => ReminderConfig(items: items ?? this.items);

  Map<String, Object?> toJson() => {'items': [for (final r in items) r.toJson()]};

  /// Đọc định dạng mới (`items`) và cả định dạng cũ (`start`, `end`, `days`).
  static ReminderConfig fromJson(Object? raw) {
    if (raw is! Map) return const ReminderConfig();
    final out = <Reminder>[];
    final list = raw['items'];
    if (list is List) {
      final seen = <int>{};
      for (final x in list) {
        final r = Reminder.fromJson(x);
        if (r != null && seen.add(r.id)) out.add(r);
        if (out.length >= 50) break;
      }
      return ReminderConfig(items: out);
    }

    // Định dạng cũ: một giờ vào ca, một giờ ra ca, chung các ngày lặp lại.
    int? minutes(Object? v) => (v is int && v >= 0 && v < 1440) ? v : null;
    final d = raw['days'];
    final days = <int>{
      if (d is List)
        for (final x in d)
          if (x is int && x >= 1 && x <= 7) x,
    };
    final legacyDays = days.isEmpty ? const {1, 2, 3, 4, 5} : days;
    final start = minutes(raw['start']);
    final end = minutes(raw['end']);
    if (start != null) out.add(Reminder(id: 1, minutes: start, days: legacyDays, label: 'Nhắc vào ca'));
    if (end != null) out.add(Reminder(id: 2, minutes: end, days: legacyDays, label: 'Nhắc ra ca'));
    return ReminderConfig(items: out);
  }
}
