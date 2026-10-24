import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/painting.dart' show ImageProvider;

import 'package:theo_doi_luong/services/avatar_store.dart';

class AvatarController extends ChangeNotifier {
  AvatarController(this._store);
  final AvatarStore _store;
  ImageProvider? image;

  Future<void> load() async {
    try {
      image = await _store.load();
    } catch (_) {}
    notifyListeners();
  }

  /// Trả về thông báo lỗi, hoặc null nếu thành công / người dùng hủy.
  Future<String?> pick() async {
    try {
      final img = await _store.pick();
      if (img != null) {
        image = img;
        notifyListeners();
      }
      return null;
    } catch (e) {
      return 'Không thể chọn ảnh: $e';
    }
  }

  Future<void> remove() async {
    try {
      await _store.remove();
    } catch (_) {}
    image = null;
    notifyListeners();
  }
}
