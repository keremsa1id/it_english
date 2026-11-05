import 'package:flutter_test/flutter_test.dart';

import 'package:it_english/services/tts_service.dart';

void main() {
  group('voiceScore', () {
    test('İngilizce olmayan sesler elenir', () {
      expect(voiceScore((name: 'Microsoft Tolga', locale: 'tr-TR')), isNull);
      expect(voiceScore((name: 'Google Deutsch', locale: 'de-DE')), isNull);
    });

    test('alt çizgili ve küçük harfli dil kodları da tanınır', () {
      expect(voiceScore((name: 'Samantha', locale: 'en_us')), isNotNull);
    });
  });

  group('bestVoice', () {
    test("Chrome'da Google US English seçilir", () {
      final TtsVoice? best = bestVoice(<TtsVoice>[
        (name: 'Microsoft David - English (United States)', locale: 'en-US'),
        (name: 'Google US English', locale: 'en-US'),
        (name: 'Google UK English Female', locale: 'en-GB'),
        (name: 'Microsoft Tolga - Turkish', locale: 'tr-TR'),
      ]);

      expect(best?.name, 'Google US English');
    });

    test("Edge'de Natural ses robotik sesin önüne geçer", () {
      final TtsVoice? best = bestVoice(<TtsVoice>[
        (name: 'Microsoft Zira - English (United States)', locale: 'en-US'),
        (
          name: 'Microsoft Aria Online (Natural) - English (United States)',
          locale: 'en-US',
        ),
      ]);

      expect(best?.name, contains('Natural'));
    });

    test("iPhone'da Premium/Enhanced ses seçilir", () {
      final TtsVoice? best = bestVoice(<TtsVoice>[
        (name: 'Samantha', locale: 'en-US'),
        (name: 'Ava (Enhanced)', locale: 'en-US'),
      ]);

      expect(best?.name, 'Ava (Enhanced)');
    });

    test("Android'de ağ tabanlı ses cihaz içi sesin önüne geçer", () {
      final TtsVoice? best = bestVoice(<TtsVoice>[
        (name: 'en-us-x-sfg-local', locale: 'en-US'),
        (name: 'en-us-x-sfg-network', locale: 'en-US'),
      ]);

      expect(best?.name, 'en-us-x-sfg-network');
    });

    test('eşit kalitede ABD İngilizcesi önde gelir', () {
      final TtsVoice? best = bestVoice(<TtsVoice>[
        (name: 'Daniel', locale: 'en-GB'),
        (name: 'Alex', locale: 'en-US'),
        (name: 'Karen', locale: 'en-AU'),
      ]);

      expect(best?.locale, 'en-US');
    });

    test('İngilizce ses yoksa null döner (cihazın varsayılanı kalır)', () {
      expect(
        bestVoice(<TtsVoice>[(name: 'Microsoft Tolga', locale: 'tr-TR')]),
        isNull,
      );
      expect(bestVoice(const <TtsVoice>[]), isNull);
    });
  });
}
