import 'package:theo_doi_luong/core/utils/date_utils.dart';
import 'package:theo_doi_luong/data/models/paid_leave.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';

/// Một dòng của báo cáo xuất: ca làm hoặc ngày nghỉ có lương.
class ExportRow {
  const ExportRow.ofRecord(WorkRecord r)
      : record = r,
        leave = null,
        day = null;
  const ExportRow.ofLeave(this.day, PaidLeave l)
      : record = null,
        leave = l;
  final WorkRecord? record;
  final PaidLeave? leave;
  final DateTime? day;

  DateTime get date => dateOnly(record?.start ?? day!);
}

/// Gộp các ca và ngày nghỉ có lương, sắp xếp từ cũ đến mới.
/// Cùng ngày: các ca (theo giờ vào) trước, ngày nghỉ có lương sau.
List<ExportRow> exportRowsAsc(List<WorkRecord> newestFirst, Map<String, PaidLeave> leave) {
  final rows = <ExportRow>[
    for (final r in newestFirst.reversed) ExportRow.ofRecord(r),
    for (final e in leave.entries)
      if (DateTime.tryParse(e.key) case final d?) ExportRow.ofLeave(dateOnly(d), e.value),
  ];
  rows.sort((a, b) {
    final byDay = a.date.compareTo(b.date);
    if (byDay != 0) return byDay;
    final ar = a.record, br = b.record;
    if (ar != null && br != null) return ar.start.compareTo(br.start);
    if (ar != null) return -1;
    if (br != null) return 1;
    return 0;
  });
  return rows;
}
