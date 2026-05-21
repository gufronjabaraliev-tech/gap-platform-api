import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPrefs {
  static const _key = 'gap_onboarding_completed';

  static Future<bool> isCompleted() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_key) ?? false;
  }

  static Future<void> setCompleted() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, true);
  }
}
