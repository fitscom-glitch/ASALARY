import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart' show Clipboard;

import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

class PasteBackupDialog extends StatefulWidget {
  const PasteBackupDialog({super.key});

  @override
  State<PasteBackupDialog> createState() => _PasteBackupDialogState();
}

class _PasteBackupDialogState extends State<PasteBackupDialog> {
  final _text = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && mounted) setState(() => _text.text = data!.text!);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Nhập từ nội dung đã sao chép'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              TextField(
                controller: _text,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: tr('Dán nội dung file sao lưu vào đây'),
                  errorText: _error == null ? null : tr(_error!),
                  border: const OutlineInputBorder(),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _paste,
                  icon: const Icon(Icons.content_paste_rounded),
                  label: const Text('Dán'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              if (_text.text.trim().isEmpty) {
                setState(() => _error = 'Chưa có nội dung để nhập.');
              } else {
                Navigator.pop(context, _text.text);
              }
            },
            child: const Text('Tiếp tục'),
          ),
        ],
      );
}
