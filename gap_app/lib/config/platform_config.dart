import 'dart:io';

/// Platform admin API (GAP va kelajakdagi ilovalar).
class PlatformConfig {
  PlatformConfig._();

  static const appId = 'gap';

  /// `flutter run --dart-define=PLATFORM_API_URL=http://192.168.1.5:3847`
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('PLATFORM_API_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (Platform.isAndroid) {
      // Emulyator: 10.0.2.2 — host kompyuter.
      return 'http://10.0.2.2:3847';
    }
    return 'http://localhost:3847';
  }

  static bool get isEnabled => apiBaseUrl.isNotEmpty;
}
