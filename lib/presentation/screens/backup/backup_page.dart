import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/constants/platform_features.dart';
import 'package:theo_doi_luong/logic/controllers/app_controller.dart';
import 'package:theo_doi_luong/logic/controllers/app_lock.dart';
import 'package:theo_doi_luong/presentation/screens/backup/backup_flow.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';
import 'package:theo_doi_luong/presentation/widgets/settings_widgets.dart';

/// Trang "Sao lưu & khôi phục dữ liệu".
class BackupPage extends StatelessWidget {
  const BackupPage({super.key, required this.c, required this.lock});
  final AppController c;
  final AppLock lock;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Sao lưu & khôi phục dữ liệu')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            const SettingsSectionLabel('Sao lưu'),
            SettingsGroup(
              children: [
                SettingsTile(
                  icon: Icons.save_alt_rounded,
                  color: Colors.teal,
                  title: 'Lưu file sao lưu vào máy',
                  subtitle: 'Chọn nơi lưu và đặt tên file sao lưu (.json).',
                  onTap: () => BackupFlow.saveToDevice(context, c, lock),
                ),
                SettingsTile(
                  icon: Icons.ios_share_rounded,
                  color: Colors.indigo,
                  title: 'Chia sẻ file sao lưu',
                  subtitle: 'Gửi qua ứng dụng khác (email, Drive, Zalo...).',
                  onTap: () => BackupFlow.share(context, c, lock),
                ),
              ],
            ),
            const SettingsSectionLabel('Khôi phục'),
            SettingsGroup(
              children: [
                if (kHasFilePicker)
                  SettingsTile(
                    icon: Icons.folder_open_rounded,
                    color: Colors.orange.shade800,
                    title: 'Nhập từ file sao lưu',
                    onTap: () => BackupFlow.importFromFile(context, c, lock),
                  ),
                SettingsTile(
                  icon: Icons.content_paste_rounded,
                  color: Colors.blueGrey,
                  title: 'Nhập từ nội dung đã sao chép',
                  onTap: () => BackupFlow.importFromText(context, c),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 16, 8, 0),
              child: Text(
                'Lưu toàn bộ ca làm và cài đặt để nhập lại khi cài lại ứng dụng.',
                style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
              ),
            ),
          ],
        ),
      );
}
