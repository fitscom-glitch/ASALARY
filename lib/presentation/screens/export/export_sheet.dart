import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/logic/export_range.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

class ExportSheet extends StatefulWidget {
  const ExportSheet({super.key});

  @override
  State<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<ExportSheet> {
  ExportRange _range = ExportRange.month;
  ExportDelivery _delivery = ExportDelivery.save;

  void _pick(ExportFormat f) => Navigator.pop(context, (range: _range, format: f, delivery: _delivery));

  Widget _tile(IconData icon, Color color, String title, String subtitle, ExportFormat f) => Card(
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _pick(f),
        ),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text('Xuất dữ liệu', style: Theme.of(context).textTheme.titleLarge),
              const Text('Khoảng thời gian', style: TextStyle(color: AppColors.muted)),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final r in ExportRange.values)
                    ChoiceChip(
                      label: Text(exportRangeLabels[r]!),
                      selected: _range == r,
                      onSelected: (_) => setState(() => _range = r),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Cách xuất', style: TextStyle(color: AppColors.muted)),
              SegmentedButton<ExportDelivery>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ExportDelivery.save,
                    icon: Icon(Icons.save_alt_rounded),
                    label: Text('Lưu vào máy'),
                  ),
                  ButtonSegment(
                    value: ExportDelivery.share,
                    icon: Icon(Icons.ios_share_rounded),
                    label: Text('Chia sẻ'),
                  ),
                ],
                selected: {_delivery},
                onSelectionChanged: (v) => setState(() => _delivery = v.first),
              ),
              const SizedBox(height: 4),
              const Text('Định dạng', style: TextStyle(color: AppColors.muted)),
              _tile(Icons.table_chart_rounded, Colors.green.shade700, 'Excel (.xlsx)',
                  'Chi tiết từng ca và tổng hợp theo tuần', ExportFormat.xlsx),
              _tile(Icons.picture_as_pdf_rounded, Colors.red.shade700, 'PDF',
                  'Báo cáo để in hoặc gửi (chạy offline)', ExportFormat.pdf),
              _tile(Icons.description_outlined, Colors.blueGrey, 'CSV',
                  'Văn bản thuần, mở được bằng Excel hoặc Google Sheets', ExportFormat.csv),
            ],
          ),
        ),
      );
}
