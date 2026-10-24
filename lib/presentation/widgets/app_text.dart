import 'package:flutter/material.dart' hide Text;
import 'package:flutter/material.dart' as mat show Text;

import 'package:theo_doi_luong/core/l10n/translator.dart';

/// Thay cho Text của Flutter: tự dịch chuỗi theo ngôn ngữ hiện tại.
class Text extends StatelessWidget {
  const Text(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) => mat.Text(
        tr(data),
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
      );
}
