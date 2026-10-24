import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

class Pill extends StatelessWidget {
  const Pill(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ),
      );
}
