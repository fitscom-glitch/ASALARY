import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/core/utils/date_utils.dart';
import 'package:theo_doi_luong/core/utils/diff_format.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/period_summary.dart';
import 'package:theo_doi_luong/logic/controllers/app_controller.dart';
import 'package:theo_doi_luong/logic/period_stats.dart';
import 'package:theo_doi_luong/logic/period_utils.dart';
import 'package:theo_doi_luong/logic/summary_calculator.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';
import 'package:theo_doi_luong/presentation/widgets/pill.dart';
import 'package:theo_doi_luong/presentation/widgets/settings_widgets.dart';

/// Bảng thống kê chi tiết của một tháng hoặc một năm (mở từ ô "Tháng này" / "Năm nay").
class PeriodStatsPage extends StatefulWidget {
  const PeriodStatsPage({super.key, required this.c, required this.kind});
  final AppController c;
  final StatsKind kind;

  @override
  State<PeriodStatsPage> createState() => _PeriodStatsPageState();
}

class _PeriodStatsPageState extends State<PeriodStatsPage> {
  DateTime _anchor = DateTime.now();

  bool get _isMonth => widget.kind == StatsKind.month;
  CompareKind get _ck => _isMonth ? CompareKind.month : CompareKind.year;

  void _move(int delta) => setState(() => _anchor = shiftPeriod(_ck, _anchor, delta));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_isMonth ? 'Thống kê tháng' : 'Thống kê năm')),
        body: ListenableBuilder(listenable: widget.c, builder: (context, _) => _body(context)),
      );

  Widget _body(BuildContext context) {
    final records = widget.c.records;
    final holidays = widget.c.settings.holidays;
    final today = dateOnly(DateTime.now());

    final (from, to) = periodBounds(_ck, _anchor);
    final (pFrom, pTo) = periodBounds(_ck, shiftPeriod(_ck, _anchor, -1));
    final isCurrent = !today.isBefore(from) && today.isBefore(to);
    final isFuture = today.isBefore(from);

    // Các ngày được xét là "ngày thường không có ca": chỉ những ngày đã qua (không gồm hôm nay).
    final idleEnd = isCurrent ? today : (isFuture ? from : to);
    final stats = computePeriodStats(records, holidays, from, to, idleEnd: idleEnd);

    // Kỳ trước: tiền so với cả kỳ trước; số ngày không có ca so với cùng khoảng thời gian đã qua.
    final prevIdleEnd = (!_isMonth && isCurrent) ? DateTime(pFrom.year, today.month, today.day) : pTo;
    final prev = computePeriodStats(records, holidays, pFrom, pTo, idleEnd: prevIdleEnd);

    final s = stats.summary;
    final canNext = !isCurrent && !isFuture;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      children: [
        _PeriodNav(
          title: periodTitle(_ck, _anchor),
          onPrev: from.year > 2020 ? () => _move(-1) : null,
          onNext: canNext ? () => _move(1) : null,
        ),
        const SizedBox(height: 8),
        _HeaderCard(
          summary: s,
          prev: prev.summary,
          compareLabel: _isMonth ? 'So với tháng trước' : 'So với năm trước',
          prevTitle: periodTitle(_ck, shiftPeriod(_ck, _anchor, -1)),
        ),
        if (s.shifts == 0)
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 10, 8, 0),
            child: Text('Chưa có ca làm nào trong kỳ này.', style: TextStyle(color: AppColors.muted)),
          ),
        if (_isMonth) ..._monthSections(from, to, today, stats) else ..._yearSections(from, to, today, isCurrent, isFuture, stats, prev),
      ],
    );
  }

  // ── Tháng ────────────────────────────────────────────────────────────────

  List<Widget> _monthSections(
    DateTime from,
    DateTime to,
    DateTime today,
    PeriodStats stats,
  ) {
    final weeks = weeksOfMonth(widget.c.records, from, to);
    final s = stats.summary;
    return [
      const SettingsSectionLabel('Theo tuần'),
      _Panel(
        children: [
          _Line('Số tuần trong tháng', '${weeks.length} tuần', strong: true),
          const Divider(height: 20),
          for (final w in weeks)
            _WeekRow(
              week: w,
              current: !today.isBefore(w.start) && !today.isAfter(w.end),
            ),
        ],
      ),
      const SettingsSectionLabel('Số ngày'),
      _daysPanel(stats, today.isBefore(to) && !today.isBefore(from)),
      const SettingsSectionLabel('Giờ làm và tiền'),
      _Panel(
        children: [
          const _HoursHeader(),
          _HoursRow('Giờ thường', s.regular, s.regularPay, Colors.teal),
          _HoursRow('Giờ OT (x1.5)', s.ot, s.otPay, Colors.indigo),
          if (stats.otherDoubleHours > 0.0001)
            _HoursRow('Giờ x2 (trên 12 giờ)', stats.otherDoubleHours, stats.otherDoublePay, Colors.deepOrange.shade300),
          _HoursRow('Giờ ngày lễ (x2)', stats.holidayHours, stats.holidayPay, Colors.deepOrange),
          const Divider(height: 20),
          _HoursRow('Tổng cộng', s.total, s.earned, AppColors.tealDark, strong: true),
        ],
      ),
    ];
  }

  // ── Năm ──────────────────────────────────────────────────────────────────

  List<Widget> _yearSections(
    DateTime from,
    DateTime to,
    DateTime today,
    bool isCurrent,
    bool isFuture,
    PeriodStats stats,
    PeriodStats prev,
  ) {
    final recs = widget.c.records;
    final months = [
      for (var m = 1; m <= 12; m++) summarize(recs, DateTime(from.year, m), DateTime(from.year, m + 1)),
    ];
    final maxMonth = months.fold<double>(0, (a, b) => b.earned > a ? b.earned : a);

    final weekEnd = isCurrent ? DateTime(today.year, today.month, today.day + 1) : (isFuture ? from : to);
    final weekCount = calendarWeeks(from, weekEnd);
    final avgWeek = weekCount > 0 ? stats.summary.earned / weekCount : 0.0;

    return [
      const SettingsSectionLabel('Số ngày'),
      _daysPanel(stats, isCurrent, prevIdle: prev.idleWeekdays, sameSpan: isCurrent),
      const SettingsSectionLabel('Tiền lương theo tháng'),
      _Panel(
        children: [
          for (var m = 0; m < 12; m++)
            _MonthBarRow(
              label: monthShort[m],
              value: months[m].earned,
              max: maxMonth,
              current: isCurrent && today.month == m + 1,
            ),
          const Divider(height: 20),
          _Line('Tổng tiền lương', money(stats.summary.earned), strong: true),
        ],
      ),
      const SettingsSectionLabel('Bình quân mỗi tuần'),
      _Panel(
        children: [
          _Line('Bình quân mỗi tuần', money(avgWeek), strong: true, sub: 'Chia cho $weekCount tuần'),
        ],
      ),
    ];
  }

  // ── Khối "Số ngày" dùng chung ─────────────────────────────────────────────

  Widget _daysPanel(PeriodStats st, bool showTodayNote, {int? prevIdle, bool sameSpan = false}) {
    final delta = prevIdle == null ? null : st.idleWeekdays - prevIdle;
    return _Panel(
      children: [
        _Line('Tổng số ngày làm', '${st.workedDays} ngày', strong: true),
        _Line('Ngày thường', '${st.weekdayDays} ngày', color: Colors.teal),
        _Line('Ngày OT (T7, CN)', '${st.otDays} ngày', color: Colors.indigo),
        _Line('Ngày lễ', '${st.holidayDays} ngày', color: Colors.deepOrange),
        const Divider(height: 20),
        _Line('Tổng số ca làm', '${st.summary.shifts}', strong: true),
        const Divider(height: 20),
        _Line('Ngày thường không có ca làm', '${st.idleWeekdays} ngày', strong: true),
        if (delta != null)
          _Line(
            sameSpan ? 'So với cùng kỳ năm trước' : 'So với năm trước',
            '${diffInt(st.idleWeekdays, prevIdle!)} ngày',
            // Nhiều ngày nghỉ hơn: đỏ; ít hơn: xanh.
            valueColor: delta > 0 ? Colors.red.shade700 : (delta < 0 ? Colors.green.shade700 : AppColors.muted),
            sub: '${tr(sameSpan ? 'Cùng kỳ năm trước' : 'Năm trước')}: ${tr('$prevIdle ngày')}',
          ),
        if (showTodayNote)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Chỉ tính các ngày đã qua, không tính hôm nay.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
      ],
    );
  }
}

