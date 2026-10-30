import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/period_summary.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

/// Tiêu đề tháng / tuần có thể bấm để mở rộng hoặc thu gọn danh sách bên dưới.
class PeriodHeader extends StatelessWidget {
  const PeriodHeader({
    super.key,
    required this.title,
    required this.summary,
    required this.expanded,
    required this.onTap,
    this.isMonth = false,
    this.indent = 0,
  });

  final String title;
  final PeriodSummary summary;
  final bool expanded;
  final VoidCallback onTap;

  /// Tháng được tô nổi hơn tuần.
  final bool isMonth;

  /// Thụt lề khi tuần nằm trong một tháng.
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.fromLTRB(indent, 0, 0, 8),
      clipBehavior: Clip.antiAlias,
      color: isMonth ? AppColors.tealMid.withValues(alpha: 0.10) : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: isMonth ? 16 : 14.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Thường ${fmtHours(summary.regular)} · OT ${fmtHours(summary.ot)} · x2 ${fmtHours(summary.dbl)}'
                      '${summary.leaveDays > 0 ? ' · Nghỉ ${fmtHours(summary.leaveHours)}' : ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Text(
                money(summary.earned),
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.tealMid, fontSize: 15),
              ),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                child: const Icon(Icons.expand_more_rounded, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
