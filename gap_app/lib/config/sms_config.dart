/// SMS provayder sozlamalari.
///
/// Haqiqiy SMS uchun build vaqtida:
/// flutter build apk --dart-define=SMS_ESKIZ_EMAIL=... --dart-define=SMS_ESKIZ_PASSWORD=...
class SmsConfig {
  SmsConfig._();

  /// Sinov / demo — har doim shu kod (haqiqiy SMS yoqilmaguncha).
  static const demoOtpCode = '123456';

  static const eskizEmail = String.fromEnvironment('SMS_ESKIZ_EMAIL');
  static const eskizPassword = String.fromEnvironment('SMS_ESKIZ_PASSWORD');

  static bool get usesRealSms =>
      eskizEmail.isNotEmpty && eskizPassword.isNotEmpty;
}
