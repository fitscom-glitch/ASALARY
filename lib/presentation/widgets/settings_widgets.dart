import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

/// Ô vuông bo góc có biểu tượng trắng, dùng làm biểu tượng của từng mục cài đặt.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, required this.color, this.size = 38});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.3),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, Color.lerp(color, Colors.black, 0.22)!],
          ),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.55),
      );
}

/// Tiêu đề nhỏ phía trên mỗi nhóm mục cài đặt.
class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 22, 8, 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.muted,
          ),
        ),
      );
}

/// Thẻ bo tròn chứa nhiều mục, ngăn cách bằng đường kẻ mảnh.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 66, endIndent: 0, color: Color(0xFFEDF1F4)),
              children[i],
            ],
          ],
        ),
      );
}

/// Một mục trong [SettingsGroup]: biểu tượng, tiêu đề, mô tả ngắn và mũi tên.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: IconBadge(icon: icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
        trailing: trailing ?? (onTap == null ? null : const Icon(Icons.chevron_right_rounded, color: AppColors.muted)),
        onTap: onTap,
      );
}
