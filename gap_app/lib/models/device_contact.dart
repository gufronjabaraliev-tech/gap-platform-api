/// Telefon kontaktidan olingan ma'lumot.
class DeviceContact {
  const DeviceContact({
    required this.displayName,
    required this.normalizedPhone,
    this.phoneLabel,
  });

  final String displayName;
  /// 998XXXXXXXXX
  final String normalizedPhone;
  final String? phoneLabel;

  String get id => normalizedPhone;
}
