import 'package:excel/excel.dart' as xl;

import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/paid_leave.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';
import 'package:theo_doi_luong/logic/export_rows.dart';
import 'package:theo_doi_luong/logic/summary_calculator.dart';

List<int> buildXlsx(List<WorkRecord> newestFirst, {Map<String, PaidLeave> leave = const {}}) {
  final asc = newestFirst.reversed.toList();
  final book = xl.Excel.createExcel();
  book.rename('Sheet1', tr('Ca làm'));
  final shifts = book[tr('Ca làm')];
  final weeks = book[tr('Theo tuần')];

  final head = xl.CellStyle(
    bold: true,
    fontColorHex: xl.ExcelColor.white,
    backgroundColorHex: xl.ExcelColor.fromHexString('#0F766E'),
    horizontalAlign: xl.HorizontalAlign.Center,
  );
  final bold = xl.CellStyle(bold: true);

  void put(xl.Sheet sh, int col, int row, xl.CellValue v, [xl.CellStyle? st]) => sh.updateCell(
        xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        v,
        cellStyle: st,
      );
  xl.CellValue t(String v) => xl.TextCellValue(v);
  xl.CellValue n(double v) => xl.DoubleCellValue(double.parse(v.toStringAsFixed(2)));

  // Sheet 1: chi tiết từng ca
  final h1 = [
    tr('Ngày'), tr('Thứ'), tr('Giờ vào'), tr('Giờ ra'), tr('Loại ngày'), tr('Tổng giờ'),
    tr('Giờ thường'), tr('Giờ OT (x1.5)'), tr('Giờ x2'), tr('Giờ nghỉ có lương'), tr('Lương/giờ (USD)'), tr('Tiền (USD)')
  ];
  for (var c = 0; c < h1.length; c++) {
    put(shifts, c, 0, t(h1[c]), head);
    shifts.setColumnWidth(c, c == 0 ? 14 : 13);
  }
  // Ngày nghỉ có lương: nền xanh nhạt để dễ phân biệt với ca làm.
  final leaveStyle = xl.CellStyle(backgroundColorHex: xl.ExcelColor.fromHexString('#E0F2FE'));
  var row = 1;
  double sTotal = 0, sReg = 0, sOt = 0, sDbl = 0, sLeave = 0, sEarned = 0;
  for (final x in exportRowsAsc(newestFirst, leave)) {
    final r = x.record;
    if (r != null) {
      put(shifts, 0, row, t(dmyFmt.format(r.start)));
      put(shifts, 1, row, t(weekdayShort[r.start.weekday - 1]));
      put(shifts, 2, row, t(timeFmt.format(r.start)));
      put(shifts, 3, row, t('${timeFmt.format(r.end)}${r.overnight ? ' (+1)' : ''}'));
      put(shifts, 4, row, t(dayLabel(r.dayType)));
      put(shifts, 5, row, n(r.totalHours));
      put(shifts, 6, row, n(r.regularHours));
      put(shifts, 7, row, n(r.otHours));
      put(shifts, 8, row, n(r.doubleHours));
      put(shifts, 9, row, n(0));
      put(shifts, 10, row, n(r.hourlyRate));
      put(shifts, 11, row, n(r.earned));
      sTotal += r.totalHours;
      sReg += r.regularHours;
      sOt += r.otHours;
      sDbl += r.doubleHours;
      sEarned += r.earned;
    } else if (x.leave case final l?) {
      final d = x.date;
      put(shifts, 0, row, t(dmyFmt.format(d)), leaveStyle);
      put(shifts, 1, row, t(weekdayShort[d.weekday - 1]), leaveStyle);
      put(shifts, 2, row, t(''), leaveStyle);
      put(shifts, 3, row, t(''), leaveStyle);
      put(shifts, 4, row, t(tr('Nghỉ có lương')), leaveStyle);
      for (var c = 5; c <= 8; c++) {
        put(shifts, c, row, n(0), leaveStyle);
      }
      put(shifts, 9, row, n(l.hours), leaveStyle);
      put(shifts, 10, row, n(l.rate), leaveStyle);
      put(shifts, 11, row, n(l.pay), leaveStyle);
      sLeave += l.hours;
      sEarned += l.pay;
    }
    row++;
  }
  put(shifts, 0, row, t(tr('TỔNG')), bold);
  put(shifts, 5, row, n(sTotal), bold);
  put(shifts, 6, row, n(sReg), bold);
  put(shifts, 7, row, n(sOt), bold);
  put(shifts, 8, row, n(sDbl), bold);
  put(shifts, 9, row, n(sLeave), bold);
  put(shifts, 11, row, n(sEarned), bold);

  // Sheet 2: tổng hợp theo tuần
  final h2 = [
    tr('Tuần'), tr('Số ca'), tr('Tổng giờ'), tr('Giờ thường'), tr('Giờ OT (x1.5)'), tr('Giờ x2'),
    tr('Giờ nghỉ có lương'), tr('Tiền (USD)')
  ];
  for (var c = 0; c < h2.length; c++) {
    put(weeks, c, 0, t(h2[c]), head);
    weeks.setColumnWidth(c, c == 0 ? 24 : 14);
  }
  var wr = 1;
  for (final (monday, sum) in weeklySummaries(asc, leave: leave)) {
    put(weeks, 0, wr, t(weekLabel(monday)));
    put(weeks, 1, wr, xl.IntCellValue(sum.shifts));
    put(weeks, 2, wr, n(sum.total));
    put(weeks, 3, wr, n(sum.regular));
    put(weeks, 4, wr, n(sum.ot));
    put(weeks, 5, wr, n(sum.dbl));
    put(weeks, 6, wr, n(sum.leaveHours));
    put(weeks, 7, wr, n(sum.earned));
    wr++;
  }

  final bytes = book.save();
  if (bytes == null) throw StateError(tr('Không tạo được file Excel'));
  return bytes;
}
