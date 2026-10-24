import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/logic/controllers/avatar_controller.dart';

class AvatarButton extends StatelessWidget {
  const AvatarButton({super.key, required this.avatar, required this.onTap, this.radius = 20});
  final AvatarController avatar;
  final VoidCallback onTap;
  final double radius;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: avatar,
        builder: (context, _) => InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.tealMid, width: 2)),
            child: CircleAvatar(
              radius: radius,
              backgroundColor: AppColors.tealMid.withValues(alpha: 0.12),
              backgroundImage: avatar.image,
              child: avatar.image == null ? Icon(Icons.person_rounded, size: radius * 1.1, color: AppColors.tealMid) : null,
            ),
          ),
        ),
      );
}
