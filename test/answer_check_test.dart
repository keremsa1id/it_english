import 'package:flutter_test/flutter_test.dart';

import 'package:it_english/utils/answer_check.dart';

void main() {
  test('aynı kelime doğru sayılır', () {
    expect(isCorrectAnswer('firewall', 'firewall'), isTrue);
  });

  test('büyük/küçük harf ve baştaki/sondaki boşluk önemsenmez', () {
    expect(isCorrectAnswer('  Firewall ', 'firewall'), isTrue);
    expect(isCorrectAnswer('ssd', 'SSD'), isTrue);
  });

  test('tire, eğik çizgi ve aradaki boşluklar önemsenmez', () {
    expect(isCorrectAnswer('wifi', 'Wi-Fi'), isTrue);
    expect(isCorrectAnswer('ci cd', 'CI/CD'), isTrue);
    expect(isCorrectAnswer('look  forward to', 'look forward to'), isTrue);
  });

  test('farklı kelime yanlış sayılır', () {
    expect(isCorrectAnswer('router', 'firewall'), isFalse);
    expect(isCorrectAnswer('firewal', 'firewall'), isFalse);
  });

  test('boş cevap yanlış sayılır', () {
    expect(isCorrectAnswer('', 'firewall'), isFalse);
    expect(isCorrectAnswer('  - ', 'firewall'), isFalse);
  });
}
