import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';

String buildCsv(List<WorkRecord> newestFirst) {
  String cell(Object? v) => '"${'$v'.replaceAll('"', '""')}"';
  final rows = <List<Object?>>[
    [
      tr('Ngày'), tr('Giờ vào'), tr('Giờ ra'), tr('Loại ngày'), tr('Tổng giờ'), tr('Giờ thường'),
      tr('Giờ OT (x1.5)'), tr('Giờ x2'), tr('Lương/giờ (USD)'), tr('Tiền (USD)')
    ],
    for (final r in newestFirst.reversed)
      [
        dateFmt.format(r.start),
        timeFmt.format(r.start),
        timeFmt.format(r.end) + (r.overnight ? ' (+1)' : ''),
        dayLabel(r.dayType),
        r.totalHours.toStringAsFixed(2),
        r.regularHours.toStringAsFixed(2),
        r.otHours.toStringAsFixed(2),
        r.doubleHours.toStringAsFixed(2),
        r.hourlyRate.toStringAsFixed(2),
        r.earned.toStringAsFixed(2),
      ],
  ];
  return '\uFEFF${rows.map((row) => row.map(cell).join(',')).join('\r\n')}';
}
