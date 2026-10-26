import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/constants/app_constants.dart';
import 'package:theo_doi_luong/core/constants/platform_features.dart';
import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/core/utils/date_utils.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/record_draft.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';
import 'package:theo_doi_luong/logic/controllers/app_controller.dart';
import 'package:theo_doi_luong/logic/controllers/app_lock.dart';
import 'package:theo_doi_luong/logic/controllers/avatar_controller.dart';
import 'package:theo_doi_luong/logic/pay_calculator.dart';
import 'package:theo_doi_luong/logic/period_stats.dart';
import 'package:theo_doi_luong/logic/summary_calculator.dart';
import 'package:theo_doi_luong/presentation/screens/avatar/avatar_sheet.dart';
import 'package:theo_doi_luong/presentation/screens/compare/compare_page.dart';
import 'package:theo_doi_luong/presentation/screens/export/export_flow.dart';
import 'package:theo_doi_luong/presentation/screens/history/history_page.dart';
import 'package:theo_doi_luong/presentation/screens/history/widgets/day_summary_card.dart';
import 'package:theo_doi_luong/presentation/screens/history/widgets/record_tile.dart';
import 'package:theo_doi_luong/presentation/screens/home/widgets/compare_tile.dart';
import 'package:theo_doi_luong/presentation/screens/home/widgets/history_preview_card.dart';
import 'package:theo_doi_luong/presentation/screens/home/widgets/live_today_tile.dart';
import 'package:theo_doi_luong/presentation/screens/home/widgets/profile_header.dart';
import 'package:theo_doi_luong/presentation/screens/home/widgets/shift_card.dart';
import 'package:theo_doi_luong/presentation/screens/home/widgets/stat_tile.dart';
import 'package:theo_doi_luong/presentation/screens/home/widgets/week_overview.dart';
import 'package:theo_doi_luong/presentation/screens/settings/settings_page.dart';
import 'package:theo_doi_luong/presentation/screens/stats/period_stats_page.dart';
import 'package:theo_doi_luong/presentation/screens/shift/record_editor.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';
import 'package:theo_doi_luong/presentation/widgets/confirm_dialog.dart';
import 'package:theo_doi_luong/presentation/widgets/toast.dart';
import 'package:theo_doi_luong/services/reminder_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.c,
    required this.lock,
    required this.reminders,
    required this.avatar,
  });
  final AppController c;
  final AppLock lock;
  final ReminderService reminders;
  final AvatarController avatar;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        if (c.loading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (c.loadError != null && c.records.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text(kAppName)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  children: [
                    const Icon(Icons.error_outline, size: 40),
                    Text('Không thể tải dữ liệu\n${c.loadError}', textAlign: TextAlign.center),
                    FilledButton(onPressed: c.load, child: const Text('Thử lại')),
                  ],
                ),
              ),
            ),
          );
        }

        final records = c.records;
        final holidays = c.settings.holidays;
        final now = DateTime.now();
        final monday = startOfWeek(now, DateTime.monday);
        final week = summarize(records, monday, DateTime(monday.year, monday.month, monday.day + 7));
        final month = summarize(records, DateTime(now.year, now.month), DateTime(now.year, now.month + 1));
        final year = summarize(records, DateTime(now.year), DateTime(now.year + 1));

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _editRecord(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm ca'),
          ),
          body: RefreshIndicator(
            onRefresh: c.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  automaticallyImplyLeading: false,
                  toolbarHeight: 88,
                  titleSpacing: 16,
                  title: ProfileHeader(
                    settings: c.settings,
                    avatar: avatar,
                    onAvatarTap: () => _openAvatar(context),
                  ),
                  actions: [
                    IconButton(
                      tooltip: tr('Xuất dữ liệu'),
                      onPressed: () => _export(context),
                      icon: const Icon(Icons.ios_share_rounded),
                    ),
                    IconButton(
                      tooltip: tr('Cài đặt'),
                      onPressed: () => _openSettings(context),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 14,
                      children: [
                        if (c.skipped > 0)
                          Card(
                            color: Colors.amber.shade100,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                'Có ${c.skipped} bản ghi cũ không đọc được nên chưa hiển thị. '
                                'Dữ liệu chưa bị xóa và vẫn nằm trong file DB '
                                '(có bản sao work_records_v3.db.pre_v5.bak).',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ShiftCard(
                          active: c.active,
                          todayType: c.dayTypeFor(now),
                          weekEarned: week.earned,
                          weekHours: week.total,
                          weekShifts: week.shifts,
                          estimate: () => c.active == null
                              ? 0.0
                              : estimateActive(records, c.active!, holidays, DateTime.now()),
                          onStart: () => _startShift(context),
                          onEnd: () => _endShift(context),
                          onDiscard: () => _discardShift(context),
                        ),
                        WeekOverview(
                          records: records,
                          holidays: holidays,
                          active: c.active,
                          onDayTap: (day) => _openDay(context, day),
                        ),
                        Row(
                          spacing: 10,
                          children: [
                            Expanded(
                              child: LiveTodayTile(
                                records: records,
                                active: c.active,
                                holidays: holidays,
                                onTap: () => _openDay(context, dateOnly(DateTime.now())),
                              ),
                            ),
                            Expanded(
                              child: StatTile(
                                icon: Icons.calendar_month_rounded,
                                label: 'Tháng này',
                                value: money(month.earned),
                                hours: fmtHours(month.total),
                                color: Colors.indigo,
                                onTap: () => _openStats(context, StatsKind.month),
                              ),
                            ),
                            Expanded(
                              child: StatTile(
                                icon: Icons.emoji_events_outlined,
                                label: 'Năm nay',
                                value: money(year.earned),
                                hours: fmtHours(year.total),
                                color: Colors.deepOrange,
                                onTap: () => _openStats(context, StatsKind.year),
                              ),
                            ),
                          ],
                        ),
                        CompareTile(onOpen: () => _openCompare(context)),
                        HistoryPreviewCard(records: records, onOpen: () => _openHistory(context)),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 100),
                    child: Text(
                      'Thu nhập chỉ là ước tính. Mỗi ca được ghi theo ngày bắt đầu '
                      '(kể cả ca qua nửa đêm). Thứ 2–6: 8 giờ đầu x1, 8–12 giờ x1.5, trên 12 giờ x2. '
                      'Thứ 7, CN: 8 giờ đầu được bù vào giờ thường còn thiếu của tuần (tối đa 40 giờ), '
                      'sau đó x1.5, trên 12 giờ x2. Ngày lễ: x2, không tính vào giờ thường; tuần có '
                      'ngày lễ rơi vào thứ 2–6 thì cuối tuần không được bù.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Vào ca ngay với mức lương theo giờ mặc định trong Cài đặt, không hỏi lại.
  Future<void> _startShift(BuildContext context) => c.checkIn(c.settings.hourlyRate);

  /// Bảng chi tiết một ngày: các ca trong ngày và thống kê ngày đầy đủ.
  Future<void> _openDay(BuildContext context, DateTime day) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (sheetContext) => ListenableBuilder(
          listenable: c,
          builder: (_, __) {
            final rs = [
              for (final r in c.records)
                if (dateOnly(r.start) == day) r
            ];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '${weekdayFull[day.weekday - 1]}, ${dmyFmt.format(day)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                if (rs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        c.active != null && dateOnly(c.active!.start) == day
                            ? 'Đang trong ca. Ca sẽ được lưu khi bạn bấm "Ra ca".'
                            : 'Không có ca làm nào trong khoảng này.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else ...[
                  for (final r in rs)
                    RecordTile(
                      key: ValueKey(r.id),
                      record: r,
                      onTap: () => _editRecord(sheetContext, r),
                      onDelete: () => _deleteRecord(sheetContext, r),
                    ),
                  DaySummaryCard(
                    date: day,
                    summary: summarize(rs, day, DateTime(day.year, day.month, day.day + 1)),
                  ),
                ],
              ],
            );
          },
        ),
      );

  Future<void> _endShift(BuildContext context) async {
    final start = c.active?.start;
    if (start == null) return;
    final longShift = DateTime.now().difference(start).inHours >= 16;
    final err = await c.checkOut();
    if (!context.mounted) return;
    showToast(
      context,
      err ??
          (longShift
              ? 'Đã lưu. Ca dài bất thường, hãy kiểm tra lại giờ ra (chạm vào ca để sửa).'
              : 'Đã lưu ca làm.'),
    );
  }

  Future<void> _discardShift(BuildContext context) async {
    final ok = await confirmDialog(
      context,
      title: 'Hủy ca đang làm?',
      message: 'Ca này sẽ không được lưu.',
      action: 'Hủy ca',
    );
    if (ok) await c.discardActive();
  }

  Future<void> _editRecord(BuildContext context, [WorkRecord? existing]) async {
    final draft = await showModalBottomSheet<RecordDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => RecordEditor(
        existing: existing,
        defaultRate: c.settings.hourlyRate,
        validate: c.validate,
        typeOf: c.dayTypeFor,
      ),
    );
    if (draft == null) return;
    final err = await c.saveDraft(draft);
    if (context.mounted) showToast(context, err ?? 'Đã lưu.');
  }

  Future<void> _deleteRecord(BuildContext context, WorkRecord r) async {
    final ok = await confirmDialog(
      context,
      title: 'Xóa ca làm?',
      message: 'Xóa ca ${dmyFmt.format(r.start)} '
          '(${timeFmt.format(r.start)}–${timeFmt.format(r.end)})?',
      action: 'Xóa',
    );
    if (!ok) return;
    final err = await c.delete(r);
    if (context.mounted) showToast(context, err ?? 'Đã xóa.');
  }

  Future<void> _openSettings(BuildContext context) => Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => SettingsPage(c: c, lock: lock, reminders: reminders, avatar: avatar),
        ),
      );

  Future<void> _openAvatar(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => AvatarSheet(
          avatar: avatar,
          onPick: () => _pickAvatar(context),
          onRemove: () => _removeAvatar(context),
        ),
      );

  Future<void> _pickAvatar(BuildContext context) async {
    if (!kHasAvatarPicker) {
      showToast(context, 'Chọn ảnh chỉ có trong bản app đầy đủ.');
      return;
    }
    final err = await lock.runExternal(avatar.pick);
    if (err != null && context.mounted) showToast(context, err);
  }

  Future<void> _removeAvatar(BuildContext context) async {
    final ok = await confirmDialog(
      context,
      title: 'Xóa ảnh đại diện?',
      message: 'Ảnh sẽ được gỡ khỏi ứng dụng.',
      action: 'Xóa ảnh',
    );
    if (ok) await avatar.remove();
  }

  Future<void> _openHistory(BuildContext context, [HistoryPreset preset = HistoryPreset.all]) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => HistoryPage(
            c: c,
            initialPreset: preset,
            onEdit: (ctx, r) => _editRecord(ctx, r),
            onDelete: (ctx, r) => _deleteRecord(ctx, r),
          ),
        ),
      );

  Future<void> _openCompare(BuildContext context) => Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => ComparePage(c: c)),
      );

  Future<void> _openStats(BuildContext context, StatsKind kind) => Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => PeriodStatsPage(c: c, kind: kind)),
      );

  Future<void> _export(BuildContext context) => ExportFlow.run(context, c, lock);
}
