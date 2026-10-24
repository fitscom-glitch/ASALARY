import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/utils/date_utils.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';
import 'package:theo_doi_luong/logic/pay_calculator.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

String _shortH(double h) {
  final m = (h * 60).round();
  if (m < 60) return '${m}p';
  final hh = m / 60;
  return hh == hh.roundToDouble() ? '${hh.round()}h' : '${hh.toStringAsFixed(1)}h';
}

int _flex(double h) => math.max(1, (h * 60).round());

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.text);
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          Text(text, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      );
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.label,
    required this.today,
    required this.holiday,
    required this.reg,
    required this.ot,
    required this.dbl,
    required this.maxH,
  });
  final String label;
  final bool today, holiday;
  final double reg, ot, dbl, maxH;

  @override
  Widget build(BuildContext context) {
    final total = reg + ot + dbl;
    const barArea = 78.0;
    final h = total <= 0 ? 4.0 : math.max(6.0, barArea * total / maxH);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: today ? AppColors.tealMid.withValues(alpha: 0.08) : null,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 14,
            child: total > 0
                ? Text(_shortH(total),
                    style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w600))
                : null,
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: barArea,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                width: 18,
                height: h,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: total <= 0 ? const Color(0xFFE2E8F0) : null,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: total <= 0
                    ? null
                    : Column(
                        children: [
                          if (dbl > 0) Expanded(flex: _flex(dbl), child: const ColoredBox(color: Colors.deepOrange)),
                          if (ot > 0) Expanded(flex: _flex(ot), child: const ColoredBox(color: Colors.indigo)),
                          if (reg > 0) Expanded(flex: _flex(reg), child: const ColoredBox(color: AppColors.tealMid)),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            holiday ? '$label★' : label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: today ? FontWeight.w700 : FontWeight.w500,
              color: holiday ? Colors.deepOrange : (today ? AppColors.tealMid : AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class WeekOverview extends StatelessWidget {
  const WeekOverview({super.key, required this.records, required this.holidays});
  final List<WorkRecord> records;
  final Set<String> holidays;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = startOfWeek(now, DateTime.monday);
    final sunday = DateTime(monday.year, monday.month, monday.day + 6);
    final next = DateTime(monday.year, monday.month, monday.day + 7);
    final days = [for (var i = 0; i < 7; i++) DateTime(monday.year, monday.month, monday.day + i)];

    final reg = List.filled(7, 0.0), ot = List.filled(7, 0.0), dbl = List.filled(7, 0.0);
    for (final r in records) {
      if (r.start.isBefore(monday) || !r.start.isBefore(next)) continue;
      final i = r.start.weekday - 1;
      reg[i] += r.regularHours;
      ot[i] += r.otHours;
      dbl[i] += r.doubleHours;
    }
    final maxH = math.max(
      10.0,
      [for (var i = 0; i < 7; i++) reg[i] + ot[i] + dbl[i]].fold<double>(0, (a, b) => math.max(a, b)),
    );
    final weekReg = reg.fold<double>(0, (a, b) => a + b);
    final missing = math.max(0.0, 40 - weekReg);
    final noFill = PayCalculator.weekdayHolidayIn(monday, holidays);

    final String note;
    if (missing <= 0) {
      note = 'Đã đủ 40 giờ thường. Giờ làm thêm tính OT.';
    } else if (noFill) {
      note = 'Còn thiếu ${fmtHours(missing)}. Tuần có ngày lễ T2–T6 nên cuối tuần không được bù.';
    } else {
      note = 'Còn thiếu ${fmtHours(missing)}. Thứ 7, CN có thể bù tối đa 8 giờ mỗi ngày.';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Tuần này', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
                Text(
                  '${pad2(monday.day)}/${pad2(monday.month)} – ${pad2(sunday.day)}/${pad2(sunday.month)}',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              spacing: 4,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: _DayBar(
                      label: weekdayShort[i],
                      today: dateOnly(now) == days[i],
                      holiday: holidays.contains(dateFmt.format(days[i])),
                      reg: reg[i],
                      ot: ot[i],
                      dbl: dbl[i],
                      maxH: maxH,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                _Legend(AppColors.tealMid, 'Thường'),
                _Legend(Colors.indigo, 'OT x1.5'),
                _Legend(Colors.deepOrange, 'x2'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: Text('Giờ thường trong tuần', style: TextStyle(color: AppColors.muted))),
                Text('${fmtHours(weekReg)} / 40h', style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: (weekReg / 40).clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: AppColors.tealMid,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(note, style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.35)),
          ],
        ),
      ),
    );
  }
}
