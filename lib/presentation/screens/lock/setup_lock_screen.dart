import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/utils/validators.dart';
import 'package:theo_doi_luong/logic/controllers/app_lock.dart';
import 'package:theo_doi_luong/presentation/screens/lock/widgets/lock_badge.dart';
import 'package:theo_doi_luong/presentation/screens/lock/widgets/password_field.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

class SetupLockScreen extends StatefulWidget {
  const SetupLockScreen({super.key, required this.lock});
  final AppLock lock;

  @override
  State<SetupLockScreen> createState() => _SetupLockScreenState();
}

class _SetupLockScreenState extends State<SetupLockScreen> {
  final _pw = TextEditingController();
  final _confirm = TextEditingController();
  bool _hide = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final err = validateNewPassword(_pw.text, _confirm.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    await widget.lock.setPassword(_pw.text);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surfaceBg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    const LockBadge(icon: Icons.shield_outlined),
                    const Text(
                      'Bảo vệ ứng dụng bằng mật khẩu',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const Text(
                      'Tạo mật khẩu để người khác không mở được dữ liệu chấm công của bạn.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                    PasswordField(
                      controller: _pw,
                      label: 'Mật khẩu mới',
                      hide: _hide,
                      onToggle: () => setState(() => _hide = !_hide),
                    ),
                    PasswordField(
                      controller: _confirm,
                      label: 'Nhập lại mật khẩu',
                      hide: _hide,
                      onToggle: () => setState(() => _hide = !_hide),
                      onSubmitted: _busy ? null : _submit,
                    ),
                    if (_error != null)
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Tạo mật khẩu'),
                    ),
                    TextButton(
                      onPressed: _busy ? null : widget.lock.skipSetup,
                      child: const Text('Bỏ qua, bật sau trong Cài đặt'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
