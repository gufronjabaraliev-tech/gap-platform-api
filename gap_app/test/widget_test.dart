import 'package:flutter_test/flutter_test.dart';
import 'package:gap_app/utils/pin_util.dart';

void main() {
  test('telefon normalizatsiyasi', () {
    expect(normalizePhone('901234567'), '998901234567');
    expect(isValidPhone('901234567'), true);
  });

  test('PIN tekshiruvi', () {
    expect(isValidPin('1234', 4), true);
    expect(isValidPin('12345', 4), false);
    expect(isValidPin('123456', 6), true);
  });
}
