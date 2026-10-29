import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/logic/controllers/app_controller.dart';
import 'package:theo_doi_luong/logic/period_utils.dart';
import 'package:theo_doi_luong/logic/summary_calculator.dart';
import 'package:theo_doi_luong/presentation/screens/compare/month_picker_dialog.dart';
import 'package:theo_doi_luong/presentation/screens/compare/year_picker_dialog.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({required this.tag, required this.color, required this.title, required this.onTap});
  final String tag, title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Row(
                  spacing: 6,
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    Text(tag, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ),
      );
}

String _dHours(double a, double b) {
  final m = ((a - b) * 60).round();
  if (m == 0) return '0h00';
  return '${m > 0 ? '+' : '-'}${fmtHours(m.abs() / 60)}';
}

String _dMoney(double a, double b) {
  final d = a - b;
  if (d.abs() < 0.005) return money(0);
  return '${d > 0 ? '+' : '-'}${money(d.abs())}';
}

String _dPct(double a, double b) {
  if (b.abs() < 0.005) return a.abs() < 0.005 ? '' : '—';
  return '${a >= b ? '+' : '-'}${((a - b).abs() / b * 100).toStringAsFixed(1)}%';
}

Color _dColor(double d) => d > 0.0001 ? Colors.green.shade700 : (d < -0.0001 ? Colors.red.shade700 : AppColors.muted);

class ComparePage extends StatefulWidget {
  const ComparePage({super.key, required this.c});
  final AppController c;

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  CompareKind _kind = CompareKind.month;
  DateTime _a = DateTime.now();
  DateTime _b = shiftPeriod(CompareKind.month, DateTime.now(), -1);

  void _setKind(CompareKind k) {
    final now = DateTime.now();
    setState(() {
      _kind = k;
      _a = now;
      _b = shiftPeriod(k, now, -1);
    });
  }

  Future<DateTime?> _choose(DateTime current) {
    switch (_kind) {
      case CompareKind.week:
        return showDatePicker(
          context: context,
          initialDate: current,
          firstDate: DateTime(2020),
          lastDate: DateTime(DateTime.now().year + 2, 12, 31),
          helpText: tr('Chọn một ngày trong tuần cần xem'),
        );
      case CompareKind.month:
        return showDialog<DateTime>(context: context, builder: (_) => MonthPickerDialog(initial: current));
      case CompareKind.year:
        return showDialog<DateTime>(context: context, builder: (_) => YearPickerDialog(initial: current));
    }
  }

  Future<void> _pick(bool isA) async {
    final d = await _choose(isA ? _a : _b);
    if (d == null || !mounted) return;
    setState(() {
      if (isA) {
        _a = d;
      } else {
        _b = d;
      }
    });
  }

  Widget _bar(String tag, double value, double max, Color color) => Row(
        spacing: 8,
        children: [
          SizedBox(width: 18, child: Text(tag, style: TextStyle(color: color, fontWeight: FontWeight.w700))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: max <= 0 ? 0 : (value / max).clamp(0.0, 1.0),
                minHeight: 12,
                color: color,
                backgroundColor: const Color(0xFFE2E8F0),
              ),
            ),
          ),
          SizedBox(
            width: 84,
            child: Text(money(value), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      );

  Widget _row(String label, String a, String b, String delta, Color deltaColor, {bool strong = false, String sub = ''}) {
    final style = TextStyle(fontWeight: strong ? FontWeight.w700 : FontWeight.w500, fontSize: strong ? 14 : 13);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: Text(label, style: TextStyle(color: AppColors.muted, fontSize: strong ? 14 : 13))),
          Expanded(flex: 5, child: Text(a, textAlign: TextAlign.right, style: style)),
          Expanded(flex: 5, child: Text(b, textAlign: TextAlign.right, style: style)),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(delta, style: style.copyWith(color: deltaColor)),
                if (sub.isNotEmpty) Text(sub, style: TextStyle(fontSize: 11, color: deltaColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.c,
        builder: (context, _) {
          final rs = widget.c.records;
          final ba = periodBounds(_kind, _a);
          final bb = periodBounds(_kind, _b);
          final leave = widget.c.settings.paidLeave;
          final sa = summarize(rs, ba.$1, ba.$2, leave: leave);
          final sb = summarize(rs, bb.$1, bb.$2, leave: leave);
          const colorA = AppColors.tealMid;
          const colorB = Colors.indigo;
          final same = ba.$1 == bb.$1;
          final maxPay = math.max(sa.earned, sb.earned);

          return Scaffold(
            appBar: AppBar(title: const Text('So sánh thu nhập')),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              children: [
                SegmentedButton<CompareKind>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: CompareKind.week, label: Text('Tuần')),
                    ButtonSegment(value: CompareKind.month, label: Text('Tháng')),
                    ButtonSegment(value: CompareKind.year, label: Text('Năm')),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (v) => _setKind(v.first),
                ),
                const SizedBox(height: 12),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: _PeriodButton(
                        tag: 'Kỳ A',
                        color: colorA,
                        title: periodTitle(_kind, _a),
                        onTap: () => _pick(true),
                      ),
                    ),
                    IconButton(
                      tooltip: tr('Đổi chỗ hai kỳ'),
                      onPressed: () => setState(() {
                        final t = _a;
                        _a = _b;
                        _b = t;
                      }),
                      icon: const Icon(Icons.swap_horiz_rounded),
                    ),
                    Expanded(
                      child: _PeriodButton(
                        tag: 'Kỳ B',
                        color: colorB,
                        title: periodTitle(_kind, _b),
                        onTap: () => _pick(false),
                      ),
                    ),
                  ],
                ),
                if (same)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Hai kỳ đang giống nhau, hãy chọn kỳ khác để so sánh.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _bar('A', sa.earned, maxPay, colorA),
                        const SizedBox(height: 8),
                        _bar('B', sb.earned, maxPay, colorB),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Spacer(flex: 5),
                            Expanded(
                              flex: 5,
                              child: Text('Kỳ A',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(color: colorA, fontWeight: FontWeight.w700, fontSize: 12)),
                            ),
                            Expanded(
                              flex: 5,
                              child: Text('Kỳ B',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(color: colorB, fontWeight: FontWeight.w700, fontSize: 12)),
                            ),
                            const Expanded(
                              flex: 5,
                              child: Text('Chênh lệch',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
                            ),
                          ],
                        ),
                        _row('Lương', money(sa.earned), money(sb.earned), _dMoney(sa.earned, sb.earned),
                            _dColor(sa.earned - sb.earned),
                            strong: true, sub: _dPct(sa.earned, sb.earned)),
                        _row('Tổng giờ', fmtHours(sa.total), fmtHours(sb.total), _dHours(sa.total, sb.total),
                            _dColor(sa.total - sb.total)),
                        _row('Thường', fmtHours(sa.regular), fmtHours(sb.regular), _dHours(sa.regular, sb.regular),
                            _dColor(sa.regular - sb.regular)),
                        _row('OT x1.5', fmtHours(sa.ot), fmtHours(sb.ot), _dHours(sa.ot, sb.ot),
                            _dColor(sa.ot - sb.ot)),
                        _row('x2', fmtHours(sa.dbl), fmtHours(sb.dbl), _dHours(sa.dbl, sb.dbl),
                            _dColor(sa.dbl - sb.dbl)),
                        _row('Số ca', '${sa.shifts}', '${sb.shifts}',
                            '${sa.shifts - sb.shifts > 0 ? '+' : ''}${sa.shifts - sb.shifts}',
                            _dColor((sa.shifts - sb.shifts).toDouble())),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}
