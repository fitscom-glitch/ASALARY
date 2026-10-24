import 'package:flutter/material.dart' hide Text;
import 'package:flutter/material.dart' as mat show Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/constants/app_constants.dart';
import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/logic/controllers/app_controller.dart';
import 'package:theo_doi_luong/logic/controllers/app_lock.dart';
import 'package:theo_doi_luong/logic/controllers/avatar_controller.dart';
import 'package:theo_doi_luong/presentation/screens/about/about_page.dart';
import 'package:theo_doi_luong/presentation/screens/backup/backup_page.dart';
import 'package:theo_doi_luong/presentation/screens/lock/security_page.dart';
import 'package:theo_doi_luong/presentation/screens/reminders/reminders_page.dart';
import 'package:theo_doi_luong/presentation/screens/settings/pay_settings_page.dart';
import 'package:theo_doi_luong/presentation/screens/settings/profile_settings_page.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';
import 'package:theo_doi_luong/presentation/widgets/profile_texts.dart';
import 'package:theo_doi_luong/presentation/widgets/settings_widgets.dart';
import 'package:theo_doi_luong/services/reminder_service.dart';

/// Trang Cài đặt: mỗi mục con mở một trang riêng (có mũi tên quay lại và vuốt cạnh để quay lại).
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.c,
    required this.lock,
    required this.reminders,
    required this.avatar,
  });
  final AppController c;
  final AppLock lock;
  final ReminderService reminders;
  final AvatarController avatar;

  Future<void> _open(BuildContext context, Widget page) =>
      Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => page));

  String _reminderSummary() {
    final n = c.settings.reminders.items.length;
    return n == 0 ? 'Chưa có nhắc nhở' : '$n nhắc nhở · ${c.settings.reminders.enabledCount} đang bật';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Cài đặt')),
        body: ListenableBuilder(
          listenable: Listenable.merge([c, lock, avatar]),
          builder: (context, _) {
            final s = c.settings;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                _ProfileCard(
                  c: c,
                  avatar: avatar,
                  onTap: () => _open(context, ProfileSettingsPage(c: c)),
                ),
                const SettingsSectionLabel('Chung'),
                SettingsGroup(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 12,
                        children: [
                          const Row(
                            spacing: 14,
                            children: [
                              IconBadge(icon: Icons.language_rounded, color: Colors.blue),
                              Text('Ngôn ngữ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5)),
                            ],
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<String>(
                              showSelectedIcon: false,
                              segments: [
                                for (final e in supportedLangs.entries)
                                  ButtonSegment(value: e.key, label: mat.Text(e.value)),
                              ],
                              selected: {s.lang},
                              onSelectionChanged: (v) => c.updateSettings(s.copyWith(lang: v.first)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SettingsTile(
                      icon: Icons.payments_rounded,
                      color: Colors.green.shade700,
                      title: 'Lương & ngày lễ',
                      subtitle: '${money(s.hourlyRate)}/giờ · ${s.holidays.length} ngày lễ',
                      onTap: () => _open(context, PaySettingsPage(c: c)),
                    ),
                  ],
                ),
                const SettingsSectionLabel('Tiện ích'),
                SettingsGroup(
                  children: [
                    SettingsTile(
                      icon: Icons.alarm_rounded,
                      color: Colors.deepOrange,
                      title: 'Nhắc nhở',
                      subtitle: _reminderSummary(),
                      onTap: () => _open(context, RemindersPage(c: c, service: reminders)),
                    ),
                    SettingsTile(
                      icon: Icons.shield_rounded,
                      color: Colors.indigo,
                      title: 'Bảo mật & mật khẩu',
                      subtitle: lock.enabled ? 'Đang bật' : 'Đang tắt',
                      onTap: () => _open(context, SecurityPage(lock: lock)),
                    ),
                    SettingsTile(
                      icon: Icons.cloud_sync_rounded,
                      color: Colors.teal,
                      title: 'Sao lưu & khôi phục dữ liệu',
                      subtitle: 'Xuất, nhập và chia sẻ dữ liệu',
                      onTap: () => _open(context, BackupPage(c: c, lock: lock)),
                    ),
                  ],
                ),
                const SettingsSectionLabel('Khác'),
                SettingsGroup(
                  children: [
                    SettingsTile(
                      icon: Icons.info_rounded,
                      color: Colors.blueGrey,
                      title: 'Thông tin',
                      subtitle: 'Phiên bản, tác giả, liên hệ',
                      onTap: () => _open(context, const AboutPage()),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    '$kAppName · v$kAppVersion',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
              ],
            );
          },
        ),
      );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.c, required this.avatar, required this.onTap});
  final AppController c;
  final AvatarController avatar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.tealMid, AppColors.tealDark],
            ),
            boxShadow: [
              BoxShadow(color: AppColors.tealMid.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: avatar.image,
                    child: avatar.image == null ? const Icon(Icons.person_rounded, size: 34, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: ProfileTexts(settings: c.settings, onDark: true, companySize: 20)),
                  const SizedBox(width: 8),
                  Icon(Icons.edit_rounded, color: Colors.white.withValues(alpha: 0.85), size: 20),
                ],
              ),
            ),
          ),
        ),
      );
}
