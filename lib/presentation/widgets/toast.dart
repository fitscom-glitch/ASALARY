import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

void showToast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
}
