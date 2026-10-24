import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

class NavTile extends StatelessWidget {
  const NavTile({required this.icon, required this.title, this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.tealMid.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.tealMid),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle!, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      );
}
