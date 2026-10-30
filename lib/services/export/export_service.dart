import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show Uint8List;

import 'package:file_picker/file_picker.dart' show FilePicker;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:share_plus/share_plus.dart' show Share, XFile;

import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/paid_leave.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';
import 'package:theo_doi_luong/logic/export_range.dart';
import 'package:theo_doi_luong/services/export/csv_exporter.dart';
import 'package:theo_doi_luong/services/export/pdf_exporter.dart';
import 'package:theo_doi_luong/services/export/xlsx_exporter.dart';

Future<({List<int> bytes, String name, String mime})> buildExport(
  List<WorkRecord> newestFirst,
  ExportRange range,
  ExportFormat format, {
  Map<String, PaidLeave> leave = const {},
}) async {
  final stamp = dateFmt.format(DateTime.now());
  switch (format) {
    case ExportFormat.xlsx:
      return (
        bytes: buildXlsx(newestFirst, leave: leave),
        name: 'bang_luong_$stamp.xlsx',
        mime: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    case ExportFormat.pdf:
      return (
        bytes: await buildPdf(
          newestFirst,
          tr('Bảng lương – ${tr(exportRangeLabels[range]!)}'),
          rangeSubtitle(range, newestFirst, leave: leave),
          leave: leave,
        ),
        name: 'bang_luong_$stamp.pdf',
        mime: 'application/pdf',
      );
    case ExportFormat.csv:
      return (
        bytes: utf8.encode(buildCsv(newestFirst, leave: leave)),
        name: 'bang_luong_$stamp.csv',
        mime: 'text/csv',
      );
  }
}

Future<void> shareBytes(List<int> bytes, String name, String mime, {String? subject}) async {
  final dir = await getTemporaryDirectory();
  final file = File(p.join(dir.path, name));
  await file.writeAsBytes(bytes, flush: true);
  // share_plus >= 11: dùng SharePlus.instance.share(ShareParams(files: [...]))
  await Share.shareXFiles([XFile(file.path, mimeType: mime)], subject: subject ?? tr('Bảng lương'));
}

/// Mở hộp thoại hệ thống để người dùng chọn vị trí và lưu file vào máy.
/// Trả về false nếu người dùng hủy.
Future<bool> saveBytes(List<int> bytes, String name) async {
  final saved = await FilePicker.saveFile(
    dialogTitle: tr('Chọn nơi lưu file'),
    fileName: name,
    bytes: Uint8List.fromList(bytes),
  );
  return saved != null;
}
