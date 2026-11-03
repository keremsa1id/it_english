import 'package:flutter_test/flutter_test.dart';

import 'package:it_english/models/quiz_mode.dart';

void main() {
  test('boşluk doldurma skoru eski anahtarla saklanır', () {
    expect(QuizMode.fillBlank.scoreId('mixed'), 'mixed');
  });

  test('diğer türlerin skorları ayrı anahtarla saklanır', () {
    final Set<String> ids = <String>{
      for (final QuizMode mode in QuizMode.values) mode.scoreId('mixed'),
    };
    expect(ids, hasLength(QuizMode.values.length));
  });

  test('cümlede boşluk gösteren türler cümlede terim ister', () {
    expect(QuizMode.fillBlank.needsBlank, isTrue);
    expect(QuizMode.typing.needsBlank, isTrue);
    expect(QuizMode.definition.needsBlank, isFalse);
    expect(QuizMode.listening.needsBlank, isFalse);
    expect(QuizMode.speaking.needsBlank, isFalse);
  });

  test('yalnızca konuşma türünde cevap sesli verilir', () {
    expect(
      QuizMode.values.where((QuizMode m) => m.isSpoken),
      <QuizMode>[QuizMode.speaking],
    );
  });

  test('yalnızca yazma türünde şık yoktur', () {
    expect(
      QuizMode.values.where((QuizMode m) => m.isTyped),
      <QuizMode>[QuizMode.typing],
    );
  });
}
