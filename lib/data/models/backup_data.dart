import 'dart:convert';

import 'package:theo_doi_luong/core/constants/app_constants.dart';
import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/paid_leave.dart';
import 'package:theo_doi_luong/data/models/reminder_config.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';

enum ImportMode { merge, replace }

class BackupData {
  const BackupData({
    required this.records,
    required this.hourlyRate,
    required this.holidays,
    required this.lang,
    required this.exportedAt,
    this.reminders = const ReminderConfig(),
    this.paidLeave = const {},
    this.companyName = '',
    this.userName = '',
    this.userId = '',
  });
  final List<WorkRecord> records;
  final double hourlyRate;
  final Set<String> holidays;
  final String lang;
  final DateTime exportedAt;
  final ReminderConfig reminders;
  final Map<String, PaidLeave> paidLeave;
  final String companyName, userName, userId;

  static const _appId = 'theo_doi_luong';
  static const _format = 1;

  String toJson() => const JsonEncoder.withIndent(' ').convert({
        'app': _appId,
        'format': _format,
        'exportedAt': exportedAt.toIso8601String(),
        'settings': {
          'hourlyRate': hourlyRate,
          'holidays': holidays.toList()..sort(),
          'lang': lang,
          'reminders': reminders.toJson(),
          'paidLeave': PaidLeave.mapToJson(paidLeave),
          'profile': {'company': companyName, 'name': userName, 'id': userId},
        },
        'records': [
          for (final r in records)
            {
              'start': r.start.millisecondsSinceEpoch,
              'end': r.end.millisecondsSinceEpoch,
              'rate': r.hourlyRate,
              'startText': '${dateFmt.format(r.start)} ${timeFmt.format(r.start)}',
              'endText': '${dateFmt.format(r.end)} ${timeFmt.format(r.end)}',
            },
        ],
      });

  /// Đọc và kiểm tra nội dung file sao lưu; ném FormatException kèm thông báo nếu sai.
  static BackupData parse(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw.replaceFirst('\uFEFF', '').trim());
    } catch (_) {
      throw const FormatException('Tệp sao lưu không hợp lệ.');
    }
    if (decoded is! Map<String, dynamic> || decoded['app'] != _appId) {
      throw const FormatException('Đây không phải file sao lưu của ứng dụng này.');
    }
    final fmt = decoded['format'];
    if (fmt is! int || fmt < 1) throw const FormatException('Tệp sao lưu không hợp lệ.');
    if (fmt > _format) throw const FormatException('File sao lưu quá mới, hãy cập nhật ứng dụng.');

    try {
      final st = decoded['settings'];
      final settings = st is Map<String, dynamic> ? st : const <String, dynamic>{};
      final rateRaw = settings['hourlyRate'];
      final rate = (rateRaw is num && rateRaw >= 0 && rateRaw.isFinite) ? rateRaw.toDouble() : kDefaultRate;
      final pf = settings['profile'];
      String profileText(String k) =>
          (pf is Map && pf[k] is String) ? (pf[k] as String).trim() : '';
      final lang = supportedLangs.containsKey(settings['lang']) ? settings['lang'] as String : 'vi';
      final holidays = <String>{};
      final hl = settings['holidays'];
      if (hl is List) {
        for (final h in hl) {
          if (h is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(h)) holidays.add(h);
        }
      }

      final list = decoded['records'];
      if (list is! List || list.length > 200000) {
        throw const FormatException('Dữ liệu trong file bị lỗi.');
      }
      final out = <WorkRecord>[];
      for (final item in list) {
        if (item is! Map) throw const FormatException('Dữ liệu trong file bị lỗi.');
        final s = item['start'];
        final e = item['end'];
        final rt = item['rate'];
        if (s is! int || e is! int || s <= 0 || e <= s || e - s > 72 * 3600 * 1000) {
          throw const FormatException('Dữ liệu trong file bị lỗi.');
        }
        if (rt is! num || rt < 0 || !rt.isFinite) {
          throw const FormatException('Dữ liệu trong file bị lỗi.');
        }
        out.add(WorkRecord(
          start: DateTime.fromMillisecondsSinceEpoch(s),
          end: DateTime.fromMillisecondsSinceEpoch(e),
          dayType: 'Thường', // loại ngày thật do PayCalculator suy ra
          hourlyRate: rt.toDouble(),
        ));
      }

      final ea = decoded['exportedAt'];
      return BackupData(
        records: out,
        hourlyRate: rate,
        holidays: holidays,
        lang: lang,
        reminders: ReminderConfig.fromJson(settings['reminders']),
        paidLeave: PaidLeave.mapFromJson(settings['paidLeave']),
        companyName: profileText('company'),
        userName: profileText('name'),
        userId: profileText('id'),
        exportedAt: (ea is String ? DateTime.tryParse(ea) : null) ?? DateTime.now(),
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Dữ liệu trong file bị lỗi.');
    }
  }
}
