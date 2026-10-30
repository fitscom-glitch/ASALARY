import 'package:theo_doi_luong/core/utils/date_utils.dart';
import 'package:theo_doi_luong/data/models/paid_leave.dart';
import 'package:theo_doi_luong/data/models/period_summary.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';

/// Tổng hợp các ca bắt đầu trong [from, to). Nếu truyền [leave], tiền các ngày nghỉ có lương
/// trong khoảng đó được cộng vào [PeriodSummary.earned] (và ghi riêng ở các trường `leave*`).
PeriodSummary summarize(
  Iterable<WorkRecord> records,
  DateTime from,
  DateTime to, {
  Map<String, PaidLeave> leave = const {},
}) {
  double e = 0, t = 0, r = 0, o = 0, d = 0, rp = 0, op = 0, dp = 0;
  var n = 0;
  for (final x in records) {
    if (x.start.isBefore(from) || !x.start.isBefore(to)) continue;
    e += x.earned;
    t += x.totalHours;
    r += x.regularHours;
    o += x.otHours;
    d += x.doubleHours;
    rp += x.regularPay;
    op += x.otPay;
    dp += x.doublePay;
    n++;
  }
  var lh = 0.0, lp = 0.0, ld = 0;
  for (final entry in leave.entries) {
    final day = DateTime.tryParse(entry.key);
    if (day == null || day.isBefore(from) || !day.isBefore(to)) continue;
    lh += entry.value.hours;
    lp += entry.value.pay;
    ld++;
  }
  lp = (lp * 100).roundToDouble() / 100;
  return PeriodSummary(
    earned: e + lp,
    total: t,
    regular: r,
    ot: o,
    dbl: d,
    regularPay: rp,
    otPay: op,
    dblPay: dp,
    shifts: n,
    leaveHours: lh,
    leavePay: lp,
    leaveDays: ld,
  );
}

/// Tổng hợp theo tuần (cũ đến mới); `asc` phải sắp xếp từ cũ đến mới.
/// Nếu truyền [leave], tuần chỉ có ngày nghỉ có lương cũng được liệt kê và tiền nghỉ được cộng vào [PeriodSummary.earned].
List<(DateTime, PeriodSummary)> weeklySummaries(
  List<WorkRecord> asc, {
  Map<String, PaidLeave> leave = const {},
}) {
  final mondays = <DateTime>{
    for (final r in asc) startOfWeek(r.start, DateTime.monday),
    for (final k in leave.keys)
      if (DateTime.tryParse(k) case final d?) startOfWeek(d, DateTime.monday),
  }.toList()
    ..sort();
  return [
    for (final w in mondays) (w, summarize(asc, w, DateTime(w.year, w.month, w.day + 7), leave: leave)),
  ];
}
