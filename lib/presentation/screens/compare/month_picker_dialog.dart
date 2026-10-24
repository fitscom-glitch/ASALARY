import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

class MonthPickerDialog extends StatefulWidget {
  const MonthPickerDialog({super.key, required this.initial});
  final DateTime initial;

  @override
  State<MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<MonthPickerDialog> {
  late int _year = widget.initial.year;

  @override
  Widget build(BuildContext context) {
    final maxYear = DateTime.now().year + 2;
    return AlertDialog(
      title: Row(
        children: [
          IconButton(
            onPressed: _year > 2020 ? () => setState(() => _year--) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(child: Center(child: Text('$_year'))),
          IconButton(
            onPressed: _year < maxYear ? () => setState(() => _year++) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
      content: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var m = 1; m <= 12; m++)
            ChoiceChip(
              label: Text(monthShort[m - 1]),
              selected: _year == widget.initial.year && m == widget.initial.month,
              onSelected: (_) => Navigator.pop(context, DateTime(_year, m)),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
      ],
    );
  }
}
