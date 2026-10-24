import 'package:theo_doi_luong/core/utils/date_utils.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';

enum CompareKind { week, month, year }

/// (từ, đến) với đến là mốc không bao gồm.
(DateTime, DateTime) periodBounds(CompareKind k, DateTime anchor) {
  switch (k) {
    case CompareKind.week:
      final w = startOfWeek(anchor, DateTime.monday);
      return (w, DateTime(w.year, w.month, w.day + 7));
    case CompareKind.month:
      return (DateTime(anchor.year, anchor.month), DateTime(anchor.year, anchor.month + 1));
    case CompareKind.year:
      return (DateTime(anchor.year), DateTime(anchor.year + 1));
  }
}

DateTime shiftPeriod(CompareKind k, DateTime anchor, int delta) {
  switch (k) {
    case CompareKind.week:
      return DateTime(anchor.year, anchor.month, anchor.day + 7 * delta);
    case CompareKind.month:
      return DateTime(anchor.year, anchor.month + delta);
    case CompareKind.year:
      return DateTime(anchor.year + delta);
  }
}

String periodTitle(CompareKind k, DateTime anchor) {
  final b = periodBounds(k, anchor);
  switch (k) {
    case CompareKind.week:
      final sun = DateTime(b.$1.year, b.$1.month, b.$1.day + 6);
      return 'Tuần ${pad2(b.$1.day)}/${pad2(b.$1.month)} – ${pad2(sun.day)}/${pad2(sun.month)}/${sun.year}';
    case CompareKind.month:
      return 'Tháng ${pad2(anchor.month)}/${anchor.year}';
    case CompareKind.year:
      return 'Năm ${anchor.year}';
  }
}
