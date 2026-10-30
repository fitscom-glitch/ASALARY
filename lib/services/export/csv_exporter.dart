import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/paid_leave.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';
import 'package:theo_doi_luong/logic/export_rows.dart';

String buildCsv(List<WorkRecord> newestFirst, {Map<String, PaidLeave> leave = const {}}) {
  String cell(Object? v) => '"${'$v'.replaceAll('"', '""')}"';
  final rows = <List<Object?>>[
    [
      tr('Ngày'), tr('Giờ vào'), tr('Giờ ra'), tr('Loại ngày'), tr('Tổng giờ'), tr('Giờ thường'),
      tr('Giờ OT (x1.5)'), tr('Giờ x2'), tr('Giờ nghỉ có lương'), tr('Lương/giờ (USD)'), tr('Tiền (USD)')
    ],
    for (final x in exportRowsAsc(newestFirst, leave))
      if (x.record case final r?)
        [
          dateFmt.format(r.start),
          timeFmt.format(r.start),
          timeFmt.format(r.end) + (r.overnight ? ' (+1)' : ''),
          dayLabel(r.dayType),
          r.totalHours.toStringAsFixed(2),
          r.regularHours.toStringAsFixed(2),
          r.otHours.toStringAsFixed(2),
          r.doubleHours.toStringAsFixed(2),
          '0.00',
          r.hourlyRate.toStringAsFixed(2),
          r.earned.toStringAsFixed(2),
        ]
      else if (x.leave case final l?)
        [
          dateFmt.format(x.date),
          '',
          '',
          tr('Nghỉ có lương'),
          '0.00',
          '0.00',
          '0.00',
          '0.00',
          l.hours.toStringAsFixed(2),
          l.rate.toStringAsFixed(2),
          l.pay.toStringAsFixed(2),
        ],
  ];
  return '\uFEFF${rows.map((row) => row.map(cell).join(',')).join('\r\n')}';
}
