import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/contact_photo_service.dart';
import '../services/auth_service.dart';
import '../services/onboarding_prefs.dart';
import '../utils/pin_util.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._auth);

  final AuthService _auth;

  AppUser? get user => _auth.currentUser;
  bool get isLoggedIn => user != null;

  Future<void> init() => _auth.loadSession().then((_) => notifyListeners());

  Future<void> refreshUser() async {
    await _auth.refreshCurrentUser();
    notifyListeners();
  }

  Future<void> setOnboardingComplete() => OnboardingPrefs.setCompleted();

  Future<bool> phoneExists(String phone) async {
    final u = await _auth.findByPhone(phone);
    return u != null;
  }

  Future<int> pinLengthForPhone(String phone) async {
    final u = await _auth.findByPhone(phone);
    return u?.pinLength ?? 4;
  }

  /// Yangi foydalanuvchi: SMS kod yuborish.
  Future<({String? error, String? devCode})> sendSmsOtp(String phone) async {
    if (!isValidPhone(phone)) {
      return (error: 'Telefon: +998 XX XXX XX XX formatida kiriting', devCode: null);
    }
    if (await phoneExists(phone)) {
      return (
        error: 'Bu raqam allaqachon biriktirilgan. Parol bilan kiring',
        devCode: null,
      );
    }
    return _auth.sendRegistrationOtp(phone);
  }

  Future<String?> verifySmsOtp(String phone, String code) async {
    return _auth.verifyRegistrationOtp(phone, code);
  }

  int? smsResendSecondsLeft(String phone) =>
      _auth.smsOtp.resendSecondsLeft(phone);

  Future<String?> register({
    required String phone,
    required String name,
    required String pin,
    required int pinLength,
  }) async {
    if (!isValidPhone(phone)) {
      return 'Telefon: +998 XX XXX XX XX formatida kiriting';
    }
    if (!_auth.smsOtp.isPhoneVerifiedForRegister(phone)) {
      return 'Avval SMS kodni tasdiqlang';
    }
    if (!isValidPin(pin, pinLength)) {
      return 'Parol $pinLength raqamdan iborat bo\'lishi kerak';
    }
    try {
      await _auth.register(
        phone: phone,
        name: name,
        pin: pin,
        pinLength: pinLength,
      );
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Parolni unutgan: SMS kod yuborish (faqat ro'yxatdan o'tgan raqam).
  Future<({String? error, String? devCode})> sendPasswordResetOtp(
    String phone,
  ) async {
    if (!isValidPhone(phone)) {
      return (error: 'Telefon: +998 XX XXX XX XX formatida kiriting', devCode: null);
    }
    return _auth.sendPasswordResetOtp(phone);
  }

  Future<String?> verifyPasswordResetOtp(String phone, String code) async {
    return _auth.verifyPasswordResetOtp(phone, code);
  }

  Future<String?> resetPassword({
    required String phone,
    required String pin,
    required int pinLength,
  }) async {
    if (!isValidPhone(phone)) {
      return 'Telefon raqamni to\'g\'ri kiriting';
    }
    if (!_auth.smsOtp.isPhoneVerifiedForPasswordReset(phone)) {
      return 'Avval SMS kodni tasdiqlang';
    }
    if (!isValidPin(pin, pinLength)) {
      return 'Parol $pinLength raqamdan iborat bo\'lishi kerak';
    }
    try {
      await _auth.resetPassword(
        phone: phone,
        pin: pin,
        pinLength: pinLength,
      );
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> login(String phone, String pin) async {
    if (!isValidPhone(phone)) {
      return 'Telefon raqamni to\'g\'ri kiriting';
    }
    try {
      await _auth.login(phone, pin);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    notifyListeners();
  }

  Future<String?> changePin({
    required String currentPin,
    required String newPin,
    required int newPinLength,
  }) async {
    final err = await _auth.changePin(
      currentPin: currentPin,
      newPin: newPin,
      newPinLength: newPinLength,
    );
    if (err == null) notifyListeners();
    return err;
  }

  Future<String?> updateName(String newName) async {
    final err = await _auth.updateProfileName(newName);
    if (err == null) notifyListeners();
    return err;
  }

  Future<String?> setAvatarFromFile(File file) async {
    final err = await _auth.setLocalAvatar(file);
    if (err == null) notifyListeners();
    return err;
  }

  Future<String?> removeAvatar() async {
    final err = await _auth.removeLocalAvatar();
    if (err == null) notifyListeners();
    return err;
  }

  Future<String?> addExtraPhone(String phone) async {
    final err = await _auth.addExtraPhone(phone);
    if (err == null) {
      ContactPhotoService.instance.clearCache();
      notifyListeners();
    }
    return err;
  }

  Future<String?> removeExtraPhone(String phone) async {
    final err = await _auth.removeExtraPhone(phone);
    if (err == null) notifyListeners();
    return err;
  }
}
