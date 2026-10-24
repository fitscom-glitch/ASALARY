import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;

import 'package:theo_doi_luong/core/constants/app_constants.dart';
import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/data/models/reminder_config.dart';

class AppSettings {
  const AppSettings({
    this.hourlyRate = kDefaultRate,
    this.holidays = const {},
    this.lang = 'vi',
    this.reminders = const ReminderConfig(),
    this.companyName = '',
    this.userName = '',
    this.userId = '',
  });
  final double hourlyRate;
  final Set<String> holidays; // 'yyyy-MM-dd'
  final String lang; // 'vi' hoặc 'en'
  final ReminderConfig reminders;

  /// Hồ sơ hiển thị ở đầu trang chính.
  final String companyName;
  final String userName;
  final String userId;

  /// Quy tắc cố định: tuần làm việc bắt đầu từ thứ 2.
  int get weekStart => DateTime.monday;

  AppSettings copyWith({
    double? hourlyRate,
    Set<String>? holidays,
    String? lang,
    ReminderConfig? reminders,
    String? companyName,
    String? userName,
    String? userId,
  }) =>
      AppSettings(
        hourlyRate: hourlyRate ?? this.hourlyRate,
        holidays: holidays ?? this.holidays,
        lang: lang ?? this.lang,
        reminders: reminders ?? this.reminders,
        companyName: companyName ?? this.companyName,
        userName: userName ?? this.userName,
        userId: userId ?? this.userId,
      );

  static const _remindersKey = 'reminders_v2';

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      hourlyRate: prefs.getDouble('hourlyRate') ?? kDefaultRate,
      holidays: (prefs.getStringList('holidays') ?? const <String>[]).toSet(),
      lang: supportedLangs.containsKey(prefs.getString('lang')) ? prefs.getString('lang')! : 'vi',
      reminders: _loadReminders(prefs),
      companyName: prefs.getString('profile_company') ?? '',
      userName: prefs.getString('profile_name') ?? '',
      userId: prefs.getString('profile_id') ?? '',
    );
  }

  /// Đọc nhắc nhở; nếu chưa có định dạng mới thì chuyển từ khóa cũ (giờ vào ca / ra ca).
  static ReminderConfig _loadReminders(SharedPreferences prefs) {
    final raw = prefs.getString(_remindersKey);
    if (raw != null) {
      try {
        return ReminderConfig.fromJson(jsonDecode(raw));
      } catch (_) {
        return const ReminderConfig();
      }
    }
    return ReminderConfig.fromJson({
      'start': prefs.getInt('rem_start'),
      'end': prefs.getInt('rem_end'),
      'days': (prefs.getStringList('rem_days') ?? const <String>[]).map(int.tryParse).whereType<int>().toList(),
    });
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('hourlyRate', hourlyRate);
    await prefs.setStringList('holidays', holidays.toList()..sort());
    await prefs.setString('lang', lang);
    await prefs.setString(_remindersKey, jsonEncode(reminders.toJson()));
    for (final k in const ['rem_start', 'rem_end', 'rem_days']) {
      await prefs.remove(k);
    }
    await _putOrRemove(prefs, 'profile_company', companyName);
    await _putOrRemove(prefs, 'profile_name', userName);
    await _putOrRemove(prefs, 'profile_id', userId);
  }

  static Future<void> _putOrRemove(SharedPreferences prefs, String key, String value) async {
    final v = value.trim();
    if (v.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, v);
    }
  }
}
