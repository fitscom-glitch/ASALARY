import 'dart:async';

import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_constants.dart';
import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/utils/date_utils.dart';
import 'package:theo_doi_luong/data/database/app_database.dart';
import 'package:theo_doi_luong/logic/controllers/app_controller.dart';
import 'package:theo_doi_luong/logic/controllers/app_lock.dart';
import 'package:theo_doi_luong/logic/controllers/avatar_controller.dart';
import 'package:theo_doi_luong/presentation/screens/home/home_page.dart';
import 'package:theo_doi_luong/presentation/screens/lock/lock_gate.dart';
import 'package:theo_doi_luong/presentation/theme/app_theme.dart';
import 'package:theo_doi_luong/services/auto_backup_service.dart';
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
  bool _autoBackupChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_onControllerChanged);
    _controller.load();
    _lock.load();
    _avatar.load();
    AutoBackupService.instance.load();
  }

  /// Đặt lại lịch nhắc khi đổi giờ, thứ lặp lại hoặc ngôn ngữ (nội dung thông báo).
  void _onControllerChanged() {
    if (_controller.loading) return;
    final st = _controller.settings;
    currentLang = st.lang;
    // Lần đầu dữ liệu tải xong khi mở ứng dụng: kiểm tra và tự sao lưu nếu đến hạn.
    if (!_autoBackupChecked) {
      _autoBackupChecked = true;
      _scheduleAutoBackup();
    }
    if (st.lang != _lang) {
      _lang = st.lang;
      // Buộc mọi widget (kể cả const) dựng lại để áp dụng ngôn ngữ mới mà không đóng các trang đang mở.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _rebuildAll();
      });
    }
    // Lịch nhắc phụ thuộc cả ngày nghỉ có lương và việc vào ca / ra ca / hủy ca (để mở lại nhắc nhở sau khi vào ca).
    final sig = '${st.reminders.signature}|${st.lang}|${(st.holidays.toList()..sort()).join(',')}'
        '|${(st.paidLeave.keys.toList()..sort()).join(',')}|${_shiftStamp()}';
    if (sig != _reminderSig) {
      _reminderSig = sig;
      _syncReminders();
    }
  }

  /// Sao lưu tự động chạy nền, trễ vài giây để không tranh tài nguyên với lúc mở ứng dụng; không hiện gì lên màn hình.
  void _scheduleAutoBackup() {
    unawaited(Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) return AutoBackupService.instance.runIfDue(_controller);
    }));
  }

  /// Hôm nay đã có ca làm chưa: đang trong ca, hoặc có ca bắt đầu / kết thúc trong hôm nay.
  bool _hasShiftToday() {
    if (_controller.active != null) return true;
    final today = dateOnly(DateTime.now());
    return _controller.records.any((r) => dateOnly(r.start) == today || dateOnly(r.end) == today);
  }

  /// Có ca nào bắt đầu sau thời điểm [t] không (đang trong ca hoặc đã ghi).
  bool _hasShiftStartedAfter(DateTime t) {
    final a = _controller.active;
    if (a != null && a.start.isAfter(t)) return true;
    return _controller.records.any((r) => r.start.isAfter(t));
  }

  /// Dấu hiệu thay đổi khi vào ca / ra ca / hủy ca trong hôm nay, để đặt lại lịch nhắc.
  String _shiftStamp() {
    final today = dateOnly(DateTime.now());
    final n = _controller.records.where((r) => dateOnly(r.start) == today || dateOnly(r.end) == today).length;
    return '${_controller.active?.start.toIso8601String()}#$n';
  }

  Future<void> _syncReminders() async {
    currentLang = _controller.settings.lang;
    try {
      // Đã bấm "Tắt nhắc hôm nay" trên thông báo: hôm nay không nhắc nữa, trừ khi sau đó lại vào ca.
      final skipAt = await _reminders.skippedAt();
      var skipToday = skipAt != null;
      if (skipAt != null && _hasShiftStartedAfter(skipAt)) {
        await _reminders.clearSkip();
        skipToday = false;
      }
      await _reminders.sync(
        _controller.settings.reminders,
        _controller.settings.holidays,
        leaveDays: _controller.settings.paidLeave.keys.toSet(),
        hasShiftToday: _hasShiftToday(),
        skipToday: skipToday,
      );
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
      if (!_controller.loading) {
        _syncReminders(); // làm mới lịch cho 30 ngày tới
        _scheduleAutoBackup(); // quay lại ứng dụng sau nhiều ngày: sao lưu nếu đến hạn
      }
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