// ═════════════════════════════ Thành phần giao diện ═════════════════════════════

class _PeriodNav extends StatelessWidget {
  const _PeriodNav({required this.title, required this.onPrev, required this.onNext});
  final String title;
  final VoidCallback? onPrev, onNext;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          IconButton.filledTonal(onPressed: onPrev, icon: const Icon(Icons.chevron_left_rounded)),
          Expanded(
            child: Center(
              child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ),
          IconButton.filledTonal(onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded)),
        ],
      );
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.summary,
    required this.prev,
    required this.compareLabel,
    required this.prevTitle,
  });
  final PeriodSummary summary, prev;
  final String compareLabel, prevTitle;

  @override
  Widget build(BuildContext context) {
    final d = summary.earned - prev.earned;
    final up = d > 0.004, down = d < -0.004;
    final tone = up ? const Color(0xFF86EFAC) : (down ? const Color(0xFFFCA5A5) : Colors.white70);
    final pct = diffPercent(summary.earned, prev.earned);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.tealMid, AppColors.tealDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tổng tiền lương', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 2),
          Text(
            money(summary.earned),
            style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          ),
          Text('${fmtHours(summary.total)} · ${summary.shifts} ca', style: const TextStyle(color: Colors.white70)),
          const Divider(height: 28, color: Colors.white24),
          Row(
            children: [
              Icon(up ? Icons.arrow_upward_rounded : (down ? Icons.arrow_downward_rounded : Icons.remove_rounded), color: tone, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  pct.isEmpty ? diffMoney(summary.earned, prev.earned) : '${diffMoney(summary.earned, prev.earned)} ($pct)',
                  style: TextStyle(color: tone, fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${tr(compareLabel)} · ${tr(prevTitle)}: ${money(prev.earned)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      );
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.color, this.strong = false, this.valueColor, this.sub});
  final String label, value;
  final Color? color, valueColor;
  final bool strong;
  final String? sub;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (color != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 14, fontWeight: strong ? FontWeight.w700 : FontWeight.w500)),
                  if (sub != null) Text(sub!, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: strong ? 15 : 14,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                color: valueColor,
              ),
            ),
          ],
        ),
      );
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.week, required this.current});
  final WeekStat week;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final s = week.start, e = week.end;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: current ? AppColors.tealMid.withValues(alpha: 0.08) : null,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.tealMid.withValues(alpha: current ? 0.2 : 0.1),
            child: Text('${week.index}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.tealDark, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 6,
                  children: [
                    Text('Tuần ${week.index}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (current) const Pill('Tuần này', color: AppColors.tealMid),
                  ],
                ),
                Text(
                  '${pad2(s.day)}/${pad2(s.month)} – ${pad2(e.day)}/${pad2(e.month)} · ${week.summary.shifts} ca',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(money(week.summary.earned), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ],
      ),
    );
  }
}

