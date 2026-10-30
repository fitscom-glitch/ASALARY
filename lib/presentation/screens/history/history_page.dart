import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/core/utils/date_utils.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/paid_leave.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';
import 'package:theo_doi_luong/data/models/period_summary.dart';
import 'package:theo_doi_luong/logic/controllers/app_controller.dart';
import 'package:theo_doi_luong/logic/period_utils.dart';
import 'package:theo_doi_luong/logic/summary_calculator.dart';
import 'package:theo_doi_luong/presentation/screens/history/widgets/day_summary_card.dart';
import 'package:theo_doi_luong/presentation/screens/history/widgets/leave_tile.dart';
import 'package:theo_doi_luong/presentation/screens/history/widgets/period_header.dart';
import 'package:theo_doi_luong/presentation/screens/history/widgets/range_summary_card.dart';
import 'package:theo_doi_luong/presentation/screens/history/widgets/record_tile.dart';
import 'package:theo_doi_luong/presentation/screens/settings/paid_leave_dialog.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';
import 'package:theo_doi_luong/presentation/widgets/confirm_dialog.dart';

typedef RecordAction = void Function(BuildContext context, WorkRecord record);

/// Một dòng của lịch sử: ca làm hoặc ngày nghỉ có lương (Sick leave).
class _Entry {
  _Entry.ofRecord(WorkRecord r)
      : record = r,
        leaveKey = null,
        leave = null,
        day = dateOnly(r.start);
  _Entry.ofLeave(String key, PaidLeave l, DateTime d)
      : record = null,
        leaveKey = key,
        leave = l,
        day = dateOnly(d);
  final WorkRecord? record;
  final String? leaveKey;
  final PaidLeave? leave;
  final DateTime day;
}

/// Thống kê của một ngày trong danh sách lịch sử.
class _DayItem {
  const _DayItem(this.date, this.summary, {required this.expanded});
  final DateTime date;
  final PeriodSummary summary;
  final bool expanded;

  /// Khóa trạng thái mở/đóng của bảng thống kê ngày.
  String get key => 'd${date.toIso8601String()}';
}

/// Tiêu đề tháng / tuần có thể mở rộng, thu gọn.
class _GroupHeader {
  const _GroupHeader({
    required this.key,
    required this.title,
    required this.summary,
    required this.expanded,
    this.isMonth = false,
    this.indent = 0,
  });
  final String key, title;
  final PeriodSummary summary;
  final bool expanded, isMonth;
  final double indent;
}

enum HistoryPreset { all, week, month, lastMonth, year, custom }

class HistoryPage extends StatefulWidget {
  const HistoryPage({
    super.key,
    required this.c,
    required this.onEdit,
    required this.onDelete,
    this.initialPreset = HistoryPreset.all,
  });
  final AppController c;
  final RecordAction onEdit, onDelete;

  /// Bộ lọc ban đầu (vd. mở từ ô "Tháng này" hoặc "Năm nay" ở màn hình chính).
  final HistoryPreset initialPreset;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late HistoryPreset _preset = widget.initialPreset;
  DateTimeRange? _custom;

  /// Khóa của các tháng / tuần đang mở rộng (mặc định thu gọn hết).
  final Set<String> _open = {};

  void _toggle(String key) => setState(() {
        if (!_open.remove(key)) _open.add(key);
      });

  void _selectPreset(HistoryPreset p) => setState(() {
        _preset = p;
        _open.clear();
      });

  /// Gom các bản ghi liên tiếp có cùng khóa (danh sách đã sắp xếp theo thời gian).
  List<(DateTime, List<_Entry>)> _groupBy(List<_Entry> rs, DateTime Function(_Entry) keyOf) {
    final out = <(DateTime, List<_Entry>)>[];
    for (final r in rs) {
      final k = keyOf(r);
      if (out.isNotEmpty && out.last.$1 == k) {
        out.last.$2.add(r);
      } else {
        out.add((k, [r]));
      }
    }
    return out;
  }

  /// Tổng hợp một nhóm (ngày / tuần / tháng / năm) trong [from, to), đã gồm tiền nghỉ có lương của khoảng đó.
  /// Khoảng được cắt theo bộ lọc đang chọn để không cộng nghỉ phép nằm ngoài bộ lọc.
  PeriodSummary _sumOf(List<_Entry> es, DateTime from, DateTime to) {
    final b = _bounds;
    var f = from, t = to;
    if (b != null) {
      if (b.$1.isAfter(f)) f = b.$1;
      if (b.$2.isBefore(t)) t = b.$2;
    }
    return summarize([for (final e in es) if (e.record != null) e.record!], f, t, leave: widget.c.settings.paidLeave);
  }

