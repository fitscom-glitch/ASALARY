import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

class YearPickerDialog extends StatelessWidget {
  const YearPickerDialog({super.key, required this.initial});
  final DateTime initial;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Năm'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: YearPicker(
            firstDate: DateTime(2020),
            lastDate: DateTime(DateTime.now().year + 2),
            selectedDate: initial,
            onChanged: (d) => Navigator.pop(context, DateTime(d.year)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ],
      );
}
