import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/core/utils/date_utils.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/core/utils/number_parser.dart';
import 'package:theo_doi_luong/logic/controllers/app_controller.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';
import 'package:theo_doi_luong/presentation/widgets/toast.dart';

/// Thêm / sửa / xóa một ngày nghỉ có lương (Sick leave).
/// [day] = null: hỏi chọn ngày trước. [day] có giá trị: sửa hoặc thêm đúng ngày đó.
Future<void> showPaidLeaveDialog(BuildContext context, AppController c, {DateTime? day}) async {
  var d = day;
  if (d == null) {
    d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: tr('Chọn ngày nghỉ có lương'),
    );
    if (d == null || !context.mounted) return;
  }
  final date = dateOnly(d);
  final key = dateFmt.format(date);
  final existing = c.settings.paidLeave[key];
  final hasShift = c.records.any((r) => dateOnly(r.start) == date);

  final result = await showDialog<_Result>(
    context: context,
    builder: (_) => _PaidLeaveDialog(
      date: date,
      initialHours: existing?.hours ?? 8,
      rate: existing?.rate ?? c.settings.hourlyRate,
      isEdit: existing != null,
      hasShift: hasShift,
    ),
  );
  if (result == null) return;
  if (result.delete) {
    await c.removePaidLeave(key);
  } else {
    await c.setPaidLeave(date, result.hours!, existing?.rate ?? c.settings.hourlyRate);
  }
  if (context.mounted) showToast(context, result.delete ? 'Đã xóa ngày nghỉ.' : 'Đã lưu ngày nghỉ có lương.');
}

class _Result {
  const _Result.save(double this.hours) : delete = false;
  const _Result.remove()
      : hours = null,
        delete = true;
  final double? hours;
  final bool delete;
}

class _PaidLeaveDialog extends StatefulWidget {
  const _PaidLeaveDialog({
    required this.date,
    required this.initialHours,
    required this.rate,
    required this.isEdit,
    required this.hasShift,
  });
  final DateTime date;
  final double initialHours, rate;
  final bool isEdit, hasShift;

  @override
  State<_PaidLeaveDialog> createState() => _PaidLeaveDialogState();
}

class _PaidLeaveDialogState extends State<_PaidLeaveDialog> {
  late final TextEditingController _hours = TextEditingController(text: rateFmt.format(widget.initialHours));
  String? _error;

  @override
  void dispose() {
    _hours.dispose();
    super.dispose();
  }

  double? get _value {
    final v = parseNumber(_hours.text);
    return (v == null || v <= 0 || v > 24) ? null : v;
  }

  void _save() {
    final v = _value;
    if (v == null) {
      setState(() => _error = 'Số giờ phải lớn hơn 0 và tối đa 24.');
      return;
    }
    Navigator.pop(context, _Result.save(v));
  }

  @override
  Widget build(BuildContext context) {
    final v = _value;
    return AlertDialog(
      title: const Text('Ngày nghỉ có lương'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text('${weekdayFull[widget.date.weekday - 1]}, ${dmyFmt.format(widget.date)}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          TextField(
            controller: _hours,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              labelText: tr('Số giờ nghỉ'),
              suffixText: 'h',
              errorText: _error == null ? null : tr(_error!),
              border: const OutlineInputBorder(),
            ),
          ),
          Text(
            v == null ? '' : '≈ ${money(v * widget.rate)} (${money(widget.rate)}/giờ)',
            style: const TextStyle(fontSize: 13),
          ),
          if (widget.hasShift)
            const Text(
              'Ngày này đã có ca làm: biểu đồ tuần vẫn hiển thị ca làm.',
              style: TextStyle(fontSize: 12),
            ),
        ],
      ),
      actions: [
        if (widget.isEdit)
          TextButton(
            onPressed: () => Navigator.pop(context, const _Result.remove()),
            child: const Text('Xóa'),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: _save, child: const Text('Lưu')),
      ],
    );
  }
}
