import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
      ],
    ),
  );
  return ok ?? false;
}
