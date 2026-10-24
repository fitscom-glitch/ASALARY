import 'package:flutter/material.dart' hide Text;
import 'package:flutter/material.dart' as mat show Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/data/preferences/app_settings.dart';

/// Ba dòng hồ sơ: tên công ty (IN HOA, đậm, lớn), "Tên: ...", "ID: ...".
///
/// Dùng `mat.Text` để nội dung người dùng nhập không bị đưa qua bảng dịch.
class ProfileTexts extends StatelessWidget {
  const ProfileTexts({super.key, required this.settings, this.onDark = false, this.companySize = 21});
  final AppSettings settings;
  final bool onDark;
  final double companySize;

  @override
  Widget build(BuildContext context) {
    final company = settings.companyName.trim();
    final name = settings.userName.trim();
    final id = settings.userId.trim();
    final main = onDark ? Colors.white : AppColors.tealDark;
    final sub = onDark ? Colors.white.withValues(alpha: 0.85) : AppColors.muted;
    final subStyle = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: sub, height: 1.25);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: mat.Text(
            company.isEmpty ? tr('TÊN CÔNG TY') : company.toUpperCase(),
            maxLines: 1,
            style: TextStyle(
              fontSize: companySize,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
              height: 1.2,
              color: company.isEmpty ? sub : main,
            ),
          ),
        ),
        mat.Text('${tr('Tên')}: ${name.isEmpty ? '—' : name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: subStyle),
        mat.Text('ID: ${id.isEmpty ? '—' : id}', maxLines: 1, overflow: TextOverflow.ellipsis, style: subStyle),
      ],
    );
  }
}
