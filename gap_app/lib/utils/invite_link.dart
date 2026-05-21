/// Taklif kodi va QR uchun umumiy format.
class InviteLink {
  InviteLink._();

  static const schemePrefix = 'gap://join/';
  static const webPath = '/join/';

  /// QR va havola uchun to'liq matn.
  static String payload(String inviteCode) =>
      '$schemePrefix${normalizeCode(inviteCode)}';

  static String normalizeCode(String raw) =>
      raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  /// Skaner yoki matndan kodni ajratib oladi.
  static String? parseCode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final upper = trimmed.toUpperCase();
    final scheme = schemePrefix.toUpperCase();
    if (upper.startsWith(scheme)) {
      final code = normalizeCode(upper.substring(scheme.length));
      return _valid(code);
    }

    final joinIdx = upper.indexOf('/JOIN/');
    if (joinIdx >= 0) {
      final code = normalizeCode(upper.substring(joinIdx + 6));
      return _valid(code);
    }

    final plain = normalizeCode(upper);
    return _valid(plain);
  }

  static String? _valid(String code) {
    if (code.length >= 4 && code.length <= 12) return code;
    return null;
  }

  static String shareText({
    required String groupName,
    required String inviteCode,
  }) {
    final code = normalizeCode(inviteCode);
    return 'GAP — "$groupName" jamg\'armasiga qo\'shiling\n'
        'Taklif kodi: $code\n'
        '${payload(code)}';
  }
}
