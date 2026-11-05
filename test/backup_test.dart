import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:it_english/models/term.dart';
import 'package:it_english/services/progress_service.dart';

Term _term(String term) => Term(
      term: term,
      category: 'data',
      definition: 'Definition of $term.',
      exampleSentence: 'This long example sentence uses the $term word.',
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  /// Biraz ilerlemesi olan bir servis.
  Future<ProgressService> withProgress() async {
    final ProgressService progress = ProgressService.forTest();
    await progress.setLearned(_term('cache'), learned: true);
    await progress.toggleFavorite(_term('folder'));
    await progress.recordAnswer(_term('router'), correct: false);
    await progress.recordQuiz('verbs', 8, 10);
    await progress.setDailyGoal(20);
    return progress;
  }

  test('yedek başka cihaza geri yüklenince ilerleme aynen gelir', () async {
    final String backup = await (await withProgress()).exportBackup();

    // "Yeni telefon": boş kayıtlar.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProgressService restored = ProgressService.forTest();
    await restored.importBackup(backup);

    expect(restored.isLearned(_term('cache')), isTrue);
    expect(restored.isFavorite(_term('folder')), isTrue);
    expect(restored.isInReview(_term('router')), isTrue);
    expect(restored.bestScore('verbs')?.score, 8);
    expect(restored.dailyGoal, 20);
    expect(restored.mostMissed(), <(String, int)>[('router', 1)]);
  });

  test('yedek, uygulamayı ve sürümü belirten okunabilir bir JSON metnidir',
      () async {
    final String backup = await (await withProgress()).exportBackup();
    final Map<String, dynamic> json = jsonDecode(backup) as Map<String, dynamic>;

    expect(json['app'], 'it_english');
    expect(json['version'], ProgressService.backupVersion);
    expect((json['data'] as Map<String, dynamic>)['learnedTerms'], <String>['cache']);
  });

  test('geri yükleme mevcut ilerlemenin yerine geçer', () async {
    final String backup = await (await withProgress()).exportBackup();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProgressService other = ProgressService.forTest();
    await other.setLearned(_term('printer'), learned: true);

    await other.importBackup(backup);

    expect(other.isLearned(_term('printer')), isFalse);
    expect(other.isLearned(_term('cache')), isTrue);
  });

  group('geçersiz yedek mevcut ilerlemeye dokunmaz', () {
    Future<void> expectRejected(String raw) async {
      final ProgressService progress = await withProgress();

      await expectLater(progress.importBackup(raw), throwsFormatException);

      expect(progress.isLearned(_term('cache')), isTrue);
      expect(progress.dailyGoal, 20);
    }

    test('JSON olmayan metin', () => expectRejected('merhaba'));

    test('başka bir uygulamanın verisi', () {
      return expectRejected(jsonEncode(<String, Object>{
        'app': 'other',
        'version': 1,
        'data': <String, Object>{},
      }));
    });

    test('daha yeni bir sürümün yedeği', () {
      return expectRejected(jsonEncode(<String, Object>{
        'app': 'it_english',
        'version': ProgressService.backupVersion + 1,
        'data': <String, Object>{},
      }));
    });

    test('türü bozuk bir değer', () {
      return expectRejected(jsonEncode(<String, Object>{
        'app': 'it_english',
        'version': 1,
        'data': <String, Object>{
          'learnedTerms': <String>['cache'],
          'dailyGoal': 'yirmi',
        },
      }));
    });
  });
}
