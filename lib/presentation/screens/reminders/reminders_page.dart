import 'package:flutter/material.dart' hide Text;
import 'package:flutter/material.dart' as mat show Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/constants/app_constants.dart';
import 'package:theo_doi_luong/core/constants/platform_features.dart';
import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/reminder_config.dart';
import 'package:theo_doi_luong/logic/controllers/app_controller.dart';
import 'package:theo_doi_luong/presentation/screens/reminders/reminder_editor_page.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';
import 'package:theo_doi_luong/presentation/widgets/toast.dart';
import 'package:theo_doi_luong/services/reminder_service.dart';

/// Danh sách nhắc nhở (giống báo thức): mỗi nhắc nhở có giờ, ngày lặp lại và công tắc bật/tắt.
class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key, required this.c, required this.service});
  final AppController c;
  final ReminderService service;

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> with WidgetsBindingObserver {
  static const _deniedMsg =
      'Chưa được cấp quyền thông báo. Hãy bật thông báo cho ứng dụng trong Cài đặt Android.';

  String? _msg;
  ReminderConfig get _cfg => widget.c.settings.reminders;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Người dùng vừa bật thông báo trong Cài đặt Android rồi quay lại: xóa dòng báo lỗi cũ.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _msg != null && kHasReminders) _recheckPermission();
  }

  Future<void> _recheckPermission() async {
    final ok = await widget.service.notificationsEnabled();
    if (ok && mounted) setState(() => _msg = null);
  }

  /// Xin quyền và cập nhật dòng báo lỗi theo kết quả (xóa dòng đỏ khi đã được cấp quyền).
  Future<bool> _ensurePermission() async {
    final ok = await widget.service.requestPermission();
    final err = widget.service.lastError;
    if (mounted) setState(() => _msg = ok ? null : (err == null ? _deniedMsg : '$_deniedMsg\n($err)'));
    return ok;
  }

  Future<void> _apply(List<Reminder> items, {bool askPermission = false}) async {
    if (askPermission && kHasReminders) await _ensurePermission();
    await widget.c.updateSettings(widget.c.settings.copyWith(reminders: _cfg.copyWith(items: items)));
  }

  Future<void> _edit(Reminder? existing) async {
    final items = [..._cfg.items];
    final index = existing == null ? items.length : items.indexWhere((r) => r.id == existing.id);
    if (index < 0) return;
    final result = await Navigator.of(context).push<ReminderEditResult>(
      MaterialPageRoute(
        builder: (_) => ReminderEditorPage(
          initial: existing ?? Reminder(id: _cfg.nextId, minutes: 8 * 60),
          index: index,
          isNew: existing == null,
        ),
      ),
    );
    if (result == null || !mounted) return;
    if (result.deleted) {
      items.removeAt(index);
      await _apply(items);
    } else if (existing == null) {
      await _apply([...items, result.reminder!], askPermission: true);
    } else {
      items[index] = result.reminder!;
      await _apply(items, askPermission: true);
    }
  }

  Future<void> _toggle(Reminder r, bool on) =>
      _apply([for (final x in _cfg.items) x.id == r.id ? x.copyWith(enabled: on) : x], askPermission: on);

  Future<void> _test() async {
    if (!await _ensurePermission()) return;
    try {
      await widget.service.showTest();
      if (mounted) showToast(context, 'Đã gửi thông báo thử. Hãy kéo thanh trạng thái xuống để xem.');
    } catch (e) {
      // Trước đây lỗi ở đây bị nuốt mất nên bấm nút mà không thấy gì.
      if (mounted) setState(() => _msg = 'Không gửi được thông báo thử: $e');
    }
  }

  /// Ví dụ: "T2, T3, T4, T5, T6", "T7, CN, Lễ", "Hàng ngày".
  String _daysText(Reminder r) {
    final d = r.days.toList()..sort();
    if (d.length == 7) return r.holiday ? tr('Hàng ngày') : '${tr('Hàng ngày')} (${tr('trừ ngày lễ')})';
    final parts = [for (final x in d) weekdayShort[x - 1], if (r.holiday) tr('Lễ')];
    return parts.isEmpty ? tr('Chưa chọn ngày') : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Nhắc nhở')),
        floatingActionButton: ListenableBuilder(
          listenable: widget.c,
          builder: (context, _) => _cfg.items.length >= kMaxReminders
              ? const SizedBox.shrink()
              : FloatingActionButton.extended(
                  onPressed: () => _edit(null),
                  icon: const Icon(Icons.add_alarm_rounded),
                  label: const Text('Thêm nhắc nhở'),
                ),
        ),
        body: ListenableBuilder(
          listenable: widget.c,
          builder: (context, _) {
            final items = _cfg.items;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
              children: [
                if (!kHasReminders)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Nhắc giờ chỉ hoạt động trong app Android (bản đầy đủ), không dùng được trên DartPad.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      spacing: 10,
                      children: [
                        Icon(Icons.alarm_off_rounded, size: 52, color: AppColors.muted),
                        Text('Chưa có nhắc nhở nào', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        Text(
                          'Bấm "Thêm nhắc nhở" để tạo báo thức nhắc chấm công.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                for (var i = 0; i < items.length; i++) ...[
                  _ReminderCard(
                    title: items[i].title(i),
                    time: '${pad2(items[i].minutes ~/ 60)}:${pad2(items[i].minutes % 60)}',
                    days: _daysText(items[i]),
                    enabled: items[i].enabled,
                    onTap: () => _edit(items[i]),
                    onToggle: (v) => _toggle(items[i], v),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_msg != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(_msg!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                if (kHasReminders && items.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: _test,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Gửi thông báo thử'),
                  ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 16, 4, 0),
                  child: Text(
                    'Thông báo hiện trên thanh trạng thái và phát chuông báo thức, kể cả khi đã tắt ứng dụng. '
                    'Nếu không nghe chuông, hãy kiểm tra âm lượng báo thức, cho phép thông báo và không hạn chế '
                    'pin cho ứng dụng trong Cài đặt Android. Lịch nhắc được làm mới mỗi khi bạn mở ứng dụng '
                    '(đặt trước tối đa 30 ngày).',
                    style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
                  ),
                ),
              ],
            );
          },
        ),
      );
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.title,
    required this.time,
    required this.days,
    required this.enabled,
    required this.onTap,
    required this.onToggle,
  });
  final String title, time, days;
  final bool enabled;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final fade = enabled ? 1.0 : 0.45;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
          child: Row(
            children: [
              Expanded(
                child: Opacity(
                  opacity: fade,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      mat.Text(tr(title), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                      mat.Text(
                        time,
                        style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w300, height: 1.15),
                      ),
                      mat.Text(days, style: const TextStyle(fontSize: 13, color: AppColors.tealMid, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              Switch(value: enabled, onChanged: onToggle),
            ],
          ),
        ),
      ),
    );
  }
}
