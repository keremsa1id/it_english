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

  group('aralıklı tekrar', () {
    late DateTime now;
    ProgressService create() => ProgressService.forTest(now: () => now);
    final Term term = _term('cache');

    setUp(() => now = DateTime(2026, 3, 10, 9));

    test('doğru bilinen kelime ertesi gün tekrar sorulur', () async {
      final ProgressService progress = create();
      await progress.recordAnswer(term, correct: true);

      expect(progress.isDue(term), isFalse);
      now = DateTime(2026, 3, 11, 9);
      expect(progress.isDue(term), isTrue);
      expect(progress.needsReview(term), isTrue);
      expect(progress.reviewTotal, 1);
    });

    test('takip eden tekrarlar 3, 7 ve 30 gün sonra gelir, sonra kalıcı olur',
        () async {
      final ProgressService progress = create();
      await progress.recordAnswer(term, correct: true);

      for (final int days in <int>[1, 3, 7, 30]) {
        now = now.add(Duration(days: days - 1));
        expect(progress.isDue(term), isFalse, reason: '$days günden önce');
        now = now.add(const Duration(days: 1));
        expect(progress.isDue(term), isTrue, reason: '$days gün sonra');
        await progress.recordAnswer(term, correct: true);
      }

      expect(progress.isMastered(term), isTrue);
      now = now.add(const Duration(days: 365));
      expect(progress.isDue(term), isFalse);
    });

    test('günü gelmeden verilen doğru cevap takvimi değiştirmez', () async {
      final ProgressService progress = create();
      await progress.recordAnswer(term, correct: true);
      await progress.recordAnswer(term, correct: true);

      now = DateTime(2026, 3, 11, 9);
      expect(progress.isDue(term), isTrue);
    });

    test('yanlış cevap takvimi sıfırlar ve kelime Review destesine girer',
        () async {
      final ProgressService progress = create();
      await progress.recordAnswer(term, correct: true);
      now = DateTime(2026, 3, 11, 9);

      await progress.recordAnswer(term, correct: false);

      expect(progress.isDue(term), isFalse);
      expect(progress.isInReview(term), isTrue);
      expect(progress.reviewTotal, 1);
    });

    test('takvim kaydedilir ve geri okunur', () async {
      final ProgressService first = create();
      await first.recordAnswer(term, correct: true);

      now = DateTime(2026, 3, 11, 9);
      final ProgressService second = create();
      await second.load();

      expect(second.isDue(term), isTrue);
    });
  });

  group('istatistikler', () {
    late DateTime now;
    ProgressService create() => ProgressService.forTest(now: () => now);

    setUp(() => now = DateTime(2026, 3, 10, 9));

    test('son 7 günün soru sayıları eskiden yeniye gelir', () async {
      final ProgressService progress = create();
      await progress.recordPractice();
      now = DateTime(2026, 3, 12, 9);
      await progress.recordPractice();
      await progress.recordPractice();

      final List<(DateTime, int)> days = progress.recentPractice();

      expect(days, hasLength(7));
      expect(days.last.$1, DateTime(2026, 3, 12));
      expect(days.last.$2, 2);
      expect(days[4].$1, DateTime(2026, 3, 10));
      expect(days[4].$2, 1);
      expect(days[5].$2, 0);
    });

    test('en çok yanlış yapılan kelimeler çoktan aza sıralanır', () async {
      final ProgressService progress = create();
      await progress.recordAnswer(_term('cache'), correct: false);
      await progress.recordAnswer(_term('folder'), correct: false);
      await progress.recordAnswer(_term('folder'), correct: false);

      expect(progress.mostMissed(), <(String, int)>[('folder', 2), ('cache', 1)]);
    });

    test('çalışma süresi eklenir, tek oturum 30 dakikayla sınırlanır', () async {
      final ProgressService progress = create();
      await progress.addStudyTime(const Duration(minutes: 5));
      await progress.addStudyTime(const Duration(hours: 3));

      expect(progress.studyTimeToday, const Duration(minutes: 35));
      expect(progress.studyTimeTotal, const Duration(minutes: 35));

      now = DateTime(2026, 3, 11, 9);
      expect(progress.studyTimeToday, Duration.zero);
      expect(progress.studyTimeTotal, const Duration(minutes: 35));
    });

    test('her bitirilen quiz sayılır, en iyi skor olmasa da', () async {
      final ProgressService progress = create();
      await progress.recordQuiz('verbs', 9, 10);
      await progress.recordQuiz('verbs', 2, 10);

      expect(progress.quizzesCompleted, 2);
      expect(progress.bestScore('verbs')?.score, 9);
    });

    test('istatistikler kaydedilir ve geri okunur', () async {
      final ProgressService first = create();
      await first.recordPractice();
      await first.recordAnswer(_term('cache'), correct: false);
      await first.addStudyTime(const Duration(minutes: 10));
      await first.recordQuiz('verbs', 5, 10);

      final ProgressService second = create();
      await second.load();

      expect(second.recentPractice().last.$2, 1);
      expect(second.mostMissed(), <(String, int)>[('cache', 1)]);
      expect(second.studyTimeTotal, const Duration(minutes: 10));
      expect(second.quizzesCompleted, 1);
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
