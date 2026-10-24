import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_constants.dart';
import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/data/database/app_database.dart';
import 'package:theo_doi_luong/logic/controllers/app_controller.dart';
import 'package:theo_doi_luong/logic/controllers/app_lock.dart';
import 'package:theo_doi_luong/logic/controllers/avatar_controller.dart';
import 'package:theo_doi_luong/presentation/screens/home/home_page.dart';
import 'package:theo_doi_luong/presentation/screens/lock/lock_gate.dart';
import 'package:theo_doi_luong/presentation/theme/app_theme.dart';
import 'package:theo_doi_luong/services/avatar_store.dart';
import 'package:theo_doi_luong/services/reminder_service.dart';
import 'package:theo_doi_luong/services/security/biometrics_service.dart';
import 'package:theo_doi_luong/services/security/lock_store.dart';

class SalaryApp extends StatefulWidget {
  const SalaryApp({super.key});
  @override
  State<SalaryApp> createState() => _SalaryAppState();
}

class _SalaryAppState extends State<SalaryApp> with WidgetsBindingObserver {
  final _controller = AppController(AppDatabase.instance);
  final _lock = AppLock(LockStore(), Biometrics());
  final _reminders = ReminderService();
  final _avatar = AvatarController(AvatarStore());
  String _reminderSig = '';
  String _lang = currentLang;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_onControllerChanged);
    _controller.load();
    _lock.load();
    _avatar.load();
  }

  /// Đặt lại lịch nhắc khi đổi giờ, thứ lặp lại hoặc ngôn ngữ (nội dung thông báo).
  void _onControllerChanged() {
    if (_controller.loading) return;
    final st = _controller.settings;
    currentLang = st.lang;
    if (st.lang != _lang) {
      _lang = st.lang;
      // Buộc mọi widget (kể cả const) dựng lại để áp dụng ngôn ngữ mới mà không đóng các trang đang mở.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _rebuildAll();
      });
    }
    final sig = '${st.reminders.signature}|${st.lang}|${(st.holidays.toList()..sort()).join(',')}';
    if (sig != _reminderSig) {
      _reminderSig = sig;
      _syncReminders();
    }
  }

  Future<void> _syncReminders() async {
    currentLang = _controller.settings.lang;
    try {
      await _reminders.sync(_controller.settings.reminders, _controller.settings.holidays);
    } catch (_) {
      // Không cho thông báo lỗi làm hỏng ứng dụng.
    }
  }

  void _rebuildAll() {
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    (context as Element).visitChildren(mark);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lock.onPaused();
    } else if (state == AppLifecycleState.resumed) {
      _lock.onResumed();
      if (!_controller.loading) _syncReminders(); // làm mới lịch cho 30 ngày tới
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _lock.dispose();
    _avatar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          currentLang = _controller.settings.lang;
          return _buildApp();
        },
      );

  Widget _buildApp() => MaterialApp(
        title: kAppName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, child) => LockGate(lock: _lock, child: child ?? const SizedBox.shrink()),
        home: HomePage(c: _controller, lock: _lock, reminders: _reminders, avatar: _avatar),
      );
}
