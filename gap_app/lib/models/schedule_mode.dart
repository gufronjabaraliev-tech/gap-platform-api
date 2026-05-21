import 'package:flutter/material.dart';

/// Navbat shakllantirish usuli.
enum ScheduleMode {
  /// Ishtirokchilar kimga kerak bo'lsa unga yig'adi; masul pul oluvchini belgilaydi.
  manual(
    'manual',
    'Ixtiyoriy',
    'Har ishtirokchi tsiklda 1 marta oladi. Masul pul olmaganlardan birini tanlaydi.',
  ),

  /// Har GAP davrida tasodifiy tanlash ekrani va animatsiya.
  randomEach(
    'random_each',
    'Har gal tasodifiy',
    'Har safar faqat pul olmaganlar orasidan tasodifiy tanlanadi — '
        'har kishi 1 marta oladi.',
  ),

  /// A'zolar qo'shilgach bir marta navbat tuziladi; shu tartibda davom etadi.
  fixedRandom(
    'fixed_random',
    'GAP navbat',
    'Har ishtirokchi navbatda 1 marta oladi. Navbat tasodifiy tuziladi. '
        'Masul xohlasa 1 marta istalgan ishtirokchini pul oluvchi qilib belgilashi mumkin.',
  );

  const ScheduleMode(this.storageKey, this.label, this.description);

  final String storageKey;
  final String label;
  final String description;

  IconData get icon => switch (this) {
        ScheduleMode.fixedRandom => Icons.format_list_numbered_rounded,
        ScheduleMode.manual => Icons.touch_app_rounded,
        ScheduleMode.randomEach => Icons.casino_rounded,
      };

  static ScheduleMode fromString(String? key) {
    if (key == null) return ScheduleMode.fixedRandom;
    return ScheduleMode.values.firstWhere(
      (m) => m.storageKey == key,
      orElse: () => ScheduleMode.fixedRandom,
    );
  }
}
