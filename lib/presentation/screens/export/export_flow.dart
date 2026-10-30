import 'dart:async';

import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/logic/controllers/app_controller.dart';
import 'package:theo_doi_luong/logic/controllers/app_lock.dart';
import 'package:theo_doi_luong/logic/export_range.dart';
import 'package:theo_doi_luong/presentation/screens/export/export_sheet.dart';
import 'package:theo_doi_luong/presentation/widgets/toast.dart';
import 'package:theo_doi_luong/services/export/export_service.dart';

/// Luồng xuất bảng lương: chọn khoảng thời gian, định dạng và cách xuất
/// (lưu vào vị trí tự chọn trên máy hoặc chia sẻ), rồi tạo và đưa file ra.
abstract final class ExportFlow {
  static Future<void> run(BuildContext context, AppController c, AppLock lock) async {
    if (c.records.isEmpty && c.settings.paidLeave.isEmpty) {
      showToast(context, 'Chưa có dữ liệu để xuất.');
      return;
    }
    final choice = await showModalBottomSheet<({ExportRange range, ExportFormat format, ExportDelivery delivery})>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const ExportSheet(),
    );
    if (choice == null || !context.mounted) return;

    final rs = recordsInRange(c.records, choice.range);
    final leave = leaveInRange(c.settings.paidLeave, choice.range);
    if (rs.isEmpty && leave.isEmpty) {
      showToast(context, 'Không có ca làm nào trong khoảng này.');
      return;
    }

    // Vòng quay chờ trong lúc tạo file (PDF cần tải font).
    final nav = Navigator.of(context);
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(canPop: false, child: Center(child: CircularProgressIndicator())),
    ));
    ({List<int> bytes, String name, String mime})? file;
    String? error;
    try {
      file = await buildExport(rs, choice.range, choice.format, leave: leave);
    } catch (e) {
      error = '$e';
    }
    nav.pop();

    if (file == null) {
      if (context.mounted) {
        showToast(
          context,
          choice.format == ExportFormat.pdf
              ? 'Không thể tạo PDF (kiểm tra đã khai báo font trong pubspec.yaml): $error'
              : 'Không thể tạo file: $error',
        );
      }
      return;
    }

    final out = file;
    if (choice.delivery == ExportDelivery.save) {
      try {
        final saved = await lock.runExternal(() => saveBytes(out.bytes, out.name));
        if (saved && context.mounted) showToast(context, 'Đã lưu file: ${out.name}');
      } catch (e) {
        if (context.mounted) showToast(context, 'Không thể lưu file: $e');
      }
    } else {
      try {
        await lock.runExternal(() => shareBytes(out.bytes, out.name, out.mime));
      } catch (e) {
        if (context.mounted) showToast(context, 'Không thể chia sẻ file: $e');
      }
    }
  }
}
