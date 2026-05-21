/// Jamg'arma va to'lovlarda qo'llab-quvvatlanadigan valyutalar.
enum AppCurrency {
  uzs('UZS', 'so\'m', 'O\'zbek so\'mi'),
  usd('USD', r'$', 'AQSh dollari'),
  eur('EUR', '€', 'Yevro'),
  rub('RUB', '₽', 'Rubl'),
  kzt('KZT', '₸', 'Qozoq tengesi'),
  kgs('KGS', 'с', 'Qirg\'iz somi'),
  tjs('TJS', 'SM', 'Tojik somonisi');

  const AppCurrency(this.code, this.symbol, this.label);

  final String code;
  final String symbol;
  final String label;

  /// Mintaqaviy "som" valyutalari (katta nominal).
  bool get isRegionalSom =>
      this == AppCurrency.uzs ||
      this == AppCurrency.kgs ||
      this == AppCurrency.tjs;

  static AppCurrency fromCode(String? code) {
    if (code == null || code.isEmpty) return AppCurrency.uzs;
    return AppCurrency.values.firstWhere(
      (c) => c.code == code.toUpperCase(),
      orElse: () => AppCurrency.uzs,
    );
  }

  /// 1 birlik [bu valyuta] = necha so'm (standart kurs, masul o'zgartirishi mumkin).
  double defaultRateToUzs() {
    switch (this) {
      case AppCurrency.uzs:
        return 1;
      case AppCurrency.usd:
        return 12500;
      case AppCurrency.eur:
        return 13500;
      case AppCurrency.rub:
        return 135;
      case AppCurrency.kzt:
        return 28;
      case AppCurrency.kgs:
        return 140;
      case AppCurrency.tjs:
        return 1150;
    }
  }

  /// To'lov ekranidagi tez tanlash summalari (shu valyuta birligida).
  List<int> get quickPaymentAmounts {
    switch (this) {
      case AppCurrency.usd:
        return const [10, 50, 200];
      case AppCurrency.eur:
        return const [50, 100, 200];
      case AppCurrency.rub:
        return const [5000, 10000, 20000];
      case AppCurrency.uzs:
        return const [500000, 1000000, 2000000];
      case AppCurrency.kzt:
        return const [250000, 500000, 1000000];
      case AppCurrency.kgs:
        return const [5000, 10000, 20000];
      case AppCurrency.tjs:
        return const [500, 1000, 2000];
    }
  }

  /// 1 birlik [from] = necha [settlement] birlik.
  static double rateBetween(AppCurrency from, AppCurrency settlement) {
    if (from == settlement) return 1;
    final fromUzs = from.defaultRateToUzs();
    final settleUzs = settlement.defaultRateToUzs();
    return fromUzs / settleUzs;
  }
}
