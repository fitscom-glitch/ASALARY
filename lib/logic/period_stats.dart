import 'package:theo_doi_luong/core/utils/date_utils.dart';
import 'package:theo_doi_luong/data/models/period_summary.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';
import 'package:theo_doi_luong/logic/day_type.dart';
import 'package:theo_doi_luong/logic/summary_calculator.dart';

enum StatsKind { week, month, year }

/// Thống kê chi tiết của một khoảng thời gian [from, to).
class PeriodStats {
  const PeriodStats({
    required this.summary,
    required this.weekdayDays,
    required this.otDays,
    required this.holidayDays,
    required this.idleWeekdays,
    required this.holidayHours,
    required this.holidayPay,
    required this.otherDoubleHours,
    required this.otherDoublePay,
  });

  /// Tổng tiền, giờ và số ca (kèm tiền theo từng loại giờ).
  final PeriodSummary summary;

  /// Số ngày có ít nhất một ca, theo loại ngày của ngày bắt đầu ca.
  final int weekdayDays, otDays, holidayDays;

  /// Số ngày thường (T2–T6, không phải ngày lễ) không có ca làm. Chỉ tính các ngày đã qua.
  final int idleWeekdays;

  /// Ca rơi vào ngày lễ: tổng giờ và tiền (tính x2).
  final double holidayHours, holidayPay;

  /// Giờ x2 ngoài ngày lễ (làm trên 12 giờ trong ngày): giờ và tiền.
  final double otherDoubleHours, otherDoublePay;

  int get workedDays => weekdayDays + otDays + holidayDays;
}

DateTime _nextDay(DateTime d) => DateTime(d.year, d.month, d.day + 1);

/// Tính thống kê cho [from, to). [idleEnd] (không bao gồm) giới hạn các ngày được xét là
/// "ngày thường không có ca": truyền ngày hôm nay cho kỳ hiện tại để không tính hôm nay và tương lai.
PeriodStats computePeriodStats(
  List<WorkRecord> records,
  Set<String> holidays,
  DateTime from,
  DateTime to, {
  required DateTime idleEnd,
}) {
  final byDay = <DateTime, String>{};
  var holidayHours = 0.0, holidayPay = 0.0, otherHours = 0.0, otherPay = 0.0;
  for (final r in records) {
    if (r.start.isBefore(from) || !r.start.isBefore(to)) continue;
    byDay[dateOnly(r.start)] = r.dayType;
    if (r.dayType == 'Lễ') {
      holidayHours += r.totalHours;
      holidayPay += r.earned;
    } else {
      otherHours += r.doubleHours;
      otherPay += r.doublePay;
    }
  }

  var weekdayDays = 0, otDays = 0, holidayDays = 0;
  for (final t in byDay.values) {
    switch (t) {
      case 'Lễ':
        holidayDays++;
      case 'OT':
        otDays++;
      default:
        weekdayDays++;
    }
  }

  var idle = 0;
  final end = idleEnd.isBefore(to) ? idleEnd : to;
  for (var d = from; d.isBefore(end); d = _nextDay(d)) {
    if (dayTypeOf(d, holidays) == 'Thường' && !byDay.containsKey(d)) idle++;
  }

  return PeriodStats(
    summary: summarize(records, from, to),
    weekdayDays: weekdayDays,
    otDays: otDays,
    holidayDays: holidayDays,
    idleWeekdays: idle,
    holidayHours: holidayHours,
    holidayPay: holidayPay,
    otherDoubleHours: otherHours,
    otherDoublePay: otherPay,
  );
}

/// Một tuần (T2–CN) của tháng, chỉ gồm các ngày nằm trong tháng.
class WeekStat {
  const WeekStat({required this.index, required this.start, required this.end, required this.summary});

  /// Tuần thứ mấy trong tháng (bắt đầu từ 1).
  final int index;

  /// Ngày đầu và ngày cuối (bao gồm) của tuần, đã cắt theo tháng.
  final DateTime start, end;
  final PeriodSummary summary;
}

List<WeekStat> weeksOfMonth(List<WorkRecord> records, DateTime from, DateTime to) {
  final out = <WeekStat>[];
  var w = startOfWeek(from, DateTime.monday);
  var i = 1;
  while (w.isBefore(to)) {
    final next = DateTime(w.year, w.month, w.day + 7);
    final s = w.isBefore(from) ? from : w;
    final e = next.isAfter(to) ? to : next; // không bao gồm
    out.add(WeekStat(
      index: i++,
      start: s,
      end: DateTime(e.year, e.month, e.day - 1),
      summary: summarize(records, s, e),
    ));
    w = next;
  }
  return out;
}

/// Số tuần dương lịch (T2–CN) chạm vào [from, endExclusive).
int calendarWeeks(DateTime from, DateTime endExclusive) {
  if (!endExclusive.isAfter(from)) return 0;
  var n = 0;
  for (var w = startOfWeek(from, DateTime.monday); w.isBefore(endExclusive); w = DateTime(w.year, w.month, w.day + 7)) {
    n++;
  }
  return n;
}
