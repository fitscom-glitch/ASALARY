import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/period_summary.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

class _MetricCell extends StatelessWidget {
  const _MetricCell(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      );
}

class RangeSummaryCard extends StatelessWidget {
  const RangeSummaryCard({super.key, required this.summary, required this.rangeText});
  final PeriodSummary summary;
  final String rangeText;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Tổng kết', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  Flexible(child: Text(rangeText, style: const TextStyle(color: AppColors.muted, fontSize: 12))),
                ],
              ),
              Text(money(summary.earned), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
              Wrap(
                spacing: 22,
                runSpacing: 10,
                children: [
                  _MetricCell('Số ca', '${summary.shifts}'),
                  _MetricCell('Tổng giờ', fmtHours(summary.total)),
                  _MetricCell('Thường', fmtHours(summary.regular)),
                  _MetricCell('OT x1.5', fmtHours(summary.ot)),
                  _MetricCell('x2', fmtHours(summary.dbl)),
                  if (summary.leaveDays > 0) _MetricCell('Nghỉ có lương', money(summary.leavePay)),
                ],
              ),
            ],
          ),
        ),
      );
}
