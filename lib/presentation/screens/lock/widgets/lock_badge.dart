import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';

class LockBadge extends StatelessWidget {
  const LockBadge({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.tealMid, AppColors.tealDark],
            ),
          ),
          child: Icon(icon, size: 36, color: Colors.white),
        ),
      );
}
