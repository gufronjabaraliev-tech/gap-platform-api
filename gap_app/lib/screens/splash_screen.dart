import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../services/onboarding_prefs.dart';
import '../services/platform_api_service.dart';
import '../services/remote_app_config_service.dart';
import 'auth/login_screen.dart';
import 'main_shell_screen.dart';
import 'onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await context.read<AuthProvider>().init();
    await RemoteAppConfigService.instance.refresh();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;

    final maintenance = RemoteAppConfigService.instance.config;
    if (maintenance?.maintenanceEnabled == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => _MaintenanceScreen(
            message: maintenance!.maintenanceMessage,
          ),
        ),
      );
      return;
    }

    final loggedIn = context.read<AuthProvider>().isLoggedIn;
    await PlatformApiService.instance.trackEvent(
      'app_open',
      userId: context.read<AuthProvider>().user?.id,
    );
    final onboardingDone = await OnboardingPrefs.isCompleted();
    if (!mounted) return;

    final Widget next;
    if (loggedIn) {
      next = MainShellScreen(key: MainShellScreen.globalKey);
    } else if (!onboardingDone) {
      next = const OnboardingScreen();
    } else {
      next = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backdrop = Theme.of(context).brightness == Brightness.dark
        ? AppColors.brandBackdropDarkGradient
        : AppColors.brandBackdropGradient;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: backdrop),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GAP',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.98),
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Navbatli jamg\'arma',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'GROW • ACT • PROSPER',
                  style: TextStyle(
                    color: AppColors.gold.withValues(alpha: 0.95),
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MaintenanceScreen extends StatelessWidget {
  const _MaintenanceScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.engineering_rounded, size: 56),
              const SizedBox(height: 16),
              Text(
                'Texnik ishlar',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message.isNotEmpty
                    ? message
                    : 'Ilova vaqtincha mavjud emas. Keyinroq urinib ko\'ring.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
