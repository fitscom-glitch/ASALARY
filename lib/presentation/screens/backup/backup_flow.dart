import 'dart:convert';

import 'package:file_selector/file_selector.dart' show openFile;
import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/backup_data.dart';
import 'package:theo_doi_luong/logic/controllers/app_controller.dart';
import 'package:theo_doi_luong/logic/controllers/app_lock.dart';
import 'package:theo_doi_luong/presentation/screens/backup/import_dialog.dart';
import 'package:theo_doi_luong/presentation/screens/backup/paste_backup_dialog.dart';
import 'package:theo_doi_luong/presentation/widgets/toast.dart';
import 'package:theo_doi_luong/services/export/export_service.dart';

/// Các thao tác sao lưu / khôi phục dữ liệu, dùng chung cho trang Sao lưu.
abstract final class BackupFlow {
  static String _fileName() => 'asalary_sao_luu_${dateFmt.format(DateTime.now())}.json';

  /// Lưu file sao lưu vào vị trí người dùng chọn trên máy.
  static Future<void> saveToDevice(BuildContext context, AppController c, AppLock lock) async {
    try {
      final name = _fileName();
      final bytes = utf8.encode(c.buildBackup().toJson());
      final saved = await lock.runExternal(() => saveBytes(bytes, name));
      if (saved && context.mounted) showToast(context, 'Đã lưu file: $name');
    } catch (e) {
      if (context.mounted) showToast(context, 'Không thể xuất file sao lưu: $e');
    }
  }

  /// Gửi file sao lưu qua ứng dụng khác (email, Drive, Zalo...).
  static Future<void> share(BuildContext context, AppController c, AppLock lock) async {
    try {
      final json = c.buildBackup().toJson();
      await lock.runExternal(
        () => shareBytes(utf8.encode(json), _fileName(), 'application/json', subject: tr('Sao lưu dữ liệu')),
      );
    } catch (e) {
      if (context.mounted) showToast(context, 'Không thể xuất file sao lưu: $e');
    }
  }

  static Future<void> importFromFile(BuildContext context, AppController c, AppLock lock) async {
    try {
      final file = await lock.runExternal(() => openFile());
      if (file == null) return;
      final text = await file.readAsString();
      if (!context.mounted) return;
      await _confirmAndImport(context, c, text);
    } catch (e) {
      if (context.mounted) showToast(context, 'Không thể đọc file: $e');
    }
  }

  static Future<void> importFromText(BuildContext context, AppController c) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const PasteBackupDialog(),
    );
    if (text == null || !context.mounted) return;
    await _confirmAndImport(context, c, text);
  }

  static Future<void> _confirmAndImport(BuildContext context, AppController c, String text) async {
    final BackupData data;
    try {
      data = BackupData.parse(text);
    } on FormatException catch (e) {
      showToast(context, e.message);
      return;
    }
    final mode = await showDialog<ImportMode>(
      context: context,
      builder: (_) => ImportDialog(data: data, existing: c.records.length),
    );
    if (mode == null || !context.mounted) return;
    try {
      final r = await c.importBackup(data, replace: mode == ImportMode.replace);
      if (context.mounted) showToast(context, 'Đã nhập ${r.added} ca, bỏ qua ${r.skipped} ca trùng giờ.');
    } catch (e) {
      if (context.mounted) showToast(context, 'Không thể nhập: $e');
    }
  }
}
