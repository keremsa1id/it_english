import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:it_english/models/term.dart';
import 'package:it_english/services/achievement_service.dart';
import 'package:it_english/services/progress_service.dart';

Term _term(String term) => Term(
      term: term,
      category: 'data',
      definition: 'Definition of $term.',
      exampleSentence: 'This long example sentence uses the $term word.',
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<void> learn(ProgressService progress, Iterable<String> words) async {
    for (final String word in words) {
      await progress.setLearned(_term(word), learned: true);
    }
  }

  test('10 kelime öğrenilince "First 10 words" kazanılır ve haber verilir',
      () async {
    final ProgressService progress = ProgressService.forTest();
    final AchievementService service = AchievementService.forTest(
      progress: progress,
      groupKeys: const <String, Set<String>>{},
    );
    final List<String> celebrated = <String>[];
    service.onEarned = (Achievement a) => celebrated.add(a.id);

    await learn(progress, List<String>.generate(9, (int i) => 'word$i'));
    expect(service.check(), isEmpty);

    await learn(progress, <String>['word9']);
    final List<Achievement> earned = service.check();

    expect(earned.map((Achievement a) => a.id), <String>['learned_10']);
    expect(celebrated, <String>['learned_10']);
    expect(progress.isEarned('learned_10'), isTrue);
    // İkinci kontrolde aynı rozet tekrar kutlanmaz.
    expect(service.check(), isEmpty);
  });

  test('sessiz kontrol rozeti işaretler ama kutlama göstermez', () async {
    final ProgressService progress = ProgressService.forTest();
    final AchievementService service = AchievementService.forTest(
      progress: progress,
      groupKeys: const <String, Set<String>>{},
    );
    final List<String> celebrated = <String>[];
    service.onEarned = (Achievement a) => celebrated.add(a.id);
    await learn(progress, List<String>.generate(10, (int i) => 'word$i'));

    service.check(silent: true);

    expect(progress.isEarned('learned_10'), isTrue);
    expect(celebrated, isEmpty);
  });

  test('seri bozulsa da kazanılan seri rozeti kalır', () async {
    DateTime now = DateTime(2026, 3, 10, 9);
    final ProgressService progress = ProgressService.forTest(now: () => now);
    final AchievementService service = AchievementService.forTest(
      progress: progress,
      groupKeys: const <String, Set<String>>{},
    );
    await progress.setDailyGoal(5);
    for (int day = 0; day < 3; day++) {
      now = DateTime(2026, 3, 10 + day, 9);
      for (int i = 0; i < 5; i++) {
        await progress.recordPractice();
      }
    }
    service.check();
    expect(progress.isEarned('streak_3'), isTrue);

    now = DateTime(2026, 3, 20, 9);
    expect(progress.streak, 0);
    expect(progress.isEarned('streak_3'), isTrue);
  });

  test('IT klasörlerinin bütün kelimeleri öğrenilince "IT master" kazanılır',
      () async {
    final ProgressService progress = ProgressService.forTest();
    final AchievementService service = AchievementService.forTest(
      progress: progress,
      groupKeys: <String, Set<String>>{
        'IT Terms': <String>{'cpu', 'ram'},
        'Advanced IT': <String>{'sql'},
        'Verbs': <String>{'run'},
      },
    );

    await learn(progress, <String>['cpu', 'ram']);
    expect(
      Achievement.all
          .firstWhere((Achievement a) => a.id == 'all_it')
          .measure(service.context),
      (2, 3),
    );

    await learn(progress, <String>['sql']);
    service.check();

    expect(progress.isEarned('all_it'), isTrue);
    // Verbs öğrenilmeden de IT klasörleri tamamlandığı için klasör rozeti de
    // kazanılır.
    expect(progress.isEarned('folder_complete'), isTrue);
  });

  test('klasör bilgisi yokken klasör rozetleri kazanılmaz', () async {
    final ProgressService progress = ProgressService.forTest();
    final AchievementService service = AchievementService.forTest(
      progress: progress,
      groupKeys: const <String, Set<String>>{},
    );

    service.check();

    expect(progress.isEarned('all_it'), isFalse);
    expect(progress.isEarned('folder_complete'), isFalse);
  });

  test('bütün soruları doğru bilinen quiz "Perfect quiz" kazandırır', () async {
    final ProgressService progress = ProgressService.forTest();
    final AchievementService service = AchievementService.forTest(
      progress: progress,
      groupKeys: const <String, Set<String>>{},
    );

    await progress.recordQuiz('verbs', 9, 10);
    service.check();
    expect(progress.isEarned('perfect_quiz'), isFalse);

    await progress.recordQuiz('verbs', 10, 10);
    service.check();
    expect(progress.isEarned('perfect_quiz'), isTrue);
  });

  test('kazanılan rozetler kaydedilir ve geri okunur', () async {
    final ProgressService first = ProgressService.forTest();
    await first.load();
    first.markEarned(<String>['learned_10']);
    // Kayıt arkada yapılır; bitmesini bekle.
    await Future<void>.delayed(Duration.zero);

    final ProgressService second = ProgressService.forTest();
    await second.load();

    expect(second.isEarned('learned_10'), isTrue);
  });
}
