import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/core/utils/date_utils.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';
import 'package:theo_doi_luong/data/models/period_summary.dart';
import 'package:theo_doi_luong/logic/controllers/app_controller.dart';
import 'package:theo_doi_luong/logic/period_utils.dart';
import 'package:theo_doi_luong/logic/summary_calculator.dart';
import 'package:theo_doi_luong/presentation/screens/history/widgets/day_summary_card.dart';
import 'package:theo_doi_luong/presentation/screens/history/widgets/period_header.dart';
import 'package:theo_doi_luong/presentation/screens/history/widgets/range_summary_card.dart';
import 'package:theo_doi_luong/presentation/screens/history/widgets/record_tile.dart';
import 'package:theo_doi_luong/presentation/screens/history/widgets/week_header.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

typedef RecordAction = void Function(BuildContext context, WorkRecord record);

/// Thống kê của một ngày trong danh sách lịch sử.
class _DayItem {
  const _DayItem(this.date, this.summary);
  final DateTime date;
  final PeriodSummary summary;
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
  const HistoryPage({super.key, required this.c, required this.onEdit, required this.onDelete});
  final AppController c;
  final RecordAction onEdit, onDelete;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  HistoryPreset _preset = HistoryPreset.all;
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
  List<(DateTime, List<WorkRecord>)> _groupBy(List<WorkRecord> rs, DateTime Function(WorkRecord) keyOf) {
    final out = <(DateTime, List<WorkRecord>)>[];
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

  PeriodSummary _sumOf(List<WorkRecord> rs) => summarize(rs, DateTime(1970), DateTime(3000));

  /// Từng ngày: các ca của ngày đó, rồi đến thống kê ngày.
  void _addDays(List<Object> out, List<WorkRecord> rs) {
    for (final (day, list) in _groupBy(rs, (r) => dateOnly(r.start))) {
      out.addAll(list);
      out.add(_DayItem(day, _sumOf(list)));
    }
  }

  /// Các tuần; tuần nào đang mở thì liệt kê tiếp các ngày bên dưới.
  void _addWeeks(List<Object> out, List<WorkRecord> rs, {String scope = '', double indent = 0}) {
    for (final (monday, list) in _groupBy(rs, (r) => startOfWeek(r.start, DateTime.monday))) {
      final sunday = DateTime(monday.year, monday.month, monday.day + 6);
      final key = 'w$scope|${monday.toIso8601String()}';
      final open = _open.contains(key);
      out.add(_GroupHeader(
        key: key,
        title: 'Tuần ${pad2(monday.day)}/${pad2(monday.month)} – ${pad2(sunday.day)}/${pad2(sunday.month)}',
        summary: _sumOf(list),
        expanded: open,
        indent: indent,
      ));
      if (open) _addDays(out, list);
    }
  }

  /// Tuần này: liệt kê ngày. Tháng: liệt kê tuần. Năm nay: tháng → tuần → ngày.
  /// Tất cả: năm → tháng → tuần → ngày.
  List<Object> _buildGrouped(List<WorkRecord> rs) {
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
        break;
    }
    return out;
  }

  /// Các tháng; tháng nào đang mở thì liệt kê tiếp các tuần bên dưới.
  void _addMonths(List<Object> out, List<WorkRecord> rs, {String scope = '', double indent = 0}) {
    for (final (month, list) in _groupBy(rs, (r) => DateTime(r.start.year, r.start.month))) {
      final key = 'm$scope|${month.toIso8601String()}';
      final open = _open.contains(key);
      out.add(_GroupHeader(
        key: key,
        title: periodTitle(CompareKind.month, month),
        summary: _sumOf(list),
        expanded: open,
        isMonth: true,
        indent: indent,
      ));
      if (open) _addWeeks(out, list, scope: key, indent: indent + 12);
    }
  }

  /// Các năm; năm nào đang mở thì liệt kê tiếp các tháng bên dưới.
  void _addYears(List<Object> out, List<WorkRecord> rs) {
    for (final (year, list) in _groupBy(rs, (r) => DateTime(r.start.year))) {
      final key = 'y${year.toIso8601String()}';
      final open = _open.contains(key);
      out.add(_GroupHeader(
        key: key,
        title: periodTitle(CompareKind.year, year),
        summary: _sumOf(list),
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

  String _rangeText(List<WorkRecord> rs, (DateTime, DateTime)? b) {
    if (b != null) {
      final last = DateTime(b.$2.year, b.$2.month, b.$2.day - 1);
      return '${dmyFmt.format(b.$1)} – ${dmyFmt.format(last)}';
    }
    if (rs.isEmpty) return '';
    return '${dmyFmt.format(rs.last.start)} – ${dmyFmt.format(rs.first.start)}';
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.c,
        builder: (context, _) {
          final all = widget.c.records;
          final b = _bounds;
          final rs = b == null
              ? all
              : [
                  for (final r in all)
                    if (!r.start.isBefore(b.$1) && r.start.isBefore(b.$2)) r
                ];
          final sum = summarize(rs, DateTime(1970), DateTime(3000));

          // Tất cả / Tuần này / Tháng / Năm: danh sách phân cấp, bấm tiêu đề để mở rộng hoặc thu gọn.
          // Chọn khoảng ngày: giữ nguyên danh sách phẳng theo tuần.
          final grouped = _preset != HistoryPreset.custom;

          // Danh sách hiển thị: DateTime = tiêu đề tuần (danh sách phẳng), _GroupHeader = tiêu đề
          // tháng / tuần (phân cấp), WorkRecord = ca làm, _DayItem = thống kê của ngày
          // (đặt sau ca cuối cùng của ngày đó).
          final items = <Object>[];
          if (grouped) {
            items.addAll(_buildGrouped(rs));
          } else {
            DateTime? currentWeek;
            DateTime? currentDay;
            void closeDay() {
              final d = currentDay;
              if (d == null) return;
              items.add(_DayItem(d, summarize(rs, d, DateTime(d.year, d.month, d.day + 1))));
            }

            for (final r in rs) {
              final day = dateOnly(r.start);
              if (currentDay != day) {
                closeDay();
                currentDay = day;
              }
              final w = startOfWeek(r.start, DateTime.monday);
              if (currentWeek != w) {
                currentWeek = w;
                items.add(w);
              }
              items.add(r);
            }
            closeDay();
          }

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
                        if (it is DateTime) {
                          return WeekHeader(
                            monday: it,
                            summary: summarize(rs, it, DateTime(it.year, it.month, it.day + 7)),
                          );
                        }
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
                        if (it is _DayItem) return DaySummaryCard(date: it.date, summary: it.summary);
                        final r = it as WorkRecord;
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
