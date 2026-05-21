import 'dart:io';

import 'package:uuid/uuid.dart';

import '../models/app_user.dart';
import '../utils/pin_util.dart';
import 'local_avatar_storage.dart';
import 'local_db_service.dart';
import 'member_link_service.dart';
import 'sms_otp_service.dart';

class AuthService {
  AuthService(this._db, this._memberLink, this._smsOtp);

  final LocalDbService _db;
  final MemberLinkService _memberLink;
  final SmsOtpService _smsOtp;
  final _uuid = const Uuid();

  AppUser? get currentUser => _currentUser;
  AppUser? _currentUser;

  Future<void> loadSession() async {
    final id = _db.currentUserId;
    if (id != null) {
      _currentUser = await _db.getUserById(id);
    }
  }

  Future<void> refreshCurrentUser() async {
    final id = _db.currentUserId;
    if (id != null) {
      _currentUser = await _db.getUserById(id);
    }
  }

  /// Asosiy yoki qo'shimcha biriktirilgan raqam bo'yicha foydalanuvchi.
  Future<AppUser?> findByPhone(String phone) {
    return _db.findUserByAnyPhone(normalizePhone(phone));
  }

  Future<List<AppUser>> listRegisteredUsers() => _db.getAllUsers();

  SmsOtpService get smsOtp => _smsOtp;

  Future<({String? error, String? devCode})> sendRegistrationOtp(String phone) =>
      _smsOtp.sendOtp(phone);

  Future<String?> verifyRegistrationOtp(String phone, String code) =>
      _smsOtp.verifyOtp(phone, code);

  Future<AppUser> register({
    required String phone,
    required String name,
    required String pin,
    required int pinLength,
  }) async {
    final normalized = normalizePhone(phone);
    if (!_smsOtp.isPhoneVerifiedForRegister(phone)) {
      throw Exception('Avval telefon raqamni SMS orqali tasdiqlang');
    }
    final existing = await _db.findUserByAnyPhone(normalized);
    if (existing != null) {
      throw Exception(
        'Bu raqam allaqachon biriktirilgan. Parol bilan kiring',
      );
    }

    final user = AppUser(
      id: _uuid.v4(),
      phone: normalized,
      name: name.trim(),
      pinHash: hashPin(pin),
      pinLength: pinLength,
    );
    await _db.saveUser(user);
    await _linkAllPhones(user);
    await _db.setCurrentUserId(user.id);
    _currentUser = user;
    _smsOtp.clearPhoneVerification(phone);
    return user;
  }

  Future<({String? error, String? devCode})> sendPasswordResetOtp(
    String phone,
  ) async {
    final normalized = normalizePhone(phone);
    if (!isValidPhone(phone)) {
      return (error: 'Telefon: +998 XX XXX XX XX', devCode: null);
    }
    final user = await _db.findUserByAnyPhone(normalized);
    if (user == null) {
      return (
        error: 'Bu raqam ro\'yxatdan o\'tmagan. Avval ro\'yxatdan o\'ting',
        devCode: null,
      );
    }
    return _smsOtp.sendOtp(phone);
  }

  Future<String?> verifyPasswordResetOtp(String phone, String code) =>
      _smsOtp.verifyOtpForPasswordReset(phone, code);

  Future<AppUser> resetPassword({
    required String phone,
    required String pin,
    required int pinLength,
  }) async {
    final normalized = normalizePhone(phone);
    if (!_smsOtp.isPhoneVerifiedForPasswordReset(phone)) {
      throw Exception('Avval telefon raqamni SMS orqali tasdiqlang');
    }
    final user = await _db.findUserByAnyPhone(normalized);
    if (user == null) {
      throw Exception('Foydalanuvchi topilmadi');
    }
    if (!isValidPin(pin, pinLength)) {
      throw Exception('Parol $pinLength raqamdan iborat bo\'lishi kerak');
    }

    final updated = user.copyWith(
      pinHash: hashPin(pin),
      pinLength: pinLength,
    );
    await _db.saveUser(updated);
    await _linkAllPhones(updated);
    await _db.setCurrentUserId(updated.id);
    _currentUser = updated;
    _smsOtp.clearPasswordResetVerification(phone);
    return updated;
  }

