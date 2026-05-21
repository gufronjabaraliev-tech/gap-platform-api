/// Masul sifatida GAP yaratish narxlari va limitlar.
class GapPricing {
  GapPricing._();

  /// Bepul masul bo‘lish mumkin bo‘lgan GAP soni (dastlabki ommaviylik).
  static const int freeResponsibleGapLimit = 1;

  /// Qo‘shimcha GAP yaratish narxi (so‘m).
  static const int extraGapPriceUzs = 49_000;

  /// Barcha ishtirokchilar pul olgach GAPni qayta yoqish narxi (so‘m).
  static const int gapReactivationPriceUzs = 49_000;

  static String get extraGapPriceLabel =>
      '${_formatPrice(extraGapPriceUzs)} so\'m';

  static String get reactivationPriceLabel =>
      '${_formatPrice(gapReactivationPriceUzs)} so\'m';

  static String _formatPrice(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
  }
}
