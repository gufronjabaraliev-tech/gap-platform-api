import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class GapThemeExtension extends ThemeExtension<GapThemeExtension> {
  const GapThemeExtension({
    required this.primaryGradient,
    required this.heroShadow,
    required this.cardShadow,
    required this.glassOverlay,
    required this.mutedText,
    required this.success,
    required this.danger,
    required this.warning,
    required this.menuColors,
  });

  final LinearGradient primaryGradient;
  final List<BoxShadow> heroShadow;
  final List<BoxShadow> cardShadow;
  final Color glassOverlay;
  final Color mutedText;
  final Color success;
  final Color danger;
  final Color warning;
  final List<Color> menuColors;

  @override
  GapThemeExtension copyWith({
    LinearGradient? primaryGradient,
    List<BoxShadow>? heroShadow,
    List<BoxShadow>? cardShadow,
    Color? glassOverlay,
    Color? mutedText,
    Color? success,
    Color? danger,
    Color? warning,
    List<Color>? menuColors,
  }) {
    return GapThemeExtension(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      heroShadow: heroShadow ?? this.heroShadow,
      cardShadow: cardShadow ?? this.cardShadow,
      glassOverlay: glassOverlay ?? this.glassOverlay,
      mutedText: mutedText ?? this.mutedText,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      menuColors: menuColors ?? this.menuColors,
    );
  }

  @override
  GapThemeExtension lerp(ThemeExtension<GapThemeExtension>? other, double t) {
    if (other is! GapThemeExtension) return this;
    return GapThemeExtension(
      primaryGradient: LinearGradient.lerp(
            primaryGradient,
            other.primaryGradient,
            t,
          ) ??
          primaryGradient,
      heroShadow: heroShadow,
      cardShadow: cardShadow,
      glassOverlay: Color.lerp(glassOverlay, other.glassOverlay, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      menuColors: menuColors,
    );
  }

  static GapThemeExtension light() => GapThemeExtension(
        primaryGradient: AppColors.brandBackdropGradient,
        heroShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.32),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        cardShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        glassOverlay: Colors.white.withValues(alpha: 0.14),
        mutedText: const Color(0xFF6B7280),
        success: AppColors.success,
        danger: AppColors.danger,
        warning: AppColors.warning,
        menuColors: AppColors.menuPalette,
      );

  static GapThemeExtension dark() => GapThemeExtension(
        primaryGradient: AppColors.brandBackdropDarkGradient,
        heroShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
        cardShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        glassOverlay: Colors.white.withValues(alpha: 0.1),
        mutedText: const Color(0xFF9CA3AF),
        success: const Color(0xFF34D399),
        danger: const Color(0xFFF87171),
        warning: const Color(0xFFFBBF24),
        menuColors: AppColors.menuPaletteDark,
      );
}

extension GapThemeContext on BuildContext {
  GapThemeExtension get gap =>
      Theme.of(this).extension<GapThemeExtension>()!;
}
