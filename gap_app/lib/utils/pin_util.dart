import 'dart:convert';

import 'package:crypto/crypto.dart';

String hashPin(String pin) {
  return sha256.convert(utf8.encode(pin)).toString();
}

bool isValidPin(String pin, int length) {
  if (pin.length != length) return false;
  return RegExp(r'^\d+$').hasMatch(pin);
}

String normalizePhone(String phone) {
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('998')) {
    digits = digits.substring(3);
  }
  if (digits.length == 9) {
    return '998$digits';
  }
  return digits;
}

bool isValidPhone(String phone) {
  final normalized = normalizePhone(phone);
  return RegExp(r'^998\d{9}$').hasMatch(normalized);
}

String formatPhoneDisplay(String phone) {
  if (phone.length == 12 && phone.startsWith('998')) {
    return '+${phone.substring(0, 3)} ${phone.substring(3, 5)} ${phone.substring(5, 8)} ${phone.substring(8, 10)} ${phone.substring(10)}';
  }
  return phone;
}
