import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/l10n/translator.dart';
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

/// Độ đậm của màu cột (nhạt, dễ nhìn).
const _soft = 0.45;

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
    this.onTap,
  });
  final String label;
  final bool today, holiday;
  final double reg, ot, dbl, maxH;

  /// Bấm vào ngày có giờ làm để mở chi tiết ngày đó (null: ngày chưa có ca, không bấm được).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final total = reg + ot + dbl;
    const barArea = 78.0;
    // Cột tô màu nhạt, chiều cao tỉ lệ với số giờ làm trong ngày (như biểu đồ cột).
    final h = total <= 0 ? 0.0 : math.max(8.0, barArea * total / maxH);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
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
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    // Ngày hôm nay có nền cột xám đậm hơn một chút, kích thước các cột luôn bằng nhau.
                    color: today ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      width: double.infinity,
                      height: h,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                      child: total <= 0
                          ? null
                          : Column(
                              // stretch: nếu không, ColoredBox không có con sẽ có chiều rộng 0 và cột không hiện.
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (dbl > 0) Expanded(flex: _flex(dbl), child: ColoredBox(color: Colors.deepOrange.withValues(alpha: _soft))),
                                if (ot > 0) Expanded(flex: _flex(ot), child: ColoredBox(color: Colors.indigo.withValues(alpha: _soft))),
                                if (reg > 0) Expanded(flex: _flex(reg), child: ColoredBox(color: AppColors.tealMid.withValues(alpha: _soft))),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Chiều cao cố định để ngày hôm nay (có vòng tròn) không làm cột lệch so với các ngày khác.
              SizedBox(
                height: 28,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: today
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: AppColors.tealMid, width: 1.6),
                          )
                        : null,
                    child: Text(
                      holiday ? '$label★' : label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: today ? FontWeight.w700 : FontWeight.w500,
                        color: holiday ? Colors.deepOrange : (today ? AppColors.tealMid : AppColors.muted),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thống kê tuần: vuốt sang phải để xem tuần trước đó (lần lượt lùi về quá khứ),
/// vuốt sang trái để quay lại các tuần sau, cho đến tuần hiện tại.
class WeekOverview extends StatefulWidget {
  const WeekOverview({super.key, required this.records, required this.holidays, this.onDayTap});
  final List<WorkRecord> records;
  final Set<String> holidays;

  /// Gọi khi bấm vào một ngày có giờ làm.
  final void Function(DateTime day)? onDayTap;

  @override
  State<WeekOverview> createState() => _WeekOverviewState();
}

class _WeekOverviewState extends State<WeekOverview> with SingleTickerProviderStateMixin {
  /// 0 = tuần hiện tại, 1 = tuần trước, 2 = hai tuần trước...
  int _offset = 0;
  int? _prev;

  /// -1: trang mới vào từ bên trái (đi về tuần cũ hơn), 1: vào từ bên phải (về tuần mới hơn).
  int _dir = 1;
  double _dragDx = 0;

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) setState(() => _prev = null);
    });

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  DateTime _mondayOf(int offset) {
    final m = startOfWeek(DateTime.now(), DateTime.monday);
    return DateTime(m.year, m.month, m.day - 7 * offset);
  }

  /// Số tuần có thể lùi lại: đến tuần của ca làm cũ nhất.
  int get _maxBack {
    if (widget.records.isEmpty) return 0;
    var first = widget.records.first.start;
    for (final r in widget.records) {
      if (r.start.isBefore(first)) first = r.start;
    }
    final diff = _mondayOf(0).difference(startOfWeek(first, DateTime.monday));
    return math.max(0, (diff.inHours / 168).round());
  }

  void _go(int target, int maxBack) {
    final t = target.clamp(0, maxBack);
    final cur = math.min(_offset, maxBack);
    if (t == cur) return;
    setState(() {
      _prev = cur;
      _dir = t > cur ? -1 : 1;
      _offset = t;
    });
    _anim.forward(from: 0);
  }

  /// Tuần hiện tại là "Tuần này"; các tuần khác ghi số tuần trong năm (theo ISO 8601) và năm,
  /// ví dụ "Tuần 30 [2026]".
  String _title(int offset) {
    if (offset == 0) return 'Tuần này';
    final thursday = _mondayOf(offset).add(const Duration(days: 3));
    final dayOfYear = DateTime.utc(thursday.year, thursday.month, thursday.day)
        .difference(DateTime.utc(thursday.year, 1, 1))
        .inDays;
    return 'Tuần ${dayOfYear ~/ 7 + 1} [${thursday.year}]';
  }

  Widget _page(BuildContext context, int offset, int maxBack) {
    final now = DateTime.now();
    final monday = _mondayOf(offset);
    final sunday = DateTime(monday.year, monday.month, monday.day + 6);
    final next = DateTime(monday.year, monday.month, monday.day + 7);
    final days = [for (var i = 0; i < 7; i++) DateTime(monday.year, monday.month, monday.day + i)];
    final holidays = widget.holidays;

    final reg = List.filled(7, 0.0), ot = List.filled(7, 0.0), dbl = List.filled(7, 0.0);
    for (final r in widget.records) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _title(offset),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            _ArrowButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Tuần trước',
              onPressed: offset < maxBack ? () => _go(offset + 1, maxBack) : null,
            ),
            Text(
              '${pad2(monday.day)}/${pad2(monday.month)} – ${pad2(sunday.day)}/${pad2(sunday.month)}',
              style: const TextStyle(color: AppColors.muted),
            ),
            _ArrowButton(
              icon: Icons.chevron_right_rounded,
              tooltip: 'Tuần sau',
              onPressed: offset > 0 ? () => _go(offset - 1, maxBack) : null,
            ),
            _ArrowButton(
              icon: Icons.keyboard_double_arrow_right_rounded,
              tooltip: 'Về tuần này',
              onPressed: offset > 0 ? () => _go(0, maxBack) : null,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          spacing: 2,
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
                  onTap: widget.onDayTap != null && reg[i] + ot[i] + dbl[i] > 0
                      ? () => widget.onDayTap!(days[i])
                      : null,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxBack = _maxBack;
    final cur = math.min(_offset, maxBack);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => _dragDx = 0,
        onHorizontalDragUpdate: (d) => _dragDx += d.delta.dx,
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          final dir = v.abs() > 250 ? v.sign : (_dragDx.abs() > 60 ? _dragDx.sign : 0.0);
          if (dir > 0) {
            _go(cur + 1, maxBack); // vuốt sang phải: tuần trước đó
          } else if (dir < 0) {
            _go(cur - 1, maxBack); // vuốt sang trái: tuần kế sau
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              final prev = _anim.isAnimating ? _prev : null;
              return LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final t = prev == null ? 1.0 : Curves.easeOutCubic.transform(_anim.value);
                  return ClipRect(
                    child: Stack(
                      children: [
                        // Key theo tuần để mỗi tuần có trạng thái riêng (thanh tiến độ, cột chạy từ đầu).
                        Transform.translate(
                          offset: Offset(_dir * w * (1 - t), 0),
                          child: KeyedSubtree(key: ValueKey(cur), child: _page(context, cur, maxBack)),
                        ),
                        if (prev != null)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            child: Transform.translate(
                              offset: Offset(-_dir * w * t, 0),
                              child: IgnorePointer(
                                child: KeyedSubtree(key: ValueKey(prev), child: _page(context, prev, maxBack)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.tooltip, required this.onPressed});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tr(tooltip),
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: 22,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      );
}
