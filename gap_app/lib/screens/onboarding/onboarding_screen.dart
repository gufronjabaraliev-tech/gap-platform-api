import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/remote_app_config_service.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _defaultPages = <OnboardingItem>[
    OnboardingItem(
      title: "Oson va ishonchli jamg'arma",
      description:
          "Guruhingiz bilan oson boshqarish, shaffof va xavfsiz tizim.",
      icon: Icons.groups_rounded,
    ),
    OnboardingItem(
      title: 'Shaffoflik va ishonch ustuvor',
      description:
          "Har bir operatsiya aniq, hisobotlar to'liq va tushunarli.",
      icon: Icons.visibility_rounded,
    ),
    OnboardingItem(
      title: 'Maqsadlar sari birgalikda',
      description:
          'Kichik hissa – katta natija. Birgalikda orzularimizga erishamiz.',
      icon: Icons.people_rounded,
    ),
    OnboardingItem(
      title: 'Hisobot',
      description:
          "Guruh a'zolarining to'lovlari va tizim faoliyati sizning qo'lingizda.",
      icon: Icons.bar_chart_rounded,
      isLast: true,
    ),
  ];

  List<OnboardingItem> get _pages {
    final remote = RemoteAppConfigService.instance.onboardingPages;
    if (remote.isEmpty) return _defaultPages;
    return remote
        .map(
          (p) => OnboardingItem(
            title: p.title,
            description: p.description,
            icon: p.iconData,
            isLast: p.isLast,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  Future<void> _navigateToLogin() async {
    await context.read<AuthProvider>().setOnboardingComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B3D2E), Color(0xFF072A1F)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _navigateToLogin,
                  child: const Text(
                    'O\'TKAZIB YUBORISH',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return OnboardingPageContent(item: _pages[index]);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentPage == index
                                ? AppColors.gold
                                : Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: const Color(0xFF0B3D2E),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'BOSHLASH'
                            : 'KEYINGI',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingItem {
  const OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    this.isLast = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isLast;
}

class OnboardingPageContent extends StatelessWidget {
  const OnboardingPageContent({super.key, required this.item});

  final OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Icon(
              item.icon,
              size: 60,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            item.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (item.isLast) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  _paymentTile(
                    letter: 'A',
                    name: 'Azizbek',
                    time: 'Bayan, 08:41',
                    amount: '500 000 so\'m',
                  ),
                  Divider(
                    color: Colors.white.withValues(alpha: 0.12),
                    height: 1,
                  ),
                  _paymentTile(
                    letter: 'M',
                    name: 'Malka',
                    time: 'Bayan, 08:15',
                    amount: '300 000 so\'m',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _paymentTile({
    required String letter,
    required String name,
    required String time,
    required String amount,
  }) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor: AppColors.gold.withValues(alpha: 0.25),
        child: Text(
          letter,
          style: const TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        time,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
      ),
      trailing: Text(
        amount,
        style: const TextStyle(
          color: AppColors.gold,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
