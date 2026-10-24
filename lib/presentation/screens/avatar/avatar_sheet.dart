import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/logic/controllers/avatar_controller.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';
import 'package:theo_doi_luong/presentation/widgets/nav_tile.dart';

class AvatarSheet extends StatelessWidget {
  const AvatarSheet({super.key, required this.avatar, required this.onPick, required this.onRemove});
  final AvatarController avatar;
  final VoidCallback onPick, onRemove;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: avatar,
        builder: (context, _) {
          final has = avatar.image != null;
          void run(VoidCallback action) {
            Navigator.pop(context);
            action();
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.tealMid.withValues(alpha: 0.12),
                      backgroundImage: avatar.image,
                      child: has ? null : const Icon(Icons.person_rounded, size: 52, color: AppColors.tealMid),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text('Ảnh đại diện', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  NavTile(
                    icon: Icons.photo_library_outlined,
                    title: has ? 'Đổi ảnh' : 'Chọn ảnh từ điện thoại',
                    onTap: () => run(onPick),
                  ),
                  if (has)
                    NavTile(icon: Icons.delete_outline_rounded, title: 'Xóa ảnh', onTap: () => run(onRemove)),
                ],
              ),
            ),
          );
        },
      );
}
