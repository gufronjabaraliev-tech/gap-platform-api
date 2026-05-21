import '../utils/pin_util.dart';
import 'app_currency.dart';

class GroupMember {
  GroupMember({
    required this.id,
    required this.displayName,
    this.phone,
    this.linkedUserId,
    this.paymentCurrency,
    this.receiveCurrency,
  });

  final String id;
  String displayName;
  final String? phone;
  String? linkedUserId;
  /// Qaysi valyutada to'laydi. null = farqi yo'q (guruh/qabul qoidasiga qarab).
  AppCurrency? paymentCurrency;
  /// Navbat kelganda qaysi valyutada olishni xohlaydi. null = farqi yo'q.
  AppCurrency? receiveCurrency;

  bool get isRegistered => linkedUserId != null;
  bool get isPending => phone != null && linkedUserId == null;

  static String pendingIdForPhone(String phone) =>
      'pending_${normalizePhone(phone)}';

  String get paymentPrefLabel {
    if (paymentCurrency != null) {
      return 'To\'lov: ${paymentCurrency!.label}';
    }
    return 'To\'lov: farqi yo\'q';
  }

  String get receivePrefLabel {
    if (receiveCurrency != null) {
      return 'Qabul: ${receiveCurrency!.label}';
    }
    return 'Qabul: farqi yo\'q';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'displayName': displayName,
        if (phone != null) 'phone': phone,
        if (linkedUserId != null) 'linkedUserId': linkedUserId,
        if (paymentCurrency != null) 'paymentCurrency': paymentCurrency!.code,
        if (receiveCurrency != null) 'receiveCurrency': receiveCurrency!.code,
      };

  factory GroupMember.fromMap(Map<dynamic, dynamic> map) => GroupMember(
        id: map['id'] as String,
        displayName: map['displayName'] as String,
        phone: map['phone'] as String?,
        linkedUserId: map['linkedUserId'] as String?,
        paymentCurrency: map['paymentCurrency'] != null
            ? AppCurrency.fromCode(map['paymentCurrency'] as String?)
            : null,
        receiveCurrency: map['receiveCurrency'] != null
            ? AppCurrency.fromCode(map['receiveCurrency'] as String?)
            : null,
      );

  GroupMember copyWith({
    String? id,
    String? displayName,
    String? phone,
    String? linkedUserId,
    AppCurrency? paymentCurrency,
    AppCurrency? receiveCurrency,
  }) {
    return GroupMember(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      linkedUserId: linkedUserId ?? this.linkedUserId,
      paymentCurrency: paymentCurrency ?? this.paymentCurrency,
      receiveCurrency: receiveCurrency ?? this.receiveCurrency,
    );
  }
}
