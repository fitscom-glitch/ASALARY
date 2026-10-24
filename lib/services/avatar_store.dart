import 'dart:io';

import 'package:file_selector/file_selector.dart' show XTypeGroup, openFile;
import 'package:flutter/painting.dart' show FileImage, ImageProvider, ResizeImage;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;

/// Lưu ảnh đại diện: chép ảnh vào thư mục riêng của ứng dụng và nhớ đường dẫn.
class AvatarStore {
  Future<ImageProvider?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('avatar_path');
    if (path == null) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    return ResizeImage(FileImage(file), width: 256);
  }

  /// Mở bộ chọn ảnh của hệ thống. Trả về null nếu người dùng hủy.
  Future<ImageProvider?> pick() async {
    final picked = await openFile(
      acceptedTypeGroups: const [XTypeGroup(label: 'images', mimeTypes: ['image/*'])],
    );
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) return null;
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg'));
    await file.writeAsBytes(bytes, flush: true);
    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getString('avatar_path');
    await prefs.setString('avatar_path', file.path);
    if (old != null && old != file.path) {
      try {
        await File(old).delete();
      } catch (_) {}
    }
    return ResizeImage(FileImage(file), width: 256);
  }

  Future<void> remove() async {
    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getString('avatar_path');
    await prefs.remove('avatar_path');
    if (old != null) {
      try {
        await File(old).delete();
      } catch (_) {}
    }
  }
}
