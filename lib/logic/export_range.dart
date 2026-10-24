import 'package:theo_doi_luong/core/utils/date_utils.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';

enum ExportRange { week, month, lastMonth, year, all }

enum ExportFormat { csv, xlsx, pdf }

/// Cách đưa file ra ngoài: lưu vào vị trí người dùng chọn, hoặc chia sẻ qua ứng dụng khác.
enum ExportDelivery { save, share }

const exportRangeLabels = {
  ExportRange.week: 'Tuần này',
  ExportRange.month: 'Tháng này',
  ExportRange.lastMonth: 'Tháng trước',
  ExportRange.year: 'Năm nay',
  ExportRange.all: 'Tất cả',
};

/// (từ, đến) với đến là mốc không bao gồm; null nghĩa là tất cả.
(DateTime, DateTime)? exportBounds(ExportRange r, DateTime now) {
  switch (r) {
    case ExportRange.week:
      final w = startOfWeek(now, DateTime.monday);
      return (w, DateTime(w.year, w.month, w.day + 7));
    case ExportRange.month:
      return (DateTime(now.year, now.month), DateTime(now.year, now.month + 1));
    case ExportRange.lastMonth:
      return (DateTime(now.year, now.month - 1), DateTime(now.year, now.month));
    case ExportRange.year:
      return (DateTime(now.year), DateTime(now.year + 1));
    case ExportRange.all:
      return null;
  }
}

List<WorkRecord> recordsInRange(List<WorkRecord> all, ExportRange r) {
  final b = exportBounds(r, DateTime.now());
  if (b == null) return all;
  return [
    for (final x in all)
      if (!x.start.isBefore(b.$1) && x.start.isBefore(b.$2)) x
  ];
}

/// `newestFirst` là danh sách đã lọc, mới nhất trước.
String rangeSubtitle(ExportRange r, List<WorkRecord> newestFirst) {
  final b = exportBounds(r, DateTime.now());
  if (b != null) {
    final last = DateTime(b.$2.year, b.$2.month, b.$2.day - 1);
    return '${dmyFmt.format(b.$1)} – ${dmyFmt.format(last)}';
  }
  if (newestFirst.isEmpty) return '';
  return '${dmyFmt.format(newestFirst.last.start)} – ${dmyFmt.format(newestFirst.first.start)}';
}
