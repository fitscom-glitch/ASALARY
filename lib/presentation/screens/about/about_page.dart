import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/constants/app_constants.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';
import 'package:theo_doi_luong/presentation/widgets/settings_widgets.dart';

/// Trang "Thông tin" về ứng dụng.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Thông tin')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Center(
              child: Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.tealMid, AppColors.tealDark],
                  ),
                ),
                child: const Text('S', style: TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 14),
            const Center(child: Text(kAppName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1))),
            const Center(child: Text('Phần Mềm Chấm Công', style: TextStyle(color: AppColors.muted))),
            const SizedBox(height: 4),
            const Center(child: Text('Phiên bản $kAppVersion', style: TextStyle(color: AppColors.muted, fontSize: 12))),
            const SizedBox(height: 20),
            const SettingsGroup(
              children: [
                SettingsTile(
                  icon: Icons.person_outline_rounded,
                  color: Colors.teal,
                  title: 'Tác giả dự án: Trung Nguyen',
                ),
                SettingsTile(
                  icon: Icons.auto_awesome_rounded,
                  color: Colors.deepPurple,
                  title: 'Với sự hỗ trợ code của AI: Claude - Sonnet',
                ),
                SettingsTile(
                  icon: Icons.phone_outlined,
                  color: Colors.green,
                  title: 'Điện thoại liên hệ: 408-455-0327',
                ),
              ],
            ),
          ],
        ),
      );
}
