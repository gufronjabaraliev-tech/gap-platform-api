import 'app_currency.dart';

class PaymentEntry {
  const PaymentEntry({
    required this.amount,
    required this.currency,
    /// 1 birlik [currency] = [exchangeRate] birlik asosiy valyutada.
    this.exchangeRate,
  });

  final int amount;
  final AppCurrency currency;
  final double? exchangeRate;

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'currency': currency.code,
        if (exchangeRate != null) 'exchangeRate': exchangeRate,
      };

  factory PaymentEntry.fromMap(Map<dynamic, dynamic> map) => PaymentEntry(
        amount: map['amount'] as int? ?? 0,
        currency: AppCurrency.fromCode(map['currency'] as String?),
        exchangeRate: (map['exchangeRate'] as num?)?.toDouble(),
      );

  factory PaymentEntry.legacy(int amount, AppCurrency currency) =>
      PaymentEntry(amount: amount, currency: currency);

  PaymentEntry copyWith({
    int? amount,
    AppCurrency? currency,
    double? exchangeRate,
  }) =>
      PaymentEntry(
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        exchangeRate: exchangeRate ?? this.exchangeRate,
      );

  @override
  bool operator ==(Object other) =>
      other is PaymentEntry &&
      other.amount == amount &&
      other.currency == currency &&
      other.exchangeRate == exchangeRate;

  @override
  int get hashCode => Object.hash(amount, currency, exchangeRate);
}
