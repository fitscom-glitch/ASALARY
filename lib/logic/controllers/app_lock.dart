import 'package:flutter/foundation.dart' show ChangeNotifier;

import 'package:theo_doi_luong/core/l10n/translator.dart';
import 'package:theo_doi_luong/services/security/biometrics_service.dart';
import 'package:theo_doi_luong/services/security/lock_store.dart';
import 'package:theo_doi_luong/services/security/password_hasher.dart';

class AppLock extends ChangeNotifier {
  AppLock(this._store, this._bio);
  final LockStore _store;
  final Biometrics _bio;

  /// Khóa lại khi ứng dụng bị đưa xuống nền quá số giây này.
  static const graceSeconds = 30;
  static const _maxFails = 5;
  static const _cooldown = Duration(seconds: 30);

  bool ready = false;
  bool enabled = false;
  bool locked = false;
  bool needsSetup = false;
  bool biometricOn = false;
  bool biometricAvailable = false;

  String? _hash;
  DateTime? _pausedAt;
  bool _busy = false; // đang hiện hộp thoại hệ thống (sinh trắc học, chọn file...)
  int _fails = 0;
  DateTime? _blockedUntil;

  Future<void> load() async {
    try {
      _hash = await _store.getString('lock_hash');
      biometricOn = await _store.getBool('lock_bio');
      final prompted = await _store.getBool('lock_prompted');
      enabled = _hash != null;
      locked = enabled;
      needsSetup = !enabled && !prompted;
      biometricAvailable = await _bio.available();
    } catch (_) {
      // Không đọc được cấu hình: mở ứng dụng bình thường để không khóa mất dữ liệu.
    }
    ready = true;
    notifyListeners();
  }

  /// Số giây còn bị chặn vì nhập sai nhiều lần (0 nếu không bị chặn).
  int get blockedSeconds {
    final until = _blockedUntil;
    if (until == null) return 0;
    final s = until.difference(DateTime.now()).inSeconds + 1;
    return s > 0 ? s : 0;
  }

  Future<void> skipSetup() async {
    await _store.setBool('lock_prompted', true);
    needsSetup = false;
    notifyListeners();
  }

  Future<void> setPassword(String password) async {
    final hash = PasswordHasher.create(password);
    _hash = hash;
    await _store.setString('lock_hash', hash);
    await _store.setBool('lock_prompted', true);
    enabled = true;
    locked = false;
    needsSetup = false;
    _fails = 0;
    _blockedUntil = null;
    notifyListeners();
  }

  bool checkPassword(String password) {
    final h = _hash;
    return h != null && PasswordHasher.verify(password, h);
  }

  /// Mở khóa bằng mật khẩu. Trả về null nếu đúng, hoặc thông báo lỗi.
  String? unlock(String password) {
    final blocked = blockedSeconds;
    if (blocked > 0) return 'Nhập sai quá nhiều lần. Thử lại sau $blocked giây.';
    if (checkPassword(password)) {
      locked = false;
      _fails = 0;
      _blockedUntil = null;
      notifyListeners();
      return null;
    }
    _fails++;
    if (_fails >= _maxFails) {
      _fails = 0;
      _blockedUntil = DateTime.now().add(_cooldown);
      return 'Nhập sai quá nhiều lần. Thử lại sau ${_cooldown.inSeconds} giây.';
    }
    return 'Mật khẩu không đúng.';
  }

  Future<String?> changePassword(String current, String newPassword) async {
    if (!checkPassword(current)) return 'Mật khẩu hiện tại không đúng.';
    await setPassword(newPassword);
    return null;
  }

  Future<String?> disable(String current) async {
    if (!checkPassword(current)) return 'Mật khẩu hiện tại không đúng.';
    _hash = null;
    enabled = false;
    locked = false;
    biometricOn = false;
    await _store.setString('lock_hash', null);
    await _store.setBool('lock_bio', false);
    notifyListeners();
    return null;
  }

  Future<bool> setBiometric(bool on) async {
    if (!enabled) return false;
    if (on) {
      _busy = true;
      final ok = await _bio.authenticate(tr('Xác nhận để bật mở khóa bằng sinh trắc học'));
      _busy = false;
      if (!ok) return false;
    }
    biometricOn = on;
    await _store.setBool('lock_bio', on);
    notifyListeners();
    return true;
  }

  Future<bool> unlockWithBiometric() async {
    if (!enabled || !biometricOn || !biometricAvailable || _busy) return false;
    _busy = true;
    final ok = await _bio.authenticate(tr('Mở khóa ứng dụng'));
    _busy = false;
    if (ok) {
      locked = false;
      _fails = 0;
      notifyListeners();
    }
    return ok;
  }

  /// Chạy một việc cần mở màn hình hệ thống (chia sẻ file, chọn file...)
  /// mà không bị tính là rời ứng dụng.
  Future<T> runExternal<T>(Future<T> Function() action) async {
    _busy = true;
    try {
      return await action();
    } finally {
      _busy = false;
    }
  }

  void onPaused() {
    if (enabled && !locked && !_busy) _pausedAt = DateTime.now();
  }

  void onResumed() {
    final t = _pausedAt;
    _pausedAt = null;
    if (enabled && !locked && !_busy && t != null && DateTime.now().difference(t).inSeconds >= graceSeconds) {
      locked = true;
      notifyListeners();
    }
  }
}
