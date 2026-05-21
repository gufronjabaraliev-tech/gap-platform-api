import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_contacts/flutter_contacts.dart';

import '../models/device_contact.dart';
import '../utils/pin_util.dart';

class DeviceContactsService {
  bool get isSupported => !kIsWeb;

  Future<({bool granted, String? message})> requestAccess() async {
    if (kIsWeb) {
      return (
        granted: false,
        message:
            'Kontaktlar brauzerda ishlamaydi. Android yoki iOS ilovasidan foydalaning.',
      );
    }
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) {
      return (
        granted: false,
        message: 'Kontaktlarga ruxsat berilmadi. Sozlamalardan yoqing.',
      );
    }
    return (granted: true, message: null);
  }

  Future<List<DeviceContact>> loadUzPhoneContacts() async {
    if (kIsWeb) return [];

    final raw = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    final byPhone = <String, DeviceContact>{};

    for (final c in raw) {
      final name = c.displayName.trim().isEmpty
          ? 'Noma\'lum'
          : c.displayName.trim();

      for (final phone in c.phones) {
        final normalized = normalizePhone(phone.number);
        if (!RegExp(r'^998\d{9}$').hasMatch(normalized)) {
          continue;
        }
        final key = normalized;
        if (!byPhone.containsKey(key)) {
          byPhone[key] = DeviceContact(
            displayName: name,
            normalizedPhone: key,
            phoneLabel: phone.label.toString(),
          );
        }
      }
    }

    final list = byPhone.values.toList()
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ));
    return list;
  }
}
