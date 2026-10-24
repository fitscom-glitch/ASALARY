import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/logic/controllers/app_controller.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';
import 'package:theo_doi_luong/presentation/widgets/toast.dart';

/// Trang nhập hồ sơ: tên công ty, tên và ID hiển thị ở đầu trang chính.
class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key, required this.c});
  final AppController c;

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  late final TextEditingController _company = TextEditingController(text: widget.c.settings.companyName);
  late final TextEditingController _name = TextEditingController(text: widget.c.settings.userName);
  late final TextEditingController _id = TextEditingController(text: widget.c.settings.userId);

  @override
  void dispose() {
    _company.dispose();
    _name.dispose();
    _id.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final c = widget.c;
    await c.updateSettings(c.settings.copyWith(
      companyName: _company.text.trim(),
      userName: _name.text.trim(),
      userId: _id.text.trim(),
    ));
    if (!mounted) return;
    showToast(context, 'Đã lưu hồ sơ.');
    Navigator.pop(context);
  }

  InputDecoration _decoration(String label, IconData icon, {String? hint}) => InputDecoration(
        labelText: tr(label),
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Hồ sơ')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 0, 4, 16),
              child: Text(
                'Hiển thị ở đầu trang chính, bên cạnh ảnh đại diện.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ),
            TextField(
              controller: _company,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration: _decoration('Tên công ty', Icons.business_rounded),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: _decoration('Tên', Icons.badge_outlined),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _id,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: _decoration('ID', Icons.tag_rounded),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Lưu thay đổi'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        ),
      );
}
