import 'payment_entry.dart';

/// Joriy oluvchiga oldin qancha to'langan — endi qaytarish kerak.
class ReciprocalObligation {
  const ReciprocalObligation({
    required this.entry,
    required this.sourcePeriod,
    required this.payerMemberId,
    required this.currentReceiverId,
  });

  /// Oluvchi pul oluvchi navbatida to'lagan summa (qaytarilishi kerak).
  final PaymentEntry entry;
  final int sourcePeriod;
  final String payerMemberId;
  final String currentReceiverId;
}
