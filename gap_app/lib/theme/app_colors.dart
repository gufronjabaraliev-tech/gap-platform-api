import 'package:flutter/material.dart';

/// Yashil + oltin — islomiy dizayn palitrasi (cho'chqa tasviri yo'q).
class AppColors {
  /// Asosiy yashil
  static const primary = Color(0xFF047857);
  static const primaryDark = Color(0xFF065F46);
  /// Oltin urg'u
  static const secondary = Color(0xFFC5A028);
  static const secondaryDeep = Color(0xFF9A7B0C);

  static const success = Color(0xFF15803D);
  static const danger = Color(0xFFDC2626);
  static const warning = Color(0xFFD97706);

  static const emerald = Color(0xFF059669);
  static const teal = Color(0xFF0D9488);
  static const forest = Color(0xFF166534);
  static const gold = Color(0xFFD4AF37);
  static const deepBlue = Color(0xFF1E3A5F);
  static const olive = Color(0xFF4D7C0F);

  static const menuPalette = [
    primary,
    teal,
    forest,
    gold,
    emerald,
    deepBlue,
    secondaryDeep,
    olive,
  ];

  static const menuPaletteDark = [
    Color(0xFF34D399),
    Color(0xFF2DD4BF),
    Color(0xFF4ADE80),
    Color(0xFFFBBF24),
    Color(0xFF6EE7B7),
    Color(0xFF93C5FD),
    Color(0xFFFCD34D),
    Color(0xFFA3E635),
  ];

  static const lightScaffold = Color(0xFFF5FAF7);
  static const darkScaffold = Color(0xFF0A1612);
  static const lightSurface = Color(0xFFFFFFFF);
  static const darkSurface = Color(0xFF13221C);
  static const darkSurfaceHigh = Color(0xFF1B2E26);

  /// Kirish / splash fon — doim yashil → oltin (keshda eski binafsha ko‘rinmasin).
  static const LinearGradient brandBackdropGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF064E3B),
      primary,
      Color(0xFFC9A227),
    ],
    stops: [0.0, 0.52, 1.0],
  );

  /// Kichik ramka / ikonka fonlari.
  static const LinearGradient brandIconShade = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary],
  );

  /// Tungi mavzu uchun fon gradienti.
  static const LinearGradient brandBackdropDarkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF022C22),
      Color(0xFF0F766E),
      Color(0xFF92400E),
    ],
    stops: [0.0, 0.55, 1.0],
  );
}