  Future<AppUser> login(String phone, String pin) async {
    final normalized = normalizePhone(phone);
    final user = await _db.findUserByAnyPhone(normalized);
    if (user == null) {
      throw Exception('Foydalanuvchi topilmadi. Avval ro\'yxatdan o\'ting');
    }
    if (pin.length != user.pinLength) {
      throw Exception('Parol ${user.pinLength} raqamdan iborat bo\'lishi kerak');
    }
    if (hashPin(pin) != user.pinHash) {
      throw Exception('Noto\'g\'ri parol');
    }
    await _linkAllPhones(user);
    await _db.setCurrentUserId(user.id);
    _currentUser = user;
    return user;
  }

  Future<void> _linkAllPhones(AppUser user) async {
    for (final p in user.allPhones) {
      await _memberLink.linkPhoneToUser(
        phone: p,
        userId: user.id,
        userName: user.name,
      );
    }
  }

  Future<String?> changePin({
    required String currentPin,
    required String newPin,
    required int newPinLength,
  }) async {
    final user = _currentUser;
    if (user == null) return 'Foydalanuvchi topilmadi';

    if (currentPin.length != user.pinLength) {
      return 'Joriy parol ${user.pinLength} raqamdan iborat bo\'lishi kerak';
    }
    if (hashPin(currentPin) != user.pinHash) {
      return 'Joriy parol noto\'g\'ri';
    }
    if (!isValidPin(newPin, newPinLength)) {
      return 'Yangi parol $newPinLength raqamdan iborat bo\'lishi kerak';
    }
    if (currentPin == newPin && newPinLength == user.pinLength) {
      return 'Yangi parol eskisidan farq qilishi kerak';
    }

    final updated = user.copyWith(
      pinHash: hashPin(newPin),
      pinLength: newPinLength,
    );
    await _db.saveUser(updated);
    _currentUser = updated;
    return null;
  }

  Future<String?> updateProfileName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.length < 2) return 'Ism kamida 2 harf bo\'lishi kerak';
    final user = _currentUser;
    if (user == null) return 'Foydalanuvchi topilmadi';

    final updated = user.copyWith(name: trimmed);
    await _db.saveUser(updated);
    await _memberLink.syncDisplayNameFromProfile(user.id, trimmed);
    _currentUser = updated;
    return null;
  }

  Future<String?> setLocalAvatar(File imageFile) async {
    final user = _currentUser;
    if (user == null) return 'Foydalanuvchi topilmadi';

    final fileName = await LocalAvatarStorage.instance.saveForUser(
      user.id,
      imageFile,
    );
    if (fileName == null) {
      return 'Rasm saqlanmadi (faqat mobil qurilmada)';
    }

    final updated = user.copyWith(localAvatarFileName: fileName);
    await _db.saveUser(updated);
    _currentUser = updated;
    return null;
  }

  Future<String?> removeLocalAvatar() async {
    final user = _currentUser;
    if (user == null) return 'Foydalanuvchi topilmadi';

    await LocalAvatarStorage.instance.deleteForUser(
      user.id,
      user.localAvatarFileName,
    );
    final updated = user.copyWith(clearAvatar: true);
    await _db.saveUser(updated);
    _currentUser = updated;
    return null;
  }

  Future<String?> addExtraPhone(String phone) async {
    final user = _currentUser;
    if (user == null) return 'Foydalanuvchi topilmadi';

    if (!isValidPhone(phone)) {
      return 'Telefon: +998 XX XXX XX XX formatida kiriting';
    }
    final normalized = normalizePhone(phone);
    if (user.allPhones.contains(normalized)) {
      return 'Bu raqam allaqachon biriktirilgan';
    }

    final taken = await _db.findUserByAnyPhone(normalized);
    if (taken != null && taken.id != user.id) {
      return 'Bu raqam boshqa hisobda ishlatilmoqda';
    }

    final updated = user.copyWith(
      extraPhones: [...user.extraPhones, normalized],
    );
    await _db.saveUser(updated);
    await _memberLink.linkPhoneToUser(
      phone: normalized,
      userId: user.id,
      userName: user.name,
    );
    _currentUser = updated;
    return null;
  }

  Future<String?> removeExtraPhone(String phone) async {
    final user = _currentUser;
    if (user == null) return 'Foydalanuvchi topilmadi';

    final normalized = normalizePhone(phone);
    if (normalized == user.phone) {
      return 'Asosiy raqamni o\'chirib bo\'lmaydi';
    }

    final updated = user.copyWith(
      extraPhones:
          user.extraPhones.where((p) => p != normalized).toList(),
    );
    await _db.saveUser(updated);
    _currentUser = updated;
    return null;
  }

  Future<void> logout() async {
    await _db.setCurrentUserId(null);
    _currentUser = null;
  }
}
