import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory, getExternalStorageDirectory;
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;

import 'package:theo_doi_luong/logic/controllers/app_controller.dart';

/// Tự động sao lưu dữ liệu định kỳ khi mở ứng dụng.
///
/// - Chạy nền, không hiện hộp thoại hay vòng quay nào: ghi file xong là thôi.
/// - Mỗi lần sao lưu tạo một file MỚI có hậu tố ngày giờ (không bao giờ ghi đè file cũ).
/// - Cấu hình (bật/tắt, tần suất, thư mục) lưu riêng, không nằm trong file sao lưu
///   nên nhập dữ liệu không làm mất cấu hình này.
class AutoBackupService extends ChangeNotifier {
  AutoBackupService._();
  static final AutoBackupService instance = AutoBackupService._();

  /// Các mức tần suất cho phép (số ngày).
  static const intervalOptions = [1, 3, 7, 14, 30];

  static const _kEnabled = 'autobackup_enabled';
  static const _kDays = 'autobackup_days';
  static const _kDir = 'autobackup_dir';
  static const _kLast = 'autobackup_last';
  static const _kLastFile = 'autobackup_last_file';

  bool enabled = false;
  int intervalDays = 7;

  /// Thư mục người dùng chọn; null = dùng thư mục mặc định của ứng dụng.
  String? customDir;

  /// Thư mục mặc định của ứng dụng (đã xác định sau [load]).
  String? defaultDir;

  DateTime? lastBackup;
  String? lastFile;

  /// Cảnh báo / lỗi của lần chạy gần nhất (null nếu bình thường). Chỉ lưu trong bộ nhớ.
  String? lastIssue;
  bool running = false;
  bool _loaded = false;

  /// Thư mục đang được dùng để lưu.
  String? get effectiveDir => customDir ?? defaultDir;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool(_kEnabled) ?? false;
    final d = prefs.getInt(_kDays);
    intervalDays = intervalOptions.contains(d) ? d! : 7;
    customDir = prefs.getString(_kDir);
    final last = prefs.getString(_kLast);
    lastBackup = last == null ? null : DateTime.tryParse(last);
    lastFile = prefs.getString(_kLastFile);
    try {
      defaultDir = await _resolveDefaultDir();
    } catch (_) {
      defaultDir = null;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<String> _resolveDefaultDir() async {
    Directory? base;
    if (Platform.isAndroid) {
      try {
        base = await getExternalStorageDirectory();
      } catch (_) {}
    }
    base ??= await getApplicationDocumentsDirectory();
    return p.join(base.path, 'backups');
  }

  Future<void> setEnabled(bool v) async {
    await load();
    enabled = v;
    lastIssue = null;
    (await SharedPreferences.getInstance()).setBool(_kEnabled, v);
    notifyListeners();
  }

  Future<void> setIntervalDays(int days) async {
    await load();
    intervalDays = days;
    (await SharedPreferences.getInstance()).setInt(_kDays, days);
    notifyListeners();
  }

  Future<void> setCustomDir(String? dir) async {
    await load();
    customDir = (dir == null || dir.trim().isEmpty) ? null : dir.trim();
    lastIssue = null;
    final prefs = await SharedPreferences.getInstance();
    if (customDir == null) {
      await prefs.remove(_kDir);
    } else {
      await prefs.setString(_kDir, customDir!);
    }
    notifyListeners();
  }

  /// Đã đến hạn sao lưu chưa (tính theo ngày lịch, không bị lệch do đổi giờ mùa hè).
  bool isDue(DateTime now) {
    if (!enabled) return false;
    final last = lastBackup;
    if (last == null) return true;
    final days = DateTime.utc(now.year, now.month, now.day).difference(DateTime.utc(last.year, last.month, last.day)).inDays;
    return days >= intervalDays;
  }

  /// Gọi khi mở ứng dụng: chỉ sao lưu nếu đã bật và đến hạn. Không ném lỗi, không chặn giao diện.
  Future<void> runIfDue(AppController c) async {
    try {
      await load();
      if (running || !isDue(DateTime.now())) return;
      await runNow(c);
    } catch (_) {
      // Sao lưu tự động không được làm hỏng ứng dụng.
    }
  }

  /// Sao lưu ngay. Trả về true nếu đã ghi file. Dữ liệu trống thì bỏ qua.
  Future<bool> runNow(AppController c) async {
    await load();
    if (running) return false;
    if (c.records.isEmpty && c.settings.paidLeave.isEmpty) {
      lastIssue = 'Chưa có dữ liệu để sao lưu.';
      notifyListeners();
      return false;
    }
    running = true;
    lastIssue = null;
    notifyListeners();
    try {
      final json = c.buildBackup().toJson();
      final fallback = defaultDir;
      String? savedPath;
      Object? firstError;
      if (customDir != null) {
        try {
          savedPath = await _write(customDir!, json);
        } catch (e) {
          firstError = e;
        }
      }
      if (savedPath == null && fallback != null) {
        try {
          savedPath = await _write(fallback, json);
          if (firstError != null) {
            lastIssue = 'Không ghi được vào thư mục đã chọn (có thể thiếu quyền truy cập bộ nhớ), '
                'đã lưu vào thư mục riêng của ứng dụng.';
          }
        } catch (e) {
          firstError ??= e;
        }
      }
      if (savedPath == null) {
        lastIssue = 'Không thể sao lưu: ${firstError ?? 'không xác định được thư mục lưu'}';
        return false;
      }
      lastBackup = DateTime.now();
      lastFile = savedPath;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLast, lastBackup!.toIso8601String());
      await prefs.setString(_kLastFile, savedPath);
      return true;
    } catch (e) {
      lastIssue = 'Không thể sao lưu: $e';
      return false;
    } finally {
      running = false;
      notifyListeners();
    }
  }

  /// Ghi file mới có hậu tố ngày giờ; nếu trùng tên (hiếm) thì thêm số thứ tự, không bao giờ ghi đè.
  Future<String> _write(String dir, String json) async {
    final d = Directory(dir);
    if (!await d.exists()) await d.create(recursive: true);
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    var path = p.join(dir, 'asalary_tu_dong_$stamp.json');
    var n = 2;
    while (await File(path).exists()) {
      path = p.join(dir, 'asalary_tu_dong_${stamp}_$n.json');
      n++;
    }
    await File(path).writeAsString(json, flush: true);
    return path;
  }
}
