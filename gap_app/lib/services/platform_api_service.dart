import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/platform_config.dart';

class PlatformApiService {
  PlatformApiService._();
  static final PlatformApiService instance = PlatformApiService._();

  Uri _uri(String path) => Uri.parse('${PlatformConfig.apiBaseUrl}$path');

  Future<Map<String, dynamic>?> fetchAppConfig() async {
    if (!PlatformConfig.isEnabled) return null;
    try {
      final res = await http
          .get(_uri('/api/public/apps/${PlatformConfig.appId}/config'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> trackEvent(
    String event, {
    Map<String, dynamic>? metadata,
    String? deviceId,
    String? userId,
  }) async {
    if (!PlatformConfig.isEnabled) return;
    try {
      await http
          .post(
            _uri('/api/public/apps/${PlatformConfig.appId}/events'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'event': event,
              'metadata': metadata ?? {},
              'deviceId': deviceId,
              'userId': userId,
            }),
          )
          .timeout(const Duration(seconds: 6));
    } catch (_) {}
  }

  Future<bool> submitSupport({
    required String subject,
    required String message,
    String? name,
    String? phone,
    String? email,
    String? userId,
  }) async {
    if (!PlatformConfig.isEnabled) return false;
    try {
      final res = await http
          .post(
            _uri('/api/public/apps/${PlatformConfig.appId}/support'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'subject': subject,
              'message': message,
              'name': name,
              'phone': phone,
              'email': email,
              'userId': userId,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
