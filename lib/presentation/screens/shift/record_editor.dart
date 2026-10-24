import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/core/utils/date_utils.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/core/utils/number_parser.dart';
import 'package:theo_doi_luong/data/models/record_draft.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';
import 'package:theo_doi_luong/presentation/theme/day_type_style.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';
import 'package:theo_doi_luong/presentation/widgets/pill.dart';

class RecordEditor extends StatefulWidget {
  const RecordEditor({
    super.key,
    required this.existing,
    required this.defaultRate,
    required this.validate,
    required this.typeOf,
  });
  final WorkRecord? existing;
  final double defaultRate;
  final String? Function(RecordDraft) validate;
  final String Function(DateTime) typeOf;

  @override
  State<RecordEditor> createState() => _RecordEditorState();
}

class _RecordEditorState extends State<RecordEditor> {
  late DateTime _date;
  late TimeOfDay _in;
  late TimeOfDay _out;
  late final TextEditingController _rate;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _date = dateOnly(e?.start ?? DateTime.now());
    _in = e != null ? TimeOfDay.fromDateTime(e.start) : const TimeOfDay(hour: 9, minute: 0);
    _out = e != null ? TimeOfDay.fromDateTime(e.end) : const TimeOfDay(hour: 17, minute: 0);
    _rate = TextEditingController(text: rateFmt.format(e?.hourlyRate ?? widget.defaultRate));
  }

  @override
  void dispose() {
    _rate.dispose();
    super.dispose();
  }

  DateTime get _startDt =>
      DateTime(_date.year, _date.month, _date.day, _in.hour, _in.minute);

  DateTime get _endDt {
    final e = DateTime(_date.year, _date.month, _date.day, _out.hour, _out.minute);
    return e.isAfter(_startDt)
        ? e
        : DateTime(e.year, e.month, e.day + 1, e.hour, e.minute);
  }

  String _tod(TimeOfDay t) => '${pad2(t.hour)}:${pad2(t.minute)}';

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() {
      _date = dateOnly(d);
      _error = null;
    });
  }

  Future<void> _pickTime(bool isIn) async {
    final t = await showTimePicker(context: context, initialTime: isIn ? _in : _out);
    if (t == null) return;
    setState(() {
      if (isIn) {
        _in = t;
      } else {
        _out = t;
      }
      _error = null;
    });
  }

  void _save() {
    final rate = parseNumber(_rate.text);
    if (rate == null) {
      setState(() => _error = 'Mức lương không hợp lệ.');
      return;
    }
    if (_in == _out) {
      setState(() => _error = 'Giờ ra phải khác giờ vào.');
      return;
    }
    final draft = RecordDraft(
      id: widget.existing?.id,
      start: _startDt,
      end: _endDt,
      rate: rate,
    );
    final err = widget.validate(draft);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.pop(context, draft);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final minutes = _in == _out ? 0 : _endDt.difference(_startDt).inMinutes;
    final overnight = dateOnly(_endDt) != dateOnly(_startDt);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            Text(
              widget.existing == null ? 'Thêm ca làm' : 'Sửa ca làm',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event),
              label: Text(
                  '${weekdayShort[_date.weekday - 1]}, ${dmyFmt.format(_date)}'),
            ),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(true),
                    icon: const Icon(Icons.login),
                    label: Text('Vào ${_tod(_in)}'),
                  ),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(false),
                    icon: const Icon(Icons.logout),
                    label: Text('Ra ${_tod(_out)}'),
                  ),
                ),
              ],
            ),
            Text(
              'Thời lượng: ${fmtHours(minutes / 60)}${overnight && minutes > 0 ? ' · qua nửa đêm' : ''}',
              style: const TextStyle(color: Colors.black54),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Pill('Loại ngày: ${dayLabel(widget.typeOf(_date))}', color: typeColor(widget.typeOf(_date))),
            ),
            TextField(
              controller: _rate,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: tr('Lương theo giờ'),
                prefixText: r'$ ',
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null) Text(_error!, style: TextStyle(color: cs.error)),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}
