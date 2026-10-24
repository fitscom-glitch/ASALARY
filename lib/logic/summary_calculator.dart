import 'package:theo_doi_luong/core/utils/date_utils.dart';
import 'package:theo_doi_luong/data/models/period_summary.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';

PeriodSummary summarize(Iterable<WorkRecord> records, DateTime from, DateTime to) {
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
  return PeriodSummary(
    earned: e,
    total: t,
    regular: r,
    ot: o,
    dbl: d,
    regularPay: rp,
    otPay: op,
    dblPay: dp,
    shifts: n,
  );
}

/// Tổng hợp theo tuần; `asc` phải sắp xếp từ cũ đến mới.
List<(DateTime, PeriodSummary)> weeklySummaries(List<WorkRecord> asc) {
  final out = <(DateTime, PeriodSummary)>[];
  DateTime? current;
  for (final r in asc) {
    final w = startOfWeek(r.start, DateTime.monday);
    if (current != w) {
      current = w;
      out.add((w, summarize(asc, w, DateTime(w.year, w.month, w.day + 7))));
    }
  }
  return out;
}
