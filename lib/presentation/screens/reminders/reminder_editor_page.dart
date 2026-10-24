import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/reminder_config.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';
import 'package:theo_doi_luong/presentation/widgets/confirm_dialog.dart';
import 'package:theo_doi_luong/presentation/widgets/settings_widgets.dart';

/// Kết quả của trang sửa nhắc nhở: lưu [reminder] hoặc xóa nhắc nhở.
class ReminderEditResult {
  const ReminderEditResult.save(Reminder this.reminder);
  const ReminderEditResult.delete() : reminder = null;
  final Reminder? reminder;
  bool get deleted => reminder == null;
}

/// Trang thêm / sửa một nhắc nhở: giờ, tên, các ngày lặp lại (T2–CN và Lễ).
class ReminderEditorPage extends StatefulWidget {
  const ReminderEditorPage({super.key, required this.initial, required this.index, required this.isNew});
  final Reminder initial;
  final int index;
  final bool isNew;

  @override
  State<ReminderEditorPage> createState() => _ReminderEditorPageState();
}

class _ReminderEditorPageState extends State<ReminderEditorPage> {
  late int _minutes = widget.initial.minutes;
  late final Set<int> _days = {...widget.initial.days};
  late bool _holiday = widget.initial.holiday;
  late final TextEditingController _label = TextEditingController(text: widget.initial.label);
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _minutes ~/ 60, minute: _minutes % 60),
    );
    if (t != null) setState(() => _minutes = t.hour * 60 + t.minute);
  }

  void _save() {
    if (_days.isEmpty && !_holiday) {
      setState(() => _error = 'Hãy chọn ít nhất một ngày.');
      return;
    }
    Navigator.pop(
      context,
      ReminderEditResult.save(widget.initial.copyWith(
        minutes: _minutes,
        days: _days,
        holiday: _holiday,
        label: _label.text.trim(),
        enabled: true,
      )),
    );
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: 'Xóa nhắc nhở?',
      message: widget.initial.title(widget.index),
      action: 'Xóa',
    );
    if (ok && mounted) Navigator.pop(context, const ReminderEditResult.delete());
  }

  @override
  Widget build(BuildContext context) {
    final time = '${pad2(_minutes ~/ 60)}:${pad2(_minutes % 60)}';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'Thêm nhắc nhở' : 'Sửa nhắc nhở'),
        actions: [
          if (!widget.isNew)
            IconButton(
              tooltip: tr('Xóa'),
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _pickTime,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: Column(
                  children: [
                    const Text('Giờ nhắc', style: TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w300,
                        color: AppColors.tealDark,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _label,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: tr('Tên nhắc nhở (tùy chọn)'),
              hintText: tr(widget.initial.title(widget.index)),
              prefixIcon: const Icon(Icons.label_outline_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SettingsSectionLabel('Lặp lại'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 1; i <= 7; i++)
                        FilterChip(
                          label: Text(weekdayShort[i - 1]),
                          selected: _days.contains(i),
                          onSelected: (v) => setState(() {
                            v ? _days.add(i) : _days.remove(i);
                            _error = null;
                          }),
                        ),
                      FilterChip(
                        avatar: const Icon(Icons.celebration_rounded, size: 18),
                        label: const Text('Lễ'),
                        selected: _holiday,
                        selectedColor: Colors.deepOrange.withValues(alpha: 0.2),
                        onSelected: (v) => setState(() {
                          _holiday = v;
                          _error = null;
                        }),
                      ),
                    ],
                  ),
                  const Text(
                    'Ngày đã đánh dấu là ngày lễ trong Cài đặt chỉ chạy các nhắc nhở có chọn "Lễ", '
                    'không phụ thuộc thứ trong tuần.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Lưu'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ],
      ),
    );
  }
}
