import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/pin_util.dart';

/// Kontaktdagi rasmlar — faqat shu qurilmada kesh (boshqalarga yuklanmaydi).
class ContactPhotoService {
  ContactPhotoService._();
  static final ContactPhotoService instance = ContactPhotoService._();

  final Map<String, File?> _fileCache = {};
  bool _contactsLoaded = false;
  final Map<String, Uint8List?> _phoneToPhoto = {};

  bool get isSupported => !kIsWeb;

  /// Kontakt rasmlarini fon rejimida indekslash.
  Future<void> preload() => _ensureContactsIndexed();

  Future<void> _ensureContactsIndexed() async {
    if (_contactsLoaded || kIsWeb) return;
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) {
      _contactsLoaded = true;
      return;
    }

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: true,
    );

    for (final c in contacts) {
      final photo = c.photo;
      if (photo == null || photo.isEmpty) continue;
      for (final phone in c.phones) {
        final normalized = normalizePhone(phone.number);
        if (!RegExp(r'^998\d{9}$').hasMatch(normalized)) continue;
        _phoneToPhoto.putIfAbsent(normalized, () => photo);
      }
    }
    _contactsLoaded = true;
  }

  Future<File?> photoFileForPhone(String? phone) async {
    if (kIsWeb || phone == null) return null;
    final normalized = normalizePhone(phone);
    if (_fileCache.containsKey(normalized)) {
      return _fileCache[normalized];
    }

    await _ensureContactsIndexed();
    final bytes = _phoneToPhoto[normalized];
    if (bytes == null || bytes.isEmpty) {
      _fileCache[normalized] = null;
      return null;
    }

    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}/contact_photo_cache');
      if (!await dir.exists()) await dir.create(recursive: true);
      final file = File('${dir.path}/$normalized.jpg');
      await file.writeAsBytes(bytes, flush: true);
      _fileCache[normalized] = file;
      return file;
    } catch (_) {
      _fileCache[normalized] = null;
      return null;
    }
  }

  void clearCache() {
    _fileCache.clear();
    _phoneToPhoto.clear();
    _contactsLoaded = false;
  }
}
