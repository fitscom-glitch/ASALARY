import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';
import 'package:theo_doi_luong/data/preferences/active_shift.dart';
import 'package:theo_doi_luong/logic/pay_tier.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

class _GlassPill extends StatelessWidget {
  const _GlassPill(this.text, {this.tint});
  final String text;

  /// Màu nền riêng (OT, x2). Null: kính trắng mờ mặc định.
  final Color? tint;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: tint ?? Colors.white.withValues(alpha: 0.18),
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
    required this.records,
    required this.holidays,
    required this.weekEarned,
    required this.weekHours,
    required this.weekShifts,
    required this.estimate,
    required this.onStart,
    required this.onEnd,
    required this.onDiscard,
    this.onEditStart,
  });
  final ActiveShift? active;
  final String todayType;

  /// Dùng để xác định loại giờ hiện tại (Thường / OT x1.5 / x2) của ca đang làm.
  final List<WorkRecord> records;
  final Set<String> holidays;
  final double weekEarned, weekHours;
  final int weekShifts;
  final double Function() estimate;
  final VoidCallback onStart, onEnd, onDiscard;

  /// Chạm vào dòng "Vào lúc ..." để sửa giờ vào ca (khi quên bấm vào ca đúng giờ).
  final VoidCallback? onEditStart;

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
                    // Nhãn đổi theo loại giờ đang được tính: Thường -> OT x1.5 -> x2 (giống vòng tròn ngày hôm nay ở biểu đồ tuần).
                    _Tick(
                      builder: (_) => switch (currentPayTier(records, holidays, a)) {
                        PayTier.double => _GlassPill('x2', tint: Colors.deepOrange.shade400),
                        PayTier.ot => _GlassPill('OT x1.5', tint: Colors.indigo.shade400),
                        PayTier.regular => const _GlassPill('Thường'),
                      },
                    ),
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
                InkWell(
                  onTap: onEditStart,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Vào lúc ${fmtStart(a.start)} · ${money(a.rate)}/giờ',
                            style: TextStyle(color: soft, fontSize: 13),
                          ),
                        ),
                        if (onEditStart != null) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.edit_rounded, size: 14, color: soft),
                        ],
                      ],
                    ),
                  ),
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
