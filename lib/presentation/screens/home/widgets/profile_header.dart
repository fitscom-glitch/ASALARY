import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/data/preferences/app_settings.dart';
import 'package:theo_doi_luong/logic/controllers/avatar_controller.dart';
import 'package:theo_doi_luong/presentation/screens/avatar/avatar_button.dart';
import 'package:theo_doi_luong/presentation/widgets/profile_texts.dart';

/// Đầu trang chính: ảnh đại diện và ba dòng hồ sơ (công ty, tên, ID).
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.settings, required this.avatar, required this.onAvatarTap});
  final AppSettings settings;
  final AvatarController avatar;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          AvatarButton(avatar: avatar, onTap: onAvatarTap, radius: 28),
          const SizedBox(width: 12),
          Expanded(child: ProfileTexts(settings: settings)),
        ],
      );
}
