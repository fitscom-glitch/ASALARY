import 'dart:math' as math;

import 'package:theo_doi_luong/core/constants/app_constants.dart';
import 'package:theo_doi_luong/core/utils/date_utils.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';
import 'package:theo_doi_luong/data/preferences/active_shift.dart';
import 'package:theo_doi_luong/logic/day_type.dart';

/// Tính lương (hàm thuần, dễ unit test).
///
///  Mỗi ca được ghi vào NGÀY BẮT ĐẦU. Tuần bắt đầu thứ 2.
///  Loại ngày tự suy ra: Lễ (đánh dấu trong cài đặt) > thứ 7/CN = OT > Thường.
///
///   • Ngày thường (T2–T6): 8 giờ đầu x1 (tối đa 40 giờ thường/tuần, vượt → x1.5);
///     giờ 8–12 x1.5; trên 12 giờ x2. Giờ OT trong ngày KHÔNG dùng để bù giờ thường.
///   • Thứ 7/CN (OT): x1.5, giờ 8–12 x1.5, trên 12 giờ/ngày x2. Nếu T2–T6 chưa đủ
///     40 giờ thường thì tối đa 8 giờ đầu của mỗi ngày cuối tuần được bù vào x1.
///   • Lễ: cả ca x2, không tính vào giờ thường. Tuần có ngày lễ rơi vào T2–T6
///     thì cuối tuần KHÔNG được bù giờ thường (vẫn tính OT bình thường).
abstract final class PayCalculator {
  static const _dailyRegular = 8 * 60;
  static const _dailyOt = 12 * 60;
  static const _weeklyRegular = 40 * 60;

  static List<WorkRecord> calculate(List<WorkRecord> input, Set<String> holidays) {
    final sorted = [...input]..sort((a, b) {
        final c = a.start.compareTo(b.start);
        return c != 0 ? c : (a.id ?? 0).compareTo(b.id ?? 0);
      });
    final daily = <DateTime, int>{};
    final weekly = <DateTime, int>{};
    return [for (final r in sorted) _one(r, holidays, daily, weekly)];
  }

  /// Tuần (bắt đầu thứ 2) có ngày lễ rơi vào T2–T6?
  static bool weekdayHolidayIn(DateTime monday, Set<String> holidays) {
    for (var i = 0; i < 5; i++) {
      final d = DateTime(monday.year, monday.month, monday.day + i);
      if (holidays.contains(dateFmt.format(d))) return true;
    }
    return false;
  }

  static WorkRecord _one(
    WorkRecord r,
    Set<String> holidays,
    Map<DateTime, int> daily,
    Map<DateTime, int> weekly,
  ) {
    final day = dateOnly(r.start);
    final week = startOfWeek(r.start, DateTime.monday);
    final type = dayTypeOf(r.start, holidays);
    var remaining = r.minutes;
    var reg = 0, ot = 0, dbl = 0;

    if (type == 'Lễ') {
      // Cả ca x2, độc lập: không cộng vào bộ đếm ngày/tuần.
      dbl = remaining;
      remaining = 0;
    } else {
      final weekend = type == 'OT';
      final canFill = weekend && !weekdayHolidayIn(week, holidays);

      while (remaining > 0) {
        final used = daily[day] ?? 0;
        final int room;
        if (used >= _dailyOt) {
          room = remaining;
        } else if (used < _dailyRegular) {
          room = _dailyRegular - used;
        } else {
          room = _dailyOt - used;
        }
        final chunk = math.min(remaining, room);

        if (used >= _dailyOt) {
          dbl += chunk;
        } else if (used >= _dailyRegular) {
          ot += chunk; // giờ 8–12 trong ngày: x1.5
        } else if (weekend) {
          // 8 giờ đầu của ngày cuối tuần: bù vào giờ thường còn thiếu của tuần
          // (tối đa 40 giờ) trước, phần còn lại x1.5.
          var fill = 0;
          if (canFill) {
            final usedWeek = weekly[week] ?? 0;
            fill = math.min(chunk, math.max(0, _weeklyRegular - usedWeek));
            reg += fill;
            weekly[week] = usedWeek + fill;
          }
          ot += chunk - fill;
        } else {
          // Ngày thường, 8 giờ đầu: giờ thường, tối đa 40 giờ/tuần, vượt → OT.
          final usedWeek = weekly[week] ?? 0;
          final regular = math.min(chunk, math.max(0, _weeklyRegular - usedWeek));
          reg += regular;
          ot += chunk - regular;
          weekly[week] = usedWeek + regular;
        }
        daily[day] = used + chunk;
        remaining -= chunk;
      }
    }

    final raw = (reg + ot * kOtMultiplier + dbl * kDoubleMultiplier) / 60.0 * r.hourlyRate;
    return r.withPay(
      total: r.minutes / 60.0,
      regular: reg / 60.0,
      ot: ot / 60.0,
      dbl: dbl / 60.0,
      earned: (raw * 100).roundToDouble() / 100,
      dayType: type,
    );
  }
}

/// Ước tính tiền của ca đang làm tính đến `now` (chỉ tính lại trong tuần của ca).
double estimateActive(
  List<WorkRecord> records,
  ActiveShift a,
  Set<String> holidays,
  DateTime now,
) {
  final end = floorMinute(now);
  if (!end.isAfter(a.start)) return 0;
  final week = startOfWeek(a.start, DateTime.monday);
  final next = DateTime(week.year, week.month, week.day + 7);
  const probeId = -1;
  final raw = [
    for (final r in records)
      if (!r.start.isBefore(week) && r.start.isBefore(next)) r,
    WorkRecord(id: probeId, start: a.start, end: end, dayType: 'Thường', hourlyRate: a.rate),
  ];
  return PayCalculator.calculate(raw, holidays).firstWhere((r) => r.id == probeId).earned;
}
