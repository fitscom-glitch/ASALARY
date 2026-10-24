import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/utils/validators.dart';
import 'package:theo_doi_luong/presentation/screens/lock/widgets/password_field.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

/// Hộp thoại nhập mật khẩu dùng chung: bật khóa, đổi mật khẩu, tắt khóa.
/// `onSubmit` trả về thông báo lỗi (hộp thoại giữ nguyên để nhập lại) hoặc null nếu thành công.
class PasswordDialog extends StatefulWidget {
  const PasswordDialog({
    super.key,
    required this.title,
    required this.onSubmit,
    this.askCurrent = false,
    this.askNew = false,
  });
  final String title;
  final bool askCurrent, askNew;
  final Future<String?> Function(String current, String newPassword) onSubmit;

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final _cur = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _hide = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _cur.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    String? err;
    if (widget.askCurrent && _cur.text.isEmpty) err = 'Nhập mật khẩu hiện tại.';
    if (err == null && widget.askNew) err = validateNewPassword(_new.text, _confirm.text);
    if (err == null) {
      setState(() => _busy = true);
      err = await widget.onSubmit(_cur.text, _new.text);
    }
    if (!mounted) return;
    if (err == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _error = err;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    void toggle() => setState(() => _hide = !_hide);
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            if (widget.askCurrent)
              PasswordField(
                controller: _cur,
                label: 'Mật khẩu hiện tại',
                hide: _hide,
                onToggle: toggle,
                autofocus: true,
                onSubmitted: widget.askNew ? null : _go,
              ),
            if (widget.askNew) ...[
              PasswordField(
                controller: _new,
                label: 'Mật khẩu mới',
                hide: _hide,
                onToggle: toggle,
                autofocus: !widget.askCurrent,
              ),
              PasswordField(
                controller: _confirm,
                label: 'Nhập lại mật khẩu',
                hide: _hide,
                onToggle: toggle,
                onSubmitted: _go,
              ),
            ],
            if (_error != null)
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: _busy ? null : _go, child: const Text('Xác nhận')),
      ],
    );
  }
}