  /// Từng ngày: các ca và ngày nghỉ có lương của ngày đó, rồi đến thống kê ngày.
  void _addDays(List<Object> out, List<_Entry> rs) {
    for (final (day, list) in _groupBy(rs, (r) => r.day)) {
      out.addAll(list);
      // Ngày chỉ có nghỉ có lương: dòng nghỉ đã có đủ giờ và tiền, không cần bảng thống kê ngày.
      if (list.every((e) => e.record == null)) continue;
      final d = _DayItem(day, _sumOf(list, day, DateTime(day.year, day.month, day.day + 1)), expanded: _open.contains('d${day.toIso8601String()}'));
      out.add(d);
    }
  }

  /// Các tuần; tuần nào đang mở thì liệt kê tiếp các ngày bên dưới.
  void _addWeeks(List<Object> out, List<_Entry> rs, {String scope = '', double indent = 0}) {
    for (final (monday, list) in _groupBy(rs, (r) => startOfWeek(r.day, DateTime.monday))) {
      final sunday = DateTime(monday.year, monday.month, monday.day + 6);
      final key = 'w$scope|${monday.toIso8601String()}';
      final open = _open.contains(key);
      out.add(_GroupHeader(
        key: key,
        title: 'Tuần ${pad2(monday.day)}/${pad2(monday.month)} – ${pad2(sunday.day)}/${pad2(sunday.month)}',
        summary: _sumOf(list, monday, DateTime(monday.year, monday.month, monday.day + 7)),
        expanded: open,
        indent: indent,
      ));
      if (open) _addDays(out, list);
    }
  }

  /// Số ngày của khoảng đã chọn (tính cả ngày đầu và ngày cuối, không bị lệch do đổi giờ mùa hè).
  int _dayCount(DateTimeRange r) =>
      DateTime.utc(r.end.year, r.end.month, r.end.day).difference(DateTime.utc(r.start.year, r.start.month, r.start.day)).inDays + 1;

  /// Tuần này: liệt kê ngày. Tháng: liệt kê tuần. Năm nay: tháng → tuần → ngày.
  /// Tất cả: năm → tháng → tuần → ngày.
  List<Object> _buildGrouped(List<_Entry> rs) {
    final out = <Object>[];
    switch (_preset) {
      case HistoryPreset.week:
        _addDays(out, rs);
      case HistoryPreset.month || HistoryPreset.lastMonth:
        _addWeeks(out, rs);
      case HistoryPreset.year:
        _addMonths(out, rs);
      case HistoryPreset.all:
        _addYears(out, rs);
      case HistoryPreset.custom:
        // Khoảng ngày dài hơn 1 tuần: năm → tháng → tuần → ngày. Từ 1 tuần trở xuống: liệt kê ngày.
        final r = _custom;
        if (r != null && _dayCount(r) <= 7) {
          _addDays(out, rs);
        } else {
          _addYears(out, rs);
        }
    }
    return out;
  }

  /// Các tháng; tháng nào đang mở thì liệt kê tiếp các tuần bên dưới.
  void _addMonths(List<Object> out, List<_Entry> rs, {String scope = '', double indent = 0}) {
    for (final (month, list) in _groupBy(rs, (r) => DateTime(r.day.year, r.day.month))) {
      final key = 'm$scope|${month.toIso8601String()}';
      final open = _open.contains(key);
      out.add(_GroupHeader(
        key: key,
        title: periodTitle(CompareKind.month, month),
        summary: _sumOf(list, month, DateTime(month.year, month.month + 1)),
        expanded: open,
        isMonth: true,
        indent: indent,
      ));
      if (open) _addWeeks(out, list, scope: key, indent: indent + 12);
    }
  }

  /// Các năm; năm nào đang mở thì liệt kê tiếp các tháng bên dưới.
  void _addYears(List<Object> out, List<_Entry> rs) {
    for (final (year, list) in _groupBy(rs, (r) => DateTime(r.day.year))) {
      final key = 'y${year.toIso8601String()}';
      final open = _open.contains(key);
      out.add(_GroupHeader(
        key: key,
        title: periodTitle(CompareKind.year, year),
        summary: _sumOf(list, year, DateTime(year.year + 1)),
        expanded: open,
        isMonth: true,
      ));
      if (open) _addMonths(out, list, scope: key, indent: 12);
    }
  }

  static const _presetLabels = {
    HistoryPreset.all: 'Tất cả',
    HistoryPreset.week: 'Tuần này',
    HistoryPreset.month: 'Tháng này',
    HistoryPreset.lastMonth: 'Tháng trước',
    HistoryPreset.year: 'Năm nay',
  };

  /// (từ, đến) với đến là mốc không bao gồm; null = không lọc.
  (DateTime, DateTime)? get _bounds {
    final now = DateTime.now();
    switch (_preset) {
      case HistoryPreset.all:
        return null;
      case HistoryPreset.week:
        return periodBounds(CompareKind.week, now);
      case HistoryPreset.month:
        return periodBounds(CompareKind.month, now);
      case HistoryPreset.lastMonth:
        return periodBounds(CompareKind.month, DateTime(now.year, now.month - 1));
      case HistoryPreset.year:
        return periodBounds(CompareKind.year, now);
      case HistoryPreset.custom:
        final r = _custom;
        if (r == null) return null;
        return (dateOnly(r.start), DateTime(r.end.year, r.end.month, r.end.day + 1));
    }
  }

