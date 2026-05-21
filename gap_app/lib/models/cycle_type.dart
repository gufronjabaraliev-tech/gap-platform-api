enum CycleType {
  weekly,
  tenDay,
  monthly;

  String get label => switch (this) {
        CycleType.weekly => 'Haftalik',
        CycleType.tenDay => '10 kunlik',
        CycleType.monthly => 'Oylik',
      };

  String get periodLabel => switch (this) {
        CycleType.weekly => 'hafta',
        CycleType.tenDay => 'davr',
        CycleType.monthly => 'oy',
      };

  static CycleType fromString(String? v) => switch (v) {
        'tenDay' => CycleType.tenDay,
        'monthly' => CycleType.monthly,
        _ => CycleType.weekly,
      };

  String get storageKey => name;
}
