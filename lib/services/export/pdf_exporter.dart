import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;

import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/paid_leave.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';
import 'package:theo_doi_luong/logic/export_rows.dart';
import 'package:theo_doi_luong/logic/summary_calculator.dart';

/// Chạy hoàn toàn offline: dùng font Liberation Sans đóng gói sẵn trong assets (có tiếng Việt).
Future<List<int>> buildPdf(
  List<WorkRecord> newestFirst,
  String title,
  String subtitle, {
  Map<String, PaidLeave> leave = const {},
}) async {
  final asc = newestFirst.reversed.toList();
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/LiberationSans-Regular.ttf'));
  final boldFont = pw.Font.ttf(await rootBundle.load('assets/fonts/LiberationSans-Bold.ttf'));
  final doc = pw.Document(theme: pw.ThemeData.withFont(base: regular, bold: boldFont));

  final teal = pdf.PdfColor.fromHex('#0F766E');
  final grey = pdf.PdfColor.fromHex('#64748B');
  final light = pdf.PdfColor.fromHex('#F1F5F9');
  final sum = summarize(asc, DateTime(1970), DateTime(3000), leave: leave);

  pw.Widget stat(String label, String value) => pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(color: light),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: pw.TextStyle(fontSize: 9, color: grey)),
              pw.SizedBox(height: 3),
              pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
      );

  pw.Widget table(List<String> headers, List<List<String>> data) => pw.TableHelper.fromTextArray(
        headers: headers,
        data: data,
        headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: pdf.PdfColors.white),
        headerDecoration: pw.BoxDecoration(color: teal),
        cellStyle: const pw.TextStyle(fontSize: 9),
        oddRowDecoration: pw.BoxDecoration(color: light),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        cellAlignments: {
          0: pw.Alignment.centerLeft,
          for (var i = 1; i < headers.length; i++) i: pw.Alignment.centerRight,
        },
      );

  doc.addPage(
    pw.MultiPage(
      pageFormat: pdf.PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          tr('Trang ${ctx.pageNumber}/${ctx.pagesCount}'),
          style: pw.TextStyle(fontSize: 9, color: grey),
        ),
      ),
      build: (ctx) => [
        pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: teal)),
        if (subtitle.isNotEmpty) pw.Text(subtitle, style: pw.TextStyle(fontSize: 10, color: grey)),
        pw.SizedBox(height: 14),
        pw.Row(
          children: [
            stat(tr('Tổng tiền'), money(sum.earned)),
            pw.SizedBox(width: 8),
            stat(tr('Tổng giờ'), fmtHours(sum.total)),
            pw.SizedBox(width: 8),
            stat(tr('Giờ thường'), fmtHours(sum.regular)),
            pw.SizedBox(width: 8),
            stat('OT x1.5', fmtHours(sum.ot)),
            pw.SizedBox(width: 8),
            stat('x2', fmtHours(sum.dbl)),
            if (sum.leaveDays > 0) ...[
              pw.SizedBox(width: 8),
              stat(tr('Nghỉ có lương'), fmtHours(sum.leaveHours)),
            ],
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Text(tr('Theo tuần'), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        table(
          [tr('Tuần'), tr('Số ca'), tr('Tổng giờ'), tr('Thường'), 'OT x1.5', 'x2', tr('Nghỉ'), tr('Tiền')],
          [
            for (final (monday, w) in weeklySummaries(asc, leave: leave))
              [
                weekLabel(monday),
                '${w.shifts}',
                fmtHours(w.total),
                fmtHours(w.regular),
                fmtHours(w.ot),
                fmtHours(w.dbl),
                fmtHours(w.leaveHours),
                money(w.earned),
              ],
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Text(tr('Chi tiết ca làm'), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        table(
          [tr('Ngày'), tr('Vào'), tr('Ra'), tr('Loại'), tr('Thường'), 'OT x1.5', 'x2', tr('Nghỉ'), tr('Lương/giờ'), tr('Tiền')],
          [
            for (final x in exportRowsAsc(newestFirst, leave))
              if (x.record case final r?)
                [
                  '${weekdayShort[r.start.weekday - 1]} ${dmyFmt.format(r.start)}',
                  timeFmt.format(r.start),
                  '${timeFmt.format(r.end)}${r.overnight ? ' (+1)' : ''}',
                  dayLabel(r.dayType),
                  fmtHours(r.regularHours),
                  fmtHours(r.otHours),
                  fmtHours(r.doubleHours),
                  '',
                  money(r.hourlyRate),
                  money(r.earned),
                ]
              else if (x.leave case final l?)
                [
                  '${weekdayShort[x.date.weekday - 1]} ${dmyFmt.format(x.date)}',
                  '',
                  '',
                  tr('Nghỉ có lương'),
                  '',
                  '',
                  '',
                  fmtHours(l.hours),
                  money(l.rate),
                  money(l.pay),
                ],
          ],
        ),
      ],
    ),
  );
  return doc.save();
}
