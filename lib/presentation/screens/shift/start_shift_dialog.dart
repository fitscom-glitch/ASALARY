import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/core/utils/number_parser.dart';
import 'package:theo_doi_luong/presentation/theme/day_type_style.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';
import 'package:theo_doi_luong/presentation/widgets/pill.dart';

class StartShiftDialog extends StatefulWidget {
  const StartShiftDialog({super.key, required this.defaultRate, required this.dayType});
  final double defaultRate;
  final String dayType;

  @override
  State<StartShiftDialog> createState() => _StartShiftDialogState();
}

class _StartShiftDialogState extends State<StartShiftDialog> {
  late final TextEditingController _rate =
      TextEditingController(text: rateFmt.format(widget.defaultRate));
  String? _error;

  @override
  void dispose() {
    _rate.dispose();
    super.dispose();
  }

  void _submit() {
    final rate = parseNumber(_rate.text);
    if (rate == null) {
      setState(() => _error = 'Mức lương không hợp lệ.');
      return;
    }
    Navigator.pop(context, rate);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Bắt đầu ca làm'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Pill('Hôm nay tính là: ${dayLabel(widget.dayType)}', color: typeColor(widget.dayType)),
              TextField(
                controller: _rate,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: tr('Lương theo giờ'),
                  prefixText: r'$ ',
                  errorText: _error == null ? null : tr(_error!),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(onPressed: _submit, child: const Text('Vào ca')),
        ],
      );
}
