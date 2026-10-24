import 'dart:async';

import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/constants/app_constants.dart';
import 'package:theo_doi_luong/logic/controllers/app_lock.dart';
import 'package:theo_doi_luong/presentation/screens/lock/widgets/lock_badge.dart';
import 'package:theo_doi_luong/presentation/screens/lock/widgets/password_field.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.lock});
  final AppLock lock;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pw = TextEditingController();
  bool _hide = true;
  bool _wrong = false;
  bool _wasBlocked = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.lock.unlockWithBiometric());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final blocked = widget.lock.blockedSeconds > 0;
      if (mounted && (blocked || _wasBlocked)) {
        _wasBlocked = blocked;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pw.dispose();
    super.dispose();
  }

  void _submit() {
    final err = widget.lock.unlock(_pw.text);
    if (err == null) return; // mở khóa thành công: LockGate tự gỡ màn hình này
    _pw.clear();
    setState(() {
      _wrong = widget.lock.blockedSeconds == 0;
      _wasBlocked = widget.lock.blockedSeconds > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lock = widget.lock;
    final blocked = lock.blockedSeconds;
    final errorColor = Theme.of(context).colorScheme.error;
    return Scaffold(
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
                  const LockBadge(icon: Icons.lock_rounded),
                  const Text(
                    kAppName,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'Nhập mật khẩu để mở ứng dụng',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                  PasswordField(
                    controller: _pw,
                    label: 'Mật khẩu',
                    hide: _hide,
                    onToggle: () => setState(() => _hide = !_hide),
                    onSubmitted: _submit,
                  ),
                  if (blocked > 0)
                    Text(
                      'Nhập sai quá nhiều lần. Thử lại sau $blocked giây.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: errorColor),
                    )
                  else if (_wrong)
                    Text('Mật khẩu không đúng.', textAlign: TextAlign.center, style: TextStyle(color: errorColor)),
                  FilledButton(
                    onPressed: blocked > 0 ? null : _submit,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Mở khóa'),
                  ),
                  if (lock.biometricOn && lock.biometricAvailable)
                    OutlinedButton.icon(
                      onPressed: lock.unlockWithBiometric,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text('Dùng vân tay / khuôn mặt'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
