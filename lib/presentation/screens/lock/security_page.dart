import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/logic/controllers/app_lock.dart';
import 'package:theo_doi_luong/presentation/screens/lock/password_dialog.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';
import 'package:theo_doi_luong/presentation/widgets/settings_widgets.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key, required this.lock});
  final AppLock lock;

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  String? _msg;
  AppLock get lock => widget.lock;

  Future<void> _toggleLock(bool on) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => on
          ? PasswordDialog(
              title: 'Tạo mật khẩu',
              askNew: true,
              onSubmit: (cur, nw) async {
                await lock.setPassword(nw);
                return null;
              },
            )
          : PasswordDialog(
              title: 'Tắt khóa ứng dụng',
              askCurrent: true,
              onSubmit: (cur, nw) => lock.disable(cur),
            ),
    );
    if (!mounted || ok != true) return;
    setState(() => _msg = on ? 'Đã bật khóa ứng dụng.' : 'Đã tắt khóa ứng dụng.');
  }

  Future<void> _change() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => PasswordDialog(
        title: 'Đổi mật khẩu',
        askCurrent: true,
        askNew: true,
        onSubmit: (cur, nw) => lock.changePassword(cur, nw),
      ),
    );
    if (!mounted || ok != true) return;
    setState(() => _msg = 'Đã đổi mật khẩu.');
  }

  Future<void> _toggleBio(bool on) async {
    final ok = await lock.setBiometric(on);
    if (!mounted) return;
    setState(() => _msg = (!ok && on) ? 'Không xác thực được nên chưa bật mở khóa sinh trắc học.' : null);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Bảo mật & mật khẩu')),
        body: ListenableBuilder(
          listenable: lock,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              SettingsGroup(
                children: [
                  SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    color: Colors.teal,
                    title: 'Khóa ứng dụng bằng mật khẩu',
                    subtitle: lock.enabled ? 'Đang bật' : 'Đang tắt',
                    trailing: Switch(value: lock.enabled, onChanged: _toggleLock),
                    onTap: () => _toggleLock(!lock.enabled),
                  ),
                  if (lock.enabled)
                    SettingsTile(
                      icon: Icons.password_rounded,
                      color: Colors.indigo,
                      title: 'Đổi mật khẩu',
                      onTap: _change,
                    ),
                  if (lock.enabled && lock.biometricAvailable)
                    SettingsTile(
                      icon: Icons.fingerprint_rounded,
                      color: Colors.deepOrange,
                      title: 'Mở khóa bằng vân tay / khuôn mặt',
                      trailing: Switch(value: lock.biometricOn, onChanged: _toggleBio),
                      onTap: () => _toggleBio(!lock.biometricOn),
                    ),
                ],
              ),
              if (lock.enabled && !lock.biometricAvailable)
                const Padding(
                  padding: EdgeInsets.fromLTRB(8, 10, 8, 0),
                  child: Text(
                    'Thiết bị chưa hỗ trợ hoặc chưa đăng ký vân tay / khuôn mặt.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
              if (_msg != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                  child: Text(_msg!, style: const TextStyle(color: AppColors.tealMid, fontWeight: FontWeight.w600)),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 16, 8, 0),
                child: Text(
                  'Nếu quên mật khẩu, bạn phải gỡ và cài lại ứng dụng rồi nhập dữ liệu từ file sao lưu. '
                  'Hãy xuất file sao lưu thường xuyên.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      );
}
