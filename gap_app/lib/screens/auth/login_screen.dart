import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/sms_config.dart';
import '../../providers/auth_provider.dart';
import '../../utils/pin_util.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_primary_button.dart';
import '../../widgets/theme_toggle_button.dart';
import '../main_shell_screen.dart';

enum _AuthStep { phone, smsOtp, register, login, resetOtp, resetPin }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _pinConfirmCtrl = TextEditingController();

  _AuthStep _step = _AuthStep.phone;
  int _pinLength = 4;
  bool _loading = false;
  int _resendSec = 0;
  Timer? _resendTimer;
  /// Haqiqiy SMS ulanmaganda ekranda ko'rsatiladigan kod.
  String? _otpDisplayCode;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    _pinConfirmCtrl.dispose();
    super.dispose();
  }

  String get _normalizedPhone => normalizePhone(_phoneCtrl.text.trim());

  void _startResendTimer() {
    _resendTimer?.cancel();
    final auth = context.read<AuthProvider>();
    _resendSec = auth.smsResendSecondsLeft(_phoneCtrl.text.trim()) ?? 60;
    if (_resendSec <= 0) {
      setState(() => _resendSec = 0);
      return;
    }
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = auth.smsResendSecondsLeft(_phoneCtrl.text.trim()) ?? 0;
      setState(() => _resendSec = left);
      if (left <= 0) _resendTimer?.cancel();
    });
  }

  Future<void> _continuePhone() async {
    if (!isValidPhone(_phoneCtrl.text.trim())) {
      showGapSnackBar(context, 'Telefon: +998 XX XXX XX XX', isError: true);
      return;
    }

    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final exists = await auth.phoneExists(_phoneCtrl.text.trim());
    if (!mounted) return;

    if (exists) {
      final len = await auth.pinLengthForPhone(_phoneCtrl.text.trim());
      setState(() {
        _loading = false;
        _pinLength = len;
        _step = _AuthStep.login;
        _pinCtrl.clear();
      });
      return;
    }

    final result = await auth.sendSmsOtp(_phoneCtrl.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.error != null) {
      showGapSnackBar(context, result.error!, isError: true);
      return;
    }

    setState(() {
      _step = _AuthStep.smsOtp;
      _otpCtrl.clear();
      _otpDisplayCode = result.devCode;
    });
    _startResendTimer();
  }

  Future<void> _verifyOtp() async {
    setState(() => _loading = true);
    final err = await context.read<AuthProvider>().verifySmsOtp(
          _phoneCtrl.text.trim(),
          _otpCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      showGapSnackBar(context, err, isError: true);
      return;
    }

    showGapSnackBar(context, 'Raqam tasdiqlandi');
    setState(() => _step = _AuthStep.register);
  }

  Future<void> _resendOtp() async {
    if (_resendSec > 0) return;
    setState(() => _loading = true);
    final result =
        await context.read<AuthProvider>().sendSmsOtp(_phoneCtrl.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.error != null) {
      showGapSnackBar(context, result.error!, isError: true);
      return;
    }
    setState(() => _otpDisplayCode = result.devCode);
    _startResendTimer();
  }

  Future<void> _register() async {
    if (_nameCtrl.text.trim().length < 2) {
      showGapSnackBar(context, 'Ism kiriting', isError: true);
      return;
    }
    if (!isValidPin(_pinCtrl.text, _pinLength)) {
      showGapSnackBar(
        context,
        'Parol $_pinLength raqamdan iborat bo\'lishi kerak',
        isError: true,
      );
      return;
    }
    if (_pinCtrl.text != _pinConfirmCtrl.text) {
      showGapSnackBar(context, 'Parollar mos kelmaydi', isError: true);
      return;
    }

    setState(() => _loading = true);
    final err = await context.read<AuthProvider>().register(
          phone: _phoneCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
          pin: _pinCtrl.text,
          pinLength: _pinLength,
        );
    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      showGapSnackBar(context, err, isError: true);
      return;
    }
    _goHome();
  }

  Future<void> _startPasswordReset() async {
    setState(() => _loading = true);
    final result = await context.read<AuthProvider>().sendPasswordResetOtp(
          _phoneCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.error != null) {
      showGapSnackBar(context, result.error!, isError: true);
      return;
    }

    setState(() {
      _step = _AuthStep.resetOtp;
      _otpCtrl.clear();
      _otpDisplayCode = result.devCode;
    });
    _startResendTimer();
  }

  Future<void> _verifyResetOtp() async {
    setState(() => _loading = true);
    final err = await context.read<AuthProvider>().verifyPasswordResetOtp(
          _phoneCtrl.text.trim(),
          _otpCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      showGapSnackBar(context, err, isError: true);
      return;
    }

    final len = await context.read<AuthProvider>().pinLengthForPhone(
          _phoneCtrl.text.trim(),
        );
    if (!mounted) return;

    showGapSnackBar(context, 'Raqam tasdiqlandi. Yangi parol yarating');
    setState(() {
      _pinLength = len;
      _step = _AuthStep.resetPin;
      _pinCtrl.clear();
      _pinConfirmCtrl.clear();
    });
  }

  Future<void> _resendResetOtp() async {
    if (_resendSec > 0) return;
    setState(() => _loading = true);
    final result = await context.read<AuthProvider>().sendPasswordResetOtp(
          _phoneCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.error != null) {
      showGapSnackBar(context, result.error!, isError: true);
      return;
    }
    setState(() => _otpDisplayCode = result.devCode);
    _startResendTimer();
  }

  Future<void> _submitNewPassword() async {
    if (!isValidPin(_pinCtrl.text, _pinLength)) {
      showGapSnackBar(
        context,
        'Parol $_pinLength raqamdan iborat bo\'lishi kerak',
        isError: true,
      );
      return;
    }
    if (_pinCtrl.text != _pinConfirmCtrl.text) {
      showGapSnackBar(context, 'Parollar mos kelmaydi', isError: true);
      return;
    }

    setState(() => _loading = true);
    final err = await context.read<AuthProvider>().resetPassword(
          phone: _phoneCtrl.text.trim(),
          pin: _pinCtrl.text,
          pinLength: _pinLength,
        );
    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      showGapSnackBar(context, err, isError: true);
      return;
    }

    showGapSnackBar(context, 'Yangi parol o\'rnatildi');
    _goHome();
  }

  void _backToLogin() {
    _resendTimer?.cancel();
    setState(() {
      _step = _AuthStep.login;
      _resendSec = 0;
      _otpCtrl.clear();
      _pinCtrl.clear();
      _pinConfirmCtrl.clear();
    });
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    final err = await context.read<AuthProvider>().login(
          _phoneCtrl.text.trim(),
          _pinCtrl.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      showGapSnackBar(context, err, isError: true);
      return;
    }
    _goHome();
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainShellScreen(key: MainShellScreen.globalKey),
      ),
    );
  }

  void _backToPhone() {
    _resendTimer?.cancel();
    setState(() {
      _step = _AuthStep.phone;
      _resendSec = 0;
      _otpCtrl.clear();
      _pinCtrl.clear();
      _otpDisplayCode = null;
    });
  }

  String get _subtitle => switch (_step) {
        _AuthStep.phone => 'Telefon raqamingizni kiriting',
        _AuthStep.smsOtp =>
          'Demo kod: ${SmsConfig.demoOtpCode} (ekranda ham ko\'rinadi)',
        _AuthStep.register => 'Profil va parolni yarating',
        _AuthStep.login => 'Parolingizni kiriting',
        _AuthStep.resetOtp =>
          'SMS orqali yangi kirish huquqini olish uchun kodni kiriting',
        _AuthStep.resetPin => 'Yangi $_pinLength raqamli parol yarating',
      };

  String get _welcomeTitle => switch (_step) {
        _AuthStep.phone => 'Xush kelibsiz',
        _AuthStep.smsOtp => 'Raqamni tasdiqlash',
        _AuthStep.register => 'Ro\'yxatdan o\'tish',
        _AuthStep.login => 'Kirish',
        _AuthStep.resetOtp => 'Parolni tiklash',
        _AuthStep.resetPin => 'Yangi parol',
      };

  InputDecoration _fieldDecoration(String label, {Widget? prefix}) {
    return glassFieldDecoration(context, label: label, prefix: prefix);
  }

  static const _fieldTextStyle = TextStyle(color: Color(0xFFE8F5F0), fontSize: 15);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoginBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: ThemeToggleButton(
                  iconColor: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'GAP',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Georgia',
                              letterSpacing: 3,
                              fontSize: 28,
                              color: Colors.white.withValues(alpha: 0.98),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _welcomeTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 28),
                          if (_step == _AuthStep.phone) ..._phoneStep(),
                          if (_step == _AuthStep.smsOtp) ..._otpStep(),
                          if (_step == _AuthStep.register) ..._registerStep(),
                          if (_step == _AuthStep.login) ..._loginStep(),
                          if (_step == _AuthStep.resetOtp) ..._resetOtpStep(),
                          if (_step == _AuthStep.resetPin) ..._resetPinStep(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _phoneStep() => [
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          style: _fieldTextStyle,
          cursorColor: const Color(0xFF2DD4BF),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _fieldDecoration(
            'Telefon raqam',
            prefix: Icon(Icons.phone_rounded,
                color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '+998 formatida, masalan: 901234567',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 20),
        GlassPrimaryButton(
          label: 'Davom etish',
          loading: _loading,
          onPressed: _loading ? null : _continuePhone,
        ),
      ];

  Widget _otpCodeBanner() {
    if (_otpDisplayCode == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          'SMS telefoningizga yuborildi. 6 raqamli kodni kiriting.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 13,
            height: 1.35,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          Text(
            'Tasdiqlash kodi',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _otpDisplayCode!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Demo rejim — har doim ${SmsConfig.demoOtpCode}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _otpStep() => [
        _phoneBadge(),
        _otpCodeBanner(),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: _fieldTextStyle,
          cursorColor: const Color(0xFF2DD4BF),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _fieldDecoration(
            'SMS kod',
            prefix: Icon(Icons.sms_rounded,
                color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
        const SizedBox(height: 12),
        GlassPrimaryButton(
          label: 'Tasdiqlash',
          loading: _loading,
          onPressed: _loading ? null : _verifyOtp,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: (_loading || _resendSec > 0) ? null : _resendOtp,
          child: Text(
            _resendSec > 0
                ? 'Qayta yuborish ($_resendSec s)'
                : 'Kodni qayta yuborish',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
          ),
        ),
        TextButton(
          onPressed: _loading ? null : _backToPhone,
          child: Text(
            'Orqaga',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
      ];

  List<Widget> _registerStep() => [
        _phoneBadge(),
        TextField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          style: _fieldTextStyle,
          cursorColor: const Color(0xFF2DD4BF),
          decoration: _fieldDecoration(
            'Ism familiya',
            prefix: Icon(Icons.person_rounded,
                color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Parol uzunligi',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 4, label: Text('4 raqam')),
            ButtonSegment(value: 6, label: Text('6 raqam')),
          ],
          selected: {_pinLength},
          onSelectionChanged: (s) => setState(() => _pinLength = s.first),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pinCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: _pinLength,
          style: _fieldTextStyle,
          cursorColor: const Color(0xFF2DD4BF),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _fieldDecoration(
            '$_pinLength raqamli parol',
            prefix: Icon(Icons.lock_rounded,
                color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
        TextField(
          controller: _pinConfirmCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: _pinLength,
          style: _fieldTextStyle,
          cursorColor: const Color(0xFF2DD4BF),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _fieldDecoration(
            'Parolni tasdiqlang',
            prefix: Icon(Icons.lock_outline_rounded,
                color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
        const SizedBox(height: 20),
        GlassPrimaryButton(
          label: 'Ro\'yxatdan o\'tish',
          loading: _loading,
          onPressed: _loading ? null : _register,
        ),
        TextButton(
          onPressed: _loading ? null : _backToPhone,
          child: Text(
            'Orqaga',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
      ];

  List<Widget> _loginStep() => [
        _phoneBadge(),
        TextField(
          controller: _pinCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: _pinLength,
          style: _fieldTextStyle,
          cursorColor: const Color(0xFF2DD4BF),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _fieldDecoration(
            '$_pinLength raqamli parol',
            prefix: Icon(Icons.lock_rounded,
                color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
        const SizedBox(height: 20),
        GlassPrimaryButton(
          label: 'Kirish',
          loading: _loading,
          onPressed: _loading ? null : _login,
        ),
        TextButton(
          onPressed: _loading ? null : _startPasswordReset,
          child: Text(
            'Parolni unutdingizmi?',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
          ),
        ),
        TextButton(
          onPressed: _loading ? null : _backToPhone,
          child: Text(
            'Boshqa raqam',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
      ];

  List<Widget> _resetOtpStep() => [
        _phoneBadge(),
        _otpCodeBanner(),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: _fieldTextStyle,
          cursorColor: const Color(0xFF2DD4BF),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _fieldDecoration(
            'SMS kod',
            prefix: Icon(Icons.sms_rounded,
                color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
        const SizedBox(height: 12),
        GlassPrimaryButton(
          label: 'Tasdiqlash',
          loading: _loading,
          onPressed: _loading ? null : _verifyResetOtp,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: (_loading || _resendSec > 0) ? null : _resendResetOtp,
          child: Text(
            _resendSec > 0
                ? 'Qayta yuborish ($_resendSec s)'
                : 'Kodni qayta yuborish',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
          ),
        ),
        TextButton(
          onPressed: _loading ? null : _backToLogin,
          child: Text(
            'Parol bilan kirish',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
      ];

  List<Widget> _resetPinStep() => [
        _phoneBadge(),
        TextField(
          controller: _pinCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: _pinLength,
          style: _fieldTextStyle,
          cursorColor: const Color(0xFF2DD4BF),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _fieldDecoration(
            'Yangi parol ($_pinLength raqam)',
            prefix: Icon(Icons.lock_rounded,
                color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
        TextField(
          controller: _pinConfirmCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: _pinLength,
          style: _fieldTextStyle,
          cursorColor: const Color(0xFF2DD4BF),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _fieldDecoration(
            'Parolni tasdiqlang',
            prefix: Icon(Icons.lock_outline_rounded,
                color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
        const SizedBox(height: 20),
        GlassPrimaryButton(
          label: 'Parolni saqlash va kirish',
          loading: _loading,
          onPressed: _loading ? null : _submitNewPassword,
        ),
        TextButton(
          onPressed: _loading ? null : _backToLogin,
          child: Text(
            'Bekor qilish',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
      ];

  Widget _phoneBadge() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.phone_rounded,
              size: 18, color: Colors.white.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              formatPhoneDisplay(_normalizedPhone),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
