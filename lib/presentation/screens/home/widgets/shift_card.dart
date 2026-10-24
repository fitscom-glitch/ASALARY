import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/preferences/active_shift.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

class _GlassPill extends StatelessWidget {
  const _GlassPill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      );
}

class ShiftCard extends StatelessWidget {
  const ShiftCard({
    super.key,
    required this.active,
    required this.todayType,
    required this.weekEarned,
    required this.weekHours,
    required this.weekShifts,
    required this.estimate,
    required this.onStart,
    required this.onEnd,
    required this.onDiscard,
  });
  final ActiveShift? active;
  final String todayType;
  final double weekEarned, weekHours;
  final int weekShifts;
  final double Function() estimate;
  final VoidCallback onStart, onEnd, onDiscard;

  @override
  Widget build(BuildContext context) {
    final a = active;
    final soft = Colors.white.withValues(alpha: 0.78);
    final solid = FilledButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.tealMid,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.tealMid, AppColors.tealDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealMid.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: a == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${weekdayFull[DateTime.now().weekday - 1]}, ${dmyFmt.format(DateTime.now())}',
                        style: TextStyle(color: soft, fontSize: 13),
                      ),
                    ),
                    _GlassPill('Hôm nay: ${dayLabel(todayType)}'),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Thu nhập tuần này', style: TextStyle(color: soft)),
                const SizedBox(height: 2),
                Text(
                  money(weekEarned),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                Text('${fmtHours(weekHours)} · $weekShifts ca', style: TextStyle(color: soft)),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: solid,
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Vào ca'),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(color: Color(0xFF86EFAC), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'ĐANG TRONG CA',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 1),
                      ),
                    ),
                    _GlassPill(dayLabel(a.dayType)),
                  ],
                ),
                const SizedBox(height: 12),
                ElapsedText(
                  start: a.start,
                  style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w300),
                ),
                _Tick(
                  builder: (_) => Text(
                    '≈ ${money(estimate())} tính đến lúc này',
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vào lúc ${fmtStart(a.start)} · ${money(a.rate)}/giờ',
                  style: TextStyle(color: soft, fontSize: 13),
                ),
                const SizedBox(height: 18),
                Row(
                  spacing: 10,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                      ),
                      onPressed: onDiscard,
                      child: const Text('Hủy ca'),
                    ),
                    Expanded(
                      child: FilledButton.icon(
                        style: solid,
                        onPressed: onEnd,
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('Ra ca'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

/// Rebuild con của nó mỗi giây (không ảnh hưởng phần còn lại của màn hình).
class _Tick extends StatefulWidget {
  const _Tick({required this.builder});
  final WidgetBuilder builder;

  @override
  State<_Tick> createState() => _TickState();
}

class _TickState extends State<_Tick> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

class ElapsedText extends StatelessWidget {
  const ElapsedText({super.key, required this.start, this.style});
  final DateTime start;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => _Tick(
        builder: (_) {
          var d = DateTime.now().difference(start);
          if (d.isNegative) d = Duration.zero;
          return Text(
            '${pad2(d.inHours)}:${pad2(d.inMinutes % 60)}:${pad2(d.inSeconds % 60)}',
            style: (style ?? const TextStyle())
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          );
        },
      );
}