class _HoursHeader extends StatelessWidget {
  const _HoursHeader();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Expanded(child: SizedBox()),
            SizedBox(width: 70, child: Text('Giờ', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: AppColors.muted))),
            SizedBox(width: 92, child: Text('Tiền', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: AppColors.muted))),
          ],
        ),
      );
}

class _HoursRow extends StatelessWidget {
  const _HoursRow(this.label, this.hours, this.pay, this.color, {this.strong = false});
  final String label;
  final double hours, pay;
  final Color color;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: strong ? 15 : 14, fontWeight: strong ? FontWeight.w800 : FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          if (!strong) ...[
            Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(label, style: style.copyWith(fontWeight: strong ? FontWeight.w800 : FontWeight.w500))),
          SizedBox(width: 70, child: Text(fmtHours(hours), textAlign: TextAlign.right, style: style)),
          SizedBox(width: 92, child: Text(money(pay), textAlign: TextAlign.right, style: style)),
        ],
      ),
    );
  }
}

class _MonthBarRow extends StatelessWidget {
  const _MonthBarRow({required this.label, required this.value, required this.max, required this.current});
  final String label;
  final double value, max;
  final bool current;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          spacing: 10,
          children: [
            SizedBox(
              width: 34,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: current ? FontWeight.w800 : FontWeight.w500,
                  color: current ? AppColors.tealMid : AppColors.muted,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: max <= 0 ? 0 : (value / max).clamp(0.0, 1.0),
                  minHeight: 12,
                  color: current ? AppColors.tealMid : AppColors.tealMid.withValues(alpha: 0.55),
                  backgroundColor: const Color(0xFFE2E8F0),
                ),
              ),
            ),
            SizedBox(
              width: 92,
              child: Text(
                money(value),
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: current ? FontWeight.w800 : FontWeight.w600, color: value <= 0 ? AppColors.muted : null),
              ),
            ),
          ],
        ),
      );
}
