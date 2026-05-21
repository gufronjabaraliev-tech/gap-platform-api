import 'app_currency.dart';

/// Markaziy bank referens kursi (1 nominal birlik = [rateUzs] so'm).
class BankRate {
  const BankRate({
    required this.currency,
    required this.rateUzs,
    this.nominal = 1,
    this.source = 'default',
    this.updatedAt,
  });

  final AppCurrency currency;
  final double rateUzs;
  final int nominal;
  final String source;
  final DateTime? updatedAt;

  double get perUnit => rateUzs / nominal;

  String get nominalLabel => nominal == 1 ? '1' : '$nominal';
}