  Future<void> _deleteLeave(BuildContext context, String key) async {
    final ok = await confirmDialog(
      context,
      title: 'Xóa ngày nghỉ có lương?',
      message: 'Ngày nghỉ có lương này sẽ bị xóa.',
      action: 'Xóa',
    );
    if (ok) await widget.c.removePaidLeave(key);
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDateRange: _custom,
      helpText: tr('Chọn khoảng ngày'),
      saveText: tr('Áp dụng'),
    );
    if (r != null && mounted) {
      setState(() {
        _custom = r;
        _preset = HistoryPreset.custom;
        _open.clear();
      });
    }
  }

  String _rangeText(List<_Entry> rs, (DateTime, DateTime)? b) {
    if (b != null) {
      final last = DateTime(b.$2.year, b.$2.month, b.$2.day - 1);
      return '${dmyFmt.format(b.$1)} – ${dmyFmt.format(last)}';
    }
    if (rs.isEmpty) return '';
    return '${dmyFmt.format(rs.last.day)} – ${dmyFmt.format(rs.first.day)}';
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.c,
        builder: (context, _) {
          final all = widget.c.records;
          final b = _bounds;
          bool inRange(DateTime d) => b == null || (!d.isBefore(b.$1) && d.isBefore(b.$2));
          final leave = widget.c.settings.paidLeave;
          final recs = [
            for (final r in all)
              if (inRange(r.start)) r
          ];
          // Ca làm và ngày nghỉ có lương, mới nhất trước. Cùng ngày: các ca (giờ vào muộn trước) rồi đến ngày nghỉ.
          final rs = <_Entry>[
            for (final r in recs) _Entry.ofRecord(r),
            for (final e in leave.entries)
              if (DateTime.tryParse(e.key) case final d? when inRange(d)) _Entry.ofLeave(e.key, e.value, d),
          ]..sort((a, z) {
              final byDay = z.day.compareTo(a.day);
              if (byDay != 0) return byDay;
              final ar = a.record, zr = z.record;
              if (ar != null && zr != null) return zr.start.compareTo(ar.start);
              if (ar != null) return -1;
              if (zr != null) return 1;
              return 0;
            });
          final sum = b == null
              ? summarize(recs, DateTime(1970), DateTime(3000), leave: leave)
              : summarize(recs, b.$1, b.$2, leave: leave);

          // Danh sách hiển thị (phân cấp, bấm tiêu đề để mở rộng hoặc thu gọn):
          // _GroupHeader = tiêu đề năm / tháng / tuần, WorkRecord = ca làm,
          // _DayItem = thống kê của ngày (đặt sau ca cuối cùng của ngày đó).
          final items = _buildGrouped(rs);

          final customLabel = (_preset == HistoryPreset.custom && _custom != null)
              ? '${dmyFmt.format(_custom!.start)} – ${dmyFmt.format(_custom!.end)}'
              : 'Chọn khoảng ngày';

          return Scaffold(
            appBar: AppBar(title: const Text('Lịch sử ca làm')),
            body: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 12,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final e in _presetLabels.entries)
                              ChoiceChip(
                                label: Text(e.value),
                                selected: _preset == e.key,
                                onSelected: (_) => _selectPreset(e.key),
                              ),
                            ChoiceChip(
                              avatar: const Icon(Icons.date_range_rounded, size: 18),
                              label: Text(customLabel),
                              selected: _preset == HistoryPreset.custom,
                              onSelected: (_) => _pickRange(),
                            ),
                          ],
                        ),
                        RangeSummaryCard(summary: sum, rangeText: _rangeText(rs, b)),
                      ],
                    ),
                  ),
                ),
                if (rs.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('Không có ca làm nào trong khoảng này.')),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final it = items[i];
                        if (it is _GroupHeader) {
                          return PeriodHeader(
                            key: ValueKey(it.key),
                            title: it.title,
                            summary: it.summary,
                            expanded: it.expanded,
                            isMonth: it.isMonth,
                            indent: it.indent,
                            onTap: () => _toggle(it.key),
                          );
                        }
                        if (it is _DayItem) {
                          return DaySummaryCard(
                            date: it.date,
                            summary: it.summary,
                            expanded: it.expanded,
                            onTap: () => _toggle(it.key),
                          );
                        }
                        final e = it as _Entry;
                        final l = e.leave;
                        if (l != null) {
                          return LeaveTile(
                            key: ValueKey('leave${e.leaveKey}'),
                            day: e.day,
                            leave: l,
                            onTap: () => showPaidLeaveDialog(context, widget.c, day: e.day),
                            onDelete: () => _deleteLeave(context, e.leaveKey!),
                          );
                        }
                        final r = e.record!;
                        return RecordTile(
                          key: ValueKey(r.id),
                          record: r,
                          onTap: () => widget.onEdit(context, r),
                          onDelete: () => widget.onDelete(context, r),
                        );
                      },
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          );
        },
      );
}
