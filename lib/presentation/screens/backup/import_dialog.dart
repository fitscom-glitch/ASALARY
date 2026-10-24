import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/backup_data.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

class ImportDialog extends StatelessWidget {
  const ImportDialog({super.key, required this.data, required this.existing});
  final BackupData data;
  final int existing;

  @override
  Widget build(BuildContext context) {
    final rs = data.records;
    String range = '';
    if (rs.isNotEmpty) {
      var first = rs.first.start, last = rs.first.start;
      for (final r in rs) {
        if (r.start.isBefore(first)) first = r.start;
        if (r.start.isAfter(last)) last = r.start;
      }
      range = '${dmyFmt.format(first)} – ${dmyFmt.format(last)}';
    }
    final exported = '${dmyFmt.format(data.exportedAt)} ${timeFmt.format(data.exportedAt)}';
    return AlertDialog(
      title: const Text('Nhập dữ liệu'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Text('Tìm thấy ${rs.length} ca làm', style: const TextStyle(fontWeight: FontWeight.w700)),
            if (range.isNotEmpty) Text(range, style: const TextStyle(color: AppColors.muted)),
            Text('Xuất lúc $exported', style: const TextStyle(color: AppColors.muted)),
            Text('Hiện có $existing ca trong ứng dụng.'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.pop(context, ImportMode.merge),
              child: const Text('Gộp vào dữ liệu hiện có'),
            ),
            const Text('Ca trùng giờ với ca đã có sẽ bị bỏ qua.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 6),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => Navigator.pop(context, ImportMode.replace),
              child: const Text('Thay thế toàn bộ'),
            ),
            const Text(
              'Xóa hết dữ liệu hiện tại và dùng dữ liệu trong file (kể cả cài đặt).',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
      ],
    );
  }
}
