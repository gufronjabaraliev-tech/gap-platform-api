import '../config/gap_pricing.dart';
import '../models/gap_creation_eligibility.dart';
import '../models/member_role.dart';
import 'local_db_service.dart';

class GapCreationPaymentRequired implements Exception {
  GapCreationPaymentRequired();
}

class GapEntitlementService {
  GapEntitlementService(this._db);

  final LocalDbService _db;

  Future<int> responsibleGapCount(String userId) async {
    final memberships = await _db.membershipsForUser(userId);
    var count = 0;
    for (final m in memberships) {
      if (m.role == MemberRole.responsible) count++;
    }
    return count;
  }

  Future<GapCreationEligibility> eligibilityFor(String userId) async {
    final count = await responsibleGapCount(userId);
    if (count < GapPricing.freeResponsibleGapLimit) {
      return GapCreationEligibility(
        kind: GapCreationKind.free,
        responsibleGapCount: count,
      );
    }

    final user = await _db.getUserById(userId);
    final credits = user?.gapCreationCredits ?? 0;
    if (credits > 0) {
      return GapCreationEligibility(
        kind: GapCreationKind.paidCredit,
        responsibleGapCount: count,
        availableCredits: credits,
      );
    }

    return GapCreationEligibility(
      kind: GapCreationKind.paymentRequired,
      responsibleGapCount: count,
    );
  }

  /// To‘lovdan keyin qo‘shimcha GAP yaratish krediti.
  Future<void> grantCreationCredit(String userId, {int count = 1}) async {
    final user = await _db.getUserById(userId);
    if (user == null) return;
    final updated = user.copyWith(
      gapCreationCredits: user.gapCreationCredits + count,
    );
    await _db.saveUser(updated);
  }

  Future<void> consumeCreationCreditIfNeeded(String userId) async {
    final count = await responsibleGapCount(userId);
    if (count < GapPricing.freeResponsibleGapLimit) return;

    final user = await _db.getUserById(userId);
    if (user == null || user.gapCreationCredits < 1) {
      throw GapCreationPaymentRequired();
    }
    await _db.saveUser(
      user.copyWith(gapCreationCredits: user.gapCreationCredits - 1),
    );
  }
}
