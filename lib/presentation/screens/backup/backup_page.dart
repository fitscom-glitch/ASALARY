import 'dart:io' show Platform;

import 'package:file_picker/file_picker.dart' show FilePicker;
import 'package:flutter/material.dart' hide Text;
import 'package:intl/intl.dart' show DateFormat;
import 'package:permission_handler/permission_handler.dart' show Permission;
import 'package:path/path.dart' as p;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/constants/platform_features.dart';
import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/logic/controllers/app_controller.dart';
import 'package:theo_doi_luong/logic/controllers/app_lock.dart';
import 'package:theo_doi_luong/presentation/screens/backup/backup_flow.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';
import 'package:theo_doi_luong/presentation/widgets/settings_widgets.dart';
import 'package:theo_doi_luong/presentation/widgets/toast.dart';
import 'package:theo_doi_luong/services/auto_backup_service.dart';

/// Trang "Sao lưu & khôi phục dữ liệu".
class BackupPage extends StatelessWidget {
  const BackupPage({super.key, required this.c, required this.lock});
  final AppController c;
  final AppLock lock;

  static String _intervalLabel(int days) => switch (days) {
        1 => 'Mỗi ngày',
        3 => 'Mỗi 3 ngày',
        7 => 'Mỗi tuần',
        14 => 'Mỗi 2 tuần',
        30 => 'Mỗi tháng',
        _ => 'Mỗi $days ngày',
      };

  Future<void> _pickInterval(BuildContext context, AutoBackupService s) async {
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Tần suất sao lưu'),
        children: [
          for (final d in AutoBackupService.intervalOptions)
            ListTile(
              title: Text(_intervalLabel(d)),
              trailing: d == s.intervalDays ? const Icon(Icons.check_rounded, color: AppColors.tealMid) : null,
              onTap: () => Navigator.pop(ctx, d),
            ),
        ],
      ),
    );
    if (v != null) await s.setIntervalDays(v);
  }

  Future<void> _pickDir(BuildContext context, AutoBackupService s) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Thư mục sao lưu'),
        children: [
          ListTile(
            leading: const Icon(Icons.folder_open_rounded),
            title: const Text('Chọn thư mục khác'),
            onTap: () => Navigator.pop(ctx, 'pick'),
          ),
          if (s.customDir != null)
            ListTile(
              leading: const Icon(Icons.restore_rounded),
              title: const Text('Dùng thư mục mặc định của ứng dụng'),
              onTap: () => Navigator.pop(ctx, 'default'),
            ),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice == 'default') {
      await s.setCustomDir(null);
      return;
    }
    try {
      // Android 11 trở lên chỉ cho ghi vào thư mục ngoài ứng dụng khi có quyền "Truy cập mọi tệp".
      if (Platform.isAndroid) {
        final st = Permission.manageExternalStorage;
        if (!await st.isGranted) {
          await lock.runExternal(() => st.request());
          if (!await st.isGranted && context.mounted) {
            showToast(context, 'Chưa cấp quyền truy cập bộ nhớ: khi không ghi được, file sẽ lưu vào thư mục riêng của ứng dụng.');
          }
        }
      }
      final dir = await lock.runExternal(() => FilePicker.getDirectoryPath(dialogTitle: tr('Chọn thư mục sao lưu')));
      if (dir != null) await s.setCustomDir(dir);
    } catch (e) {
      if (context.mounted) showToast(context, 'Không thể chọn thư mục: $e');
    }
  }

  Future<void> _runNow(BuildContext context, AutoBackupService s) async {
    final ok = await s.runNow(c);
    if (!context.mounted) return;
    showToast(context, ok ? 'Đã sao lưu: ${p.basename(s.lastFile ?? '')}' : (s.lastIssue ?? 'Không thể sao lưu.'));
  }

  Widget _status(AutoBackupService s) {
    final last = s.lastBackup;
    final issue = s.lastIssue;
    final lines = <Widget>[
      if (last != null)
        Text(
          '${tr('Lần gần nhất')}: ${DateFormat('dd/MM/yyyy HH:mm').format(last)}'
          '${s.lastFile == null ? '' : '\n${p.basename(s.lastFile!)}'}',
          style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
        )
      else
        const Text('Chưa có bản sao lưu tự động nào.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
      if (issue != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(issue, style: TextStyle(fontSize: 12, color: Colors.orange.shade800, height: 1.4)),
        ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: lines),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: AutoBackupService.instance,
        builder: (context, _) {
          final s = AutoBackupService.instance;
          return Scaffold(
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
                const SettingsSectionLabel('Sao lưu tự động'),
                SettingsGroup(
                  children: [
                    SettingsTile(
                      icon: Icons.autorenew_rounded,
                      color: Colors.green.shade700,
                      title: 'Tự động sao lưu khi mở ứng dụng',
                      subtitle: 'Chạy nền, không chiếm màn hình. Mỗi lần tạo file mới, không ghi đè file cũ.',
                      trailing: Switch(value: s.enabled, onChanged: s.setEnabled),
                      onTap: () => s.setEnabled(!s.enabled),
                    ),
                    if (s.enabled) ...[
                      SettingsTile(
                        icon: Icons.schedule_rounded,
                        color: Colors.blue.shade700,
                        title: 'Tần suất sao lưu',
                        subtitle: _intervalLabel(s.intervalDays),
                        onTap: () => _pickInterval(context, s),
                      ),
                      if (kHasFilePicker)
                        SettingsTile(
                          icon: Icons.folder_rounded,
                          color: Colors.amber.shade800,
                          title: 'Thư mục sao lưu',
                          subtitle: s.effectiveDir ?? '...',
                          onTap: () => _pickDir(context, s),
                        ),
                      SettingsTile(
                        icon: Icons.play_circle_outline_rounded,
                        color: Colors.teal,
                        title: 'Sao lưu ngay',
                        subtitle: s.running ? 'Đang sao lưu...' : null,
                        onTap: s.running ? null : () => _runNow(context, s),
                      ),
                    ],
                  ],
                ),
                if (s.enabled) _status(s),
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
                    'Lưu toàn bộ ca làm và cài đặt để nhập lại khi cài lại ứng dụng. '
                    'File sao lưu không được mã hóa, hãy chọn thư mục an toàn.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
                  ),
                ),
              ],
            ),
          );
        },
      );
}
