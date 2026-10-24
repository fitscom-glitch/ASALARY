import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/period_summary.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

class WeekHeader extends StatelessWidget {
  const WeekHeader({super.key, required this.monday, required this.summary});
  final DateTime monday;
  final PeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final sunday = DateTime(monday.year, monday.month, monday.day + 6);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tuần ${pad2(monday.day)}/${pad2(monday.month)} – ${pad2(sunday.day)}/${pad2(sunday.month)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Thường ${fmtHours(summary.regular)} · OT ${fmtHours(summary.ot)} · x2 ${fmtHours(summary.dbl)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(
            money(summary.earned),
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.tealMid, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
