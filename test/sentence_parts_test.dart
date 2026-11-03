import 'package:flutter_test/flutter_test.dart';

import 'package:it_english/utils/sentence_parts.dart';

void main() {
  test('terimi ayrı parça olarak bulur', () {
    expect(splitSentence('Restart the router now.', 'router'), const <SentencePart>[
      SentencePart('Restart the '),
      SentencePart('router', isTerm: true),
      SentencePart(' now.'),
    ]);
  });

  test('büyük/küçük harfe bakmaz ve orijinal yazımı korur', () {
    expect(splitSentence('Debugging takes time.', 'debugging'), const <SentencePart>[
      SentencePart('Debugging', isTerm: true),
      SentencePart(' takes time.'),
    ]);
  });

  test('başka kelimenin içindeki eşleşmeyi bulmaz', () {
    expect(splitSentence('Debugging takes time.', 'bug'), const <SentencePart>[
      SentencePart('Debugging takes time.'),
    ]);
  });

  test('tireli ve çok kelimeli terimleri bulur', () {
    expect(
      splitSentence('Free Wi-Fi and an IP address.', 'Wi-Fi')
          .where((SentencePart p) => p.isTerm),
      const <SentencePart>[SentencePart('Wi-Fi', isTerm: true)],
    );
    expect(
      splitSentence('Free Wi-Fi and an IP address.', 'IP address')
          .where((SentencePart p) => p.isTerm),
      const <SentencePart>[SentencePart('IP address', isTerm: true)],
    );
  });

  test('tireli kelimenin parçasını terim saymaz', () {
    expect(
      splitSentence('Use two-factor login.', 'two')
          .any((SentencePart p) => p.isTerm),
      isFalse,
    );
  });
}
