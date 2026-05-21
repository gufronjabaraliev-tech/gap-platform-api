import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/sms_config.dart';

/// Eskiz.uz orqali SMS (O'zbekiston).
class EskizSmsGateway {
  static const _base = 'https://notify.eskiz.uz/api';

  String? _token;
  DateTime? _tokenAt;

  Future<bool> sendOtp(String phone, String code) async {
    if (!SmsConfig.usesRealSms) return false;

    try {
      final token = await _tokenOrLogin();
      if (token == null) return false;

      final digits = phone.replaceAll(RegExp(r'\D'), '');
      final normalized = digits.startsWith('998') ? '+$digits' : '+998$digits';
      final body = jsonEncode({
        'mobile_phone': normalized,
        'message': 'GAP tasdiqlash kodi: $code. Kodni hech kimga bermang.',
        'from': '4546',
      });

      final res = await http.post(
        Uri.parse('$_base/message/sms/send'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _tokenOrLogin() async {
    if (_token != null &&
        _tokenAt != null &&
        DateTime.now().difference(_tokenAt!).inHours < 20) {
      return _token;
    }

    try {
      final res = await http.post(
        Uri.parse('$_base/auth/login'),
        body: {
          'email': SmsConfig.eskizEmail,
          'password': SmsConfig.eskizPassword,
        },
      );
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final token = data['data']?['token'] as String?;
      if (token == null || token.isEmpty) return null;
      _token = token;
      _tokenAt = DateTime.now();
      return token;
    } catch (_) {
      return null;
    }
  }
}
