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

          // Danh sách hiển thị: DateTime = tiêu đề tuần, WorkRecord = ca làm,
          // _DayItem = thống kê của ngày (đặt sau ca cuối cùng của ngày đó).
          final items = <Object>[];
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
                                onSelected: (_) => setState(() => _preset = e.key),
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
