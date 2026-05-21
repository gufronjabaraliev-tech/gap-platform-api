import '../utils/pin_util.dart';

String _normalizeStoredPhone(String raw) {
  final n = normalizePhone(raw.trim());
  return RegExp(r'^998\d{9}$').hasMatch(n) ? n : '';
}

class AppUser {
  AppUser({
    required this.id,
    required this.phone,
    required this.name,
    required this.pinHash,
    required this.pinLength,
    this.createdAt,
    this.gapCreationCredits = 0,
    List<String>? extraPhones,
    this.localAvatarFileName,
  }) : extraPhones = extraPhones ?? [];

  final String id;
  final String phone;
  final String name;
  final String pinHash;
  final int pinLength;
  final DateTime? createdAt;
  /// Qo‘shimcha GAP yaratish uchun sotib olingan kreditlar.
  final int gapCreationCredits;
  /// Qo'shimcha biriktirilgan telefonlar (kirish va jamg'armalar uchun).
  final List<String> extraPhones;
  /// Qurilmadagi profil rasm fayli nomi.
  final String? localAvatarFileName;

  List<String> get allPhones => [phone, ...extraPhones];

  Map<String, dynamic> toMap() => {
        'id': id,
        'phone': phone,
        'name': name,
        'pinHash': pinHash,
        'pinLength': pinLength,
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
        'gapCreationCredits': gapCreationCredits,
        'extraPhones': extraPhones,
        if (localAvatarFileName != null)
          'localAvatarFileName': localAvatarFileName,
      };

  factory AppUser.fromMap(Map<dynamic, dynamic> map) => AppUser(
        id: map['id'] as String,
        phone: map['phone'] as String,
        name: map['name'] as String,
        pinHash: map['pinHash'] as String,
        pinLength: map['pinLength'] as int? ?? 4,
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String)
            : null,
        gapCreationCredits: map['gapCreationCredits'] as int? ?? 0,
        extraPhones: List<String>.from(
          (map['extraPhones'] as List<dynamic>? ?? [])
              .map((e) => _normalizeStoredPhone(e.toString()))
              .where((p) => p.isNotEmpty),
        ),
        localAvatarFileName: map['localAvatarFileName'] as String?,
      );

  AppUser copyWith({
    String? id,
    String? phone,
    String? name,
    String? pinHash,
    int? pinLength,
    DateTime? createdAt,
    int? gapCreationCredits,
    List<String>? extraPhones,
    String? localAvatarFileName,
    bool clearAvatar = false,
  }) {
    return AppUser(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      pinHash: pinHash ?? this.pinHash,
      pinLength: pinLength ?? this.pinLength,
      createdAt: createdAt ?? this.createdAt,
      gapCreationCredits: gapCreationCredits ?? this.gapCreationCredits,
      extraPhones: extraPhones ?? this.extraPhones,
      localAvatarFileName:
          clearAvatar ? null : (localAvatarFileName ?? this.localAvatarFileName),
    );
  }
}
