import 'dart:async';

import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/utils/date_utils.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';
import 'package:theo_doi_luong/data/preferences/active_shift.dart';
import 'package:theo_doi_luong/logic/pay_calculator.dart';
import 'package:theo_doi_luong/logic/summary_calculator.dart';
import 'package:theo_doi_luong/presentation/screens/home/widgets/stat_tile.dart';

/// Ô "Hôm nay": số tiền và số giờ tính đến thời điểm hiện tại, cập nhật mỗi phút,
/// kể cả khi ca đang làm chưa được "Ra ca". Hủy ca thì phần tiền của ca đó biến mất vì
/// ca đang làm không còn nữa.
class LiveTodayTile extends StatefulWidget {
  const LiveTodayTile({
    super.key,
    required this.records,
    required this.active,
    required this.holidays,
    required this.onTap,
  });
  final List<WorkRecord> records;
  final ActiveShift? active;
  final Set<String> holidays;
  final VoidCallback onTap;

  @override
  State<LiveTodayTile> createState() => _LiveTodayTileState();
}

class _LiveTodayTileState extends State<LiveTodayTile> {
  Timer? _timer;
  int _minute = DateTime.now().millisecondsSinceEpoch ~/ 60000;

  @override
  void initState() {
    super.initState();
    // Kiểm tra mỗi giây nhưng chỉ dựng lại khi sang phút mới (kể cả khi qua nửa đêm).
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final m = DateTime.now().millisecondsSinceEpoch ~/ 60000;
      if (m != _minute) {
        _minute = m;
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final end = floorMinute(now);
    final day = dateOnly(now);
    final saved = summarize(widget.records, day, DateTime(day.year, day.month, day.day + 1));
    var earned = saved.earned;
    var hours = saved.total;

    // Ca đang làm được ghi vào ngày bắt đầu; chỉ tính nếu bắt đầu trong hôm nay.
    final a = widget.active;
    if (a != null && dateOnly(a.start) == day && end.isAfter(a.start)) {
      earned += estimateActive(widget.records, a, widget.holidays, now);
      hours += end.difference(a.start).inMinutes / 60.0;
    }

    return StatTile(
      icon: Icons.today_rounded,
      label: 'Hôm nay',
      value: money(earned),
      hours: fmtHours(hours),
      color: AppColors.tealMid,
      onTap: widget.onTap,
    );
  }
}
