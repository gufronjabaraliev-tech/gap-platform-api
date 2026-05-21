import 'package:flutter/material.dart';

/// GAP ilovasi ikonlari.
///
/// **Taqiqlangan (cho'chqa / jamg'arma-quti ko'rinishi):**
/// - `Icons.savings`, `Icons.savings_outlined`, `Icons.savings_rounded` va boshqa `savings*`
/// - `Icons.account_balance_wallet*` (hamyon — cho'chqaga o'xshash deb qabul qilinadi)
///
/// Pul / jamg'arma uchun: [payments], [groups], [brand] (masjid).
abstract final class GapIcons {
  GapIcons._();

  /// Masjid — brend va jamg'armalar tabi.
  static const IconData brand = Icons.mosque_rounded;
  static const IconData brandOutlined = Icons.mosque_outlined;

  /// To'lovlar, qarz, pul bloklari (cho'chqa emas).
  static const IconData payments = Icons.payments_rounded;
  static const IconData paymentsOutlined = Icons.payments_outlined;

  /// Guruh / GAP ro'yxati.
  static const IconData groups = Icons.groups_rounded;
}
