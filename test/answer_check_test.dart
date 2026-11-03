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

  group('söylenen kelime', () {
    test('tahminlerden biri doğruysa kabul edilir', () {
      expect(isSpokenMatch(<String>['fire wall', 'firewall'], 'firewall'), isTrue);
    });

    test('noktalama ve büyük harf önemsenmez', () {
      expect(isSpokenMatch(<String>['Firewall.'], 'firewall'), isTrue);
    });

    test('terimi tek başına içeren cümle kabul edilir', () {
      expect(isSpokenMatch(<String>['the firewall'], 'firewall'), isTrue);
      expect(isSpokenMatch(<String>['I said look for'], 'look for'), isTrue);
    });

    test('harf harf söylenen kısaltma kabul edilir', () {
      expect(isSpokenMatch(<String>['s q l'], 'SQL'), isTrue);
    });

    test('başka kelime ya da kelimenin parçası kabul edilmez', () {
      expect(isSpokenMatch(<String>['router'], 'firewall'), isFalse);
      expect(isSpokenMatch(<String>['debugging'], 'bug'), isFalse);
      expect(isSpokenMatch(const <String>[], 'firewall'), isFalse);
    });
  });

  test('boş cevap yanlış sayılır', () {
    expect(isCorrectAnswer('', 'firewall'), isFalse);
    expect(isCorrectAnswer('  - ', 'firewall'), isFalse);
  });
}
