import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config/sms_config.dart';
import 'eskiz_sms_gateway.dart';
import 'local_db_service.dart';
import '../utils/pin_util.dart';

/// SMS OTP — Eskiz ulangan bo'lsa haqiqiy SMS, aks holda kod ekranda ko'rsatiladi.
class SmsOtpService {
  SmsOtpService(this._db);

  final LocalDbService _db;
  final EskizSmsGateway _eskiz = EskizSmsGateway();

  static const _otpPrefix = 'otp_';
  static const _verifiedPrefix = 'verified_';
  static const _resetVerifiedPrefix = 'verified_reset_';
  static const _otpTtlSeconds = 300;
  static const _verifiedTtlSeconds = 1800;
  static const _resendCooldownSeconds = 60;

  String _otpKey(String phone) => '$_otpPrefix${normalizePhone(phone)}';
  String _verifiedKey(String phone) => '$_verifiedPrefix${normalizePhone(phone)}';

  String _resetVerifiedKey(String phone) =>
      '$_resetVerifiedPrefix${normalizePhone(phone)}';

  /// [devCode] — haqiqiy SMS yuborilmasa, kodni ekranda ko'rsatish uchun.
  Future<({String? error, String? devCode})> sendOtp(String phone) async {
    final normalized = normalizePhone(phone);
    if (!isValidPhone(phone)) {
      return (error: 'Telefon: +998 XX XXX XX XX', devCode: null);
    }

    final key = _otpKey(normalized);
    final existing = _db.sessionGet(key);
    if (existing is Map) {
      final sentAt = DateTime.tryParse(existing['sentAt'] as String? ?? '');
      if (sentAt != null) {
        final elapsed = DateTime.now().difference(sentAt).inSeconds;
        if (elapsed < _resendCooldownSeconds) {
          final wait = _resendCooldownSeconds - elapsed;
          return (
            error: 'Qayta yuborish uchun $wait soniya kuting',
            devCode: null,
          );
        }
      }
    }

    final code = SmsConfig.usesRealSms
        ? '${Random().nextInt(900000) + 100000}'
        : SmsConfig.demoOtpCode;
    await _db.sessionPut(key, {
      'code': code,
      'sentAt': DateTime.now().toIso8601String(),
    });

    if (SmsConfig.usesRealSms) {
      final sent = await _eskiz.sendOtp(normalized, code);
      if (!sent) {
        return (
          error: 'SMS yuborilmadi. Internet yoki SMS sozlamasini tekshiring',
          devCode: null,
        );
      }
      return (error: null, devCode: null);
    }

    if (kDebugMode) {
      debugPrint('GAP SMS OTP $normalized: $code');
    }
    return (error: null, devCode: code);
  }

  Future<String?> verifyOtp(String phone, String code) async {
    return _verifyOtpInternal(phone, code, verifiedKey: _verifiedKey);
  }

  Future<String?> verifyOtpForPasswordReset(String phone, String code) async {
    return _verifyOtpInternal(phone, code, verifiedKey: _resetVerifiedKey);
  }

  Future<String?> _verifyOtpInternal(
    String phone,
    String code, {
    required String Function(String) verifiedKey,
  }) async {
    final normalized = normalizePhone(phone);
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      return '6 raqamli kod kiriting';
    }

    final raw = _db.sessionGet(_otpKey(normalized));
    if (raw is! Map) {
      return 'Avval SMS kod so\'rang';
    }

    final sentAt = DateTime.tryParse(raw['sentAt'] as String? ?? '');
    if (sentAt == null ||
        DateTime.now().difference(sentAt).inSeconds > _otpTtlSeconds) {
      return 'Kod muddati tugagan. Qayta yuboring';
    }

    if (raw['code'] != code) {
      return 'Noto\'g\'ri kod';
    }

    await _db.sessionPut(verifiedKey(normalized), {
      'at': DateTime.now().toIso8601String(),
    });
    await _db.sessionDelete(_otpKey(normalized));
    return null;
  }

  bool isPhoneVerifiedForRegister(String phone) {
    final raw = _db.sessionGet(_verifiedKey(normalizePhone(phone)));
    if (raw is! Map) return false;
    final at = DateTime.tryParse(raw['at'] as String? ?? '');
    if (at == null) return false;
    return DateTime.now().difference(at).inSeconds < _verifiedTtlSeconds;
  }

  bool isPhoneVerifiedForPasswordReset(String phone) {
    final raw = _db.sessionGet(_resetVerifiedKey(normalizePhone(phone)));
    if (raw is! Map) return false;
    final at = DateTime.tryParse(raw['at'] as String? ?? '');
    if (at == null) return false;
    return DateTime.now().difference(at).inSeconds < _verifiedTtlSeconds;
  }

  void clearPhoneVerification(String phone) {
    _db.sessionDelete(_verifiedKey(normalizePhone(phone)));
  }

  void clearPasswordResetVerification(String phone) {
    _db.sessionDelete(_resetVerifiedKey(normalizePhone(phone)));
  }

  int? resendSecondsLeft(String phone) {
    final raw = _db.sessionGet(_otpKey(normalizePhone(phone)));
    if (raw is! Map) return null;
    final sentAt = DateTime.tryParse(raw['sentAt'] as String? ?? '');
    if (sentAt == null) return null;
    final elapsed = DateTime.now().difference(sentAt).inSeconds;
    if (elapsed >= _resendCooldownSeconds) return 0;
    return _resendCooldownSeconds - elapsed;
  }
}
