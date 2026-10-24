import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/l10n/translator.dart';

class PasswordField extends StatelessWidget {
  const PasswordField({
    required this.controller,
    required this.label,
    required this.hide,
    required this.onToggle,
    this.onSubmitted,
    this.autofocus = false,
  });
  final TextEditingController controller;
  final String label;
  final bool hide;
  final VoidCallback onToggle;
  final VoidCallback? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        obscureText: hide,
        autofocus: autofocus,
        autocorrect: false,
        enableSuggestions: false,
        onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
        decoration: InputDecoration(
          labelText: tr(label),
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: onToggle,
          ),
        ),
      );
}
