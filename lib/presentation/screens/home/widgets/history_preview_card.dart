import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';
import 'package:theo_doi_luong/presentation/theme/day_type_style.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

/// Thẻ trên trang chủ: bấm vào để mở trang lịch sử đầy đủ.
class HistoryPreviewCard extends StatelessWidget {
  const HistoryPreviewCard({super.key, required this.records, required this.onOpen});
  final List<WorkRecord> records;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final recent = records.take(3).toList();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Lịch sử ca làm', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                  Text('${records.length} ca', style: const TextStyle(color: AppColors.muted)),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                ],
              ),
              if (recent.isEmpty)
                const Text(
                  'Bấm “Vào ca” để chấm công hoặc thêm một ca thủ công.',
                  style: TextStyle(color: AppColors.muted),
                )
              else
                for (final r in recent)
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 44,
                        decoration: BoxDecoration(
                          color: typeColor(r.dayType).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              weekdayShort[r.start.weekday - 1],
                              style: TextStyle(fontSize: 10, color: typeColor(r.dayType)),
                            ),
                            Text(
                              '${r.start.day}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: typeColor(r.dayType),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${timeFmt.format(r.start)} – ${timeFmt.format(r.end)}${r.overnight ? ' (+1)' : ''}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(money(r.earned), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('Xem tất cả', style: TextStyle(color: AppColors.tealMid, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
