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

  test('öğrenilen kelimeleri sayar ve geri alabilir', () async {
    final ProgressService progress = ProgressService.forTest();
    final List<Term> terms = <Term>[_term('cache'), _term('folder')];

    await progress.setLearned(terms[0], learned: true);
    expect(progress.isLearned(terms[0]), isTrue);
    expect(progress.learnedCount(terms), 1);

    await progress.setLearned(terms[0], learned: false);
    expect(progress.learnedCount(terms), 0);
  });

  test('büyük/küçük harf farkı aynı kelime sayılır', () async {
    final ProgressService progress = ProgressService.forTest();

    await progress.setLearned(_term('Cache'), learned: true);

    expect(progress.isLearned(_term('cache')), isTrue);
  });

  test('yalnızca daha iyi quiz sonucu en iyi skorun yerine geçer', () async {
    final ProgressService progress = ProgressService.forTest();

    await progress.recordQuiz('verbs', 6, 10);
    await progress.recordQuiz('verbs', 5, 10);
    expect(progress.bestScore('verbs')?.score, 6);

    await progress.recordQuiz('verbs', 9, 10);
    expect(progress.bestScore('verbs')?.score, 9);
    expect(progress.bestScore('nouns'), isNull);
  });

  test('ilerleme kaydedilir ve yeniden açılınca geri okunur', () async {
    final ProgressService first = ProgressService.forTest();
    await first.setLearned(_term('cache'), learned: true);
    await first.recordQuiz('mixed', 18, 25);

    final ProgressService second = ProgressService.forTest();
    await second.load();

    expect(second.isLearned(_term('cache')), isTrue);
    expect(second.bestScore('mixed')?.score, 18);
    expect(second.bestScore('mixed')?.total, 25);
  });

  test('yanlış cevap kelimeyi Review destesine koyar', () async {
    final ProgressService progress = ProgressService.forTest();
    final Term term = _term('cache');
    await progress.recordAnswer(term, correct: true);

    await progress.recordAnswer(term, correct: false);

    expect(progress.isInReview(term), isTrue);
    expect(progress.isLearned(term), isFalse);
    expect(progress.reviewCount, 1);
  });

  test('Review kelimesi art arda iki doğru cevapla desteden çıkar', () async {
    final ProgressService progress = ProgressService.forTest();
    final Term term = _term('cache');
    await progress.recordAnswer(term, correct: false);

    await progress.recordAnswer(term, correct: true);
    expect(progress.isInReview(term), isTrue);

    await progress.recordAnswer(term, correct: true);
    expect(progress.isInReview(term), isFalse);
    expect(progress.isLearned(term), isTrue);
  });

  test('arada yanlış cevap Review sayacını baştan başlatır', () async {
    final ProgressService progress = ProgressService.forTest();
    final Term term = _term('cache');
    await progress.recordAnswer(term, correct: false);
    await progress.recordAnswer(term, correct: true);

    await progress.recordAnswer(term, correct: false);
    await progress.recordAnswer(term, correct: true);

    expect(progress.isInReview(term), isTrue);
  });

  test('Review destesi kaydedilir ve geri okunur', () async {
    final ProgressService first = ProgressService.forTest();
    await first.recordAnswer(_term('cache'), correct: false);

    final ProgressService second = ProgressService.forTest();
    await second.load();

    expect(second.isInReview(_term('cache')), isTrue);
  });

  test('favoriye ekler, tekrar basınca çıkarır', () async {
    final ProgressService progress = ProgressService.forTest();
    final Term term = _term('cache');

    await progress.toggleFavorite(term);
    expect(progress.isFavorite(term), isTrue);
    expect(progress.favoriteCount, 1);

    await progress.toggleFavorite(term);
    expect(progress.isFavorite(term), isFalse);
    expect(progress.favoriteCount, 0);
  });

  test('favoriler kaydedilir ve geri okunur', () async {
    final ProgressService first = ProgressService.forTest();
    await first.toggleFavorite(_term('cache'));

    final ProgressService second = ProgressService.forTest();
    await second.load();

    expect(second.isFavorite(_term('cache')), isTrue);
  });

  group('günlük hedef ve seri', () {
    late DateTime now;
    ProgressService create() => ProgressService.forTest(now: () => now);

    Future<void> practice(ProgressService progress, int times) async {
      for (int i = 0; i < times; i++) {
        await progress.recordPractice();
      }
    }

    setUp(() => now = DateTime(2026, 3, 10, 9));

    test('bugünkü soruları sayar, ertesi gün sıfırdan başlar', () async {
      final ProgressService progress = create();
      await practice(progress, 3);
      expect(progress.todayCount, 3);

      now = DateTime(2026, 3, 11, 9);
      expect(progress.todayCount, 0);
    });

    test('hedefe ulaşan soru true döner, sonrakiler false', () async {
      final ProgressService progress = create();
      await progress.setDailyGoal(5);
      await practice(progress, 4);

      expect(await progress.recordPractice(), isTrue);
      expect(progress.goalReachedToday, isTrue);
      expect(await progress.recordPractice(), isFalse);
      expect(progress.streak, 1);
    });

    test('art arda günlerde seri artar', () async {
      final ProgressService progress = create();
      await progress.setDailyGoal(5);

      await practice(progress, 5);
      now = DateTime(2026, 3, 11, 20);
      await practice(progress, 5);
      now = DateTime(2026, 3, 12, 8);
      await practice(progress, 5);

      expect(progress.streak, 3);
      expect(progress.bestStreak, 3);
    });

    test('dün hedef tutturulduysa bugün henüz seri bozulmaz', () async {
      final ProgressService progress = create();
      await progress.setDailyGoal(5);
      await practice(progress, 5);

      now = DateTime(2026, 3, 11, 9);

      expect(progress.streak, 1);
      expect(progress.goalReachedToday, isFalse);
    });

    test('bir gün kaçırılınca seri sıfırlanır ama en iyi seri kalır', () async {
      final ProgressService progress = create();
      await progress.setDailyGoal(5);
      await practice(progress, 5);
      now = DateTime(2026, 3, 11, 9);
      await practice(progress, 5);

      now = DateTime(2026, 3, 13, 9);
      expect(progress.streak, 0);

      await practice(progress, 5);
      expect(progress.streak, 1);
      expect(progress.bestStreak, 2);
    });

    test('ay değişiminde de seri devam eder', () async {
      now = DateTime(2026, 3, 31, 22);
      final ProgressService progress = create();
      await progress.setDailyGoal(5);
      await practice(progress, 5);

      now = DateTime(2026, 4, 1, 7);
      await practice(progress, 5);

      expect(progress.streak, 2);
    });

    test('hedef düşürülünce bugünkü sayı yetiyorsa hedef tutturulur', () async {
      final ProgressService progress = create();
      await practice(progress, 6);
      expect(progress.goalReachedToday, isFalse);

      await progress.setDailyGoal(5);

      expect(progress.goalReachedToday, isTrue);
      expect(progress.streak, 1);
    });

    test('hedef ve seri kaydedilir ve geri okunur', () async {
      final ProgressService first = create();
      await first.setDailyGoal(20);
      await practice(first, 20);

      final ProgressService second = create();
      await second.load();

      expect(second.dailyGoal, 20);
      expect(second.todayCount, 20);
      expect(second.streak, 1);
    });
  });

  test('bozuk skor verisi uygulamayı çökertmez', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'bestQuizScores': '{"verbs": "bozuk"}',
    });
    final ProgressService progress = ProgressService.forTest();

    await progress.load();

    expect(progress.bestScore('verbs'), isNull);
  });

  test('JSON olmayan kayıtlı veri de uygulamayı çökertmez', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'learnedTerms': <String>['cache'],
      'reviewTerms': 'bu JSON değil',
    });
    final ProgressService progress = ProgressService.forTest();

    await progress.load();

    expect(progress.reviewCount, 0);
    expect(progress.isLearned(_term('cache')), isTrue);
  });
}
