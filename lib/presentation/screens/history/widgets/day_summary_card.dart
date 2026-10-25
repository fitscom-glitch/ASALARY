import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/period_summary.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

/// Thống kê một ngày, đặt dưới các ca của ngày đó: số ca, giờ và tiền theo từng loại
/// (thường, OT x1.5, x2) và tổng tiền trong ngày.
///
/// Mặc định thu gọn, chỉ hiện dòng "Tổng cộng"; bấm vào để mở rộng đầy đủ (và bấm lần nữa để thu lại).
class DaySummaryCard extends StatelessWidget {
  const DaySummaryCard({
    super.key,
    required this.date,
    required this.summary,
    this.expanded = true,
    this.onTap,
  });
  final DateTime date;
  final PeriodSummary summary;
  final bool expanded;

  /// null: bảng luôn mở đầy đủ và không bấm được (dùng trong bảng chi tiết ngày).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final collapsible = onTap != null;
    final expanded = this.expanded || !collapsible;
    final total = _Row(label: 'Tổng cộng', hours: fmtHours(s.total), pay: money(s.earned), color: AppColors.tealDark, strong: true);
    final Widget chevron = !collapsible
        ? const SizedBox(width: 8)
        : AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 180),
            child: const Icon(Icons.expand_more_rounded, color: AppColors.muted),
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: AppColors.tealMid.withValues(alpha: 0.07),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.tealMid.withValues(alpha: 0.2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.topCenter,
              child: expanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.summarize_outlined, size: 18, color: AppColors.tealMid),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text('Thống kê ngày', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.tealDark)),
                            ),
                            Text(
                              '${weekdayShort[date.weekday - 1]} ${dmyFmt.format(date)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.muted),
                            ),
                            chevron,
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 4),
                              _Row(label: 'Số ca', hours: '${s.shifts}', pay: '', color: AppColors.muted, muted: true, isCount: true),
                              _Row(label: 'Thường', hours: fmtHours(s.regular), pay: money(s.regularPay), color: AppColors.tealMid, muted: s.regular <= 0),
                              _Row(label: 'OT x1.5', hours: fmtHours(s.ot), pay: money(s.otPay), color: Colors.indigo, muted: s.ot <= 0),
                              _Row(label: 'x2', hours: fmtHours(s.dbl), pay: money(s.dblPay), color: Colors.deepOrange, muted: s.dbl <= 0),
                              const Divider(height: 16),
                              total,
                            ],
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: total),
                        chevron,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.hours,
    required this.pay,
    required this.color,
    this.muted = false,
    this.strong = false,
    this.isCount = false,
  });
  final String label, hours, pay;
  final Color color;
  final bool muted, strong, isCount;

  @override
  Widget build(BuildContext context) {
    final fg = muted ? AppColors.muted : Colors.black87;
    final style = TextStyle(
      fontSize: strong ? 15 : 13.5,
      fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
      color: strong ? AppColors.tealDark : fg,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: strong ? Colors.transparent : color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: style.copyWith(fontWeight: strong ? FontWeight.w800 : FontWeight.w500))),
          SizedBox(width: 64, child: Text(hours, textAlign: TextAlign.right, style: style)),
          SizedBox(width: 88, child: Text(isCount ? '' : pay, textAlign: TextAlign.right, style: style)),
        ],
      ),
    );
  }
}
