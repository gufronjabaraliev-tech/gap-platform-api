import '../config/gap_pricing.dart';

/// Foydalanuvchi yangi GAP yaratish huquqi.
enum GapCreationKind {
  /// Birinchi GAP — bepul.
  free,

  /// Sotib olingan kredit bilan.
  paidCredit,

  /// To‘lov talab qilinadi.
  paymentRequired,
}

class GapCreationEligibility {
  const GapCreationEligibility({
    required this.kind,
    required this.responsibleGapCount,
    this.availableCredits = 0,
  });

  final GapCreationKind kind;
  final int responsibleGapCount;
  final int availableCredits;

  bool get canCreate =>
      kind == GapCreationKind.free || kind == GapCreationKind.paidCredit;

  bool get needsPayment => kind == GapCreationKind.paymentRequired;

  String get subtitle => switch (kind) {
        GapCreationKind.free =>
          'Birinchi GAP yaratish bepul — ilovani sinab ko\'ring.',
        GapCreationKind.paidCredit =>
          'Sizda $availableCredits ta qo\'shimcha GAP krediti bor.',
        GapCreationKind.paymentRequired =>
          'Ikkinchi va keyingi GAPlar — ${GapPricing.extraGapPriceLabel}.',
      };
}
