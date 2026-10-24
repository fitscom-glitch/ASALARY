import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/core/utils/number_parser.dart';
import 'package:theo_doi_luong/logic/controllers/app_controller.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';
import 'package:theo_doi_luong/presentation/widgets/settings_widgets.dart';
import 'package:theo_doi_luong/presentation/widgets/toast.dart';

/// Trang "Lương & ngày lễ": lương mặc định theo giờ và danh sách ngày lễ (tính x2).
class PaySettingsPage extends StatefulWidget {
  const PaySettingsPage({super.key, required this.c});
  final AppController c;

  @override
  State<PaySettingsPage> createState() => _PaySettingsPageState();
}

class _PaySettingsPageState extends State<PaySettingsPage> {
  late final TextEditingController _rate = TextEditingController(text: rateFmt.format(widget.c.settings.hourlyRate));
  String? _error;

  @override
  void dispose() {
    _rate.dispose();
    super.dispose();
  }

  Future<void> _saveRate() async {
    final rate = parseNumber(_rate.text);
    if (rate == null) {
      setState(() => _error = 'Mức lương không hợp lệ.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    await widget.c.updateSettings(widget.c.settings.copyWith(hourlyRate: rate));
    if (mounted) showToast(context, 'Đã lưu.');
  }

  Future<void> _addHoliday() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: tr('Chọn ngày lễ'),
    );
    if (d == null) return;
    final c = widget.c;
    await c.updateSettings(c.settings.copyWith(holidays: {...c.settings.holidays, dateFmt.format(d)}));
  }

  Future<void> _removeHoliday(String key) async {
    final c = widget.c;
    await c.updateSettings(c.settings.copyWith(holidays: {...c.settings.holidays}..remove(key)));
  }

  String _label(String key) {
    final d = DateTime.tryParse(key);
    return d == null ? key : '${weekdayShort[d.weekday - 1]}, ${dmyFmt.format(d)}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Lương & ngày lễ')),
        body: ListenableBuilder(
          listenable: widget.c,
          builder: (context, _) {
            final holidays = widget.c.settings.holidays.toList()..sort();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                const SettingsSectionLabel('Lương theo giờ'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 12,
                      children: [
                        TextField(
                          controller: _rate,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: tr('Lương mặc định (mỗi giờ)'),
                            prefixText: r'$ ',
                            errorText: _error == null ? null : tr(_error!),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        FilledButton.tonal(onPressed: _saveRate, child: const Text('Lưu')),
                        const Text(
                          'Lương mặc định chỉ áp dụng cho ca mới.',
                          style: TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                const SettingsSectionLabel('Ngày lễ (tính x2)'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 12,
                      children: [
                        if (holidays.isEmpty)
                          const Text('Chưa đánh dấu ngày lễ nào.', style: TextStyle(color: AppColors.muted))
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              for (final h in holidays)
                                InputChip(label: Text(_label(h)), onDeleted: () => _removeHoliday(h)),
                            ],
                          ),
                        OutlinedButton.icon(
                          onPressed: _addHoliday,
                          icon: const Icon(Icons.event_available),
                          label: const Text('Thêm ngày lễ'),
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(8, 16, 8, 0),
                  child: Text(
                    'Tuần làm việc bắt đầu thứ 2. Thứ 2–6 là ngày thường, thứ 7 và CN là ngày OT '
                    '(tự động). Ngày lễ được tính x2 và không tính vào giờ thường.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
                  ),
                ),
              ],
            );
          },
        ),
      );
}
