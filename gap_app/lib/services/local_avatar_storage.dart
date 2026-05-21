import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

/// Profil rasmlari faqat qurilmada (serverga yuborilmaydi).
class LocalAvatarStorage {
  LocalAvatarStorage._();
  static final LocalAvatarStorage instance = LocalAvatarStorage._();

  static String fileNameForUser(String userId) => 'avatar_$userId.jpg';

  Future<Directory?> _avatarsDir() async {
    if (kIsWeb) return null;
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/avatars');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File?> fileForUser(String userId, String? fileName) async {
    if (kIsWeb || fileName == null || fileName.isEmpty) return null;
    final dir = await _avatarsDir();
    if (dir == null) return null;
    final file = File('${dir.path}/$fileName');
    if (await file.exists()) return file;
    return null;
  }

  Future<String?> saveForUser(String userId, File source) async {
    if (kIsWeb) return null;
    final dir = await _avatarsDir();
    if (dir == null) return null;
    final name = fileNameForUser(userId);
    final dest = File('${dir.path}/$name');
    await source.copy(dest.path);
    return name;
  }

  Future<void> deleteForUser(String userId, String? fileName) async {
    if (kIsWeb) return;
    final file = await fileForUser(userId, fileName ?? fileNameForUser(userId));
    if (file != null && await file.exists()) {
      await file.delete();
    }
  }
}
