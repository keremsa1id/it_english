import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:it_english/main.dart';
import 'package:it_english/models/term.dart';
import 'package:it_english/screens/todays_words_screen.dart';
import 'package:it_english/services/daily_words.dart';
import 'package:it_english/services/progress_service.dart';
import 'package:it_english/services/term_repository.dart';

/// Dosya okumadan sabit kelimeler döndüren depo.
class _FakeRepository extends TermRepository {
  const _FakeRepository(this.terms);

  final List<Term> terms;

  @override
  Future<List<Term>> loadTerms() async => terms;
}

Term _term(String term) => Term(
      term: term,
      category: 'data',
      definition: 'Definition of $term.',
      exampleSentence: 'This long example sentence uses the $term word.',
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  final List<Term> terms =
      List<Term>.generate(40, (int i) => _term('word${i.toString().padLeft(2, '0')}'));

  group('pickDailyWords', () {
    test('aynı gün aynı seti, farklı gün farklı seti verir', () {
      List<String> pick(DateTime day) => pickDailyWords(
            terms: terms,
            isLearned: (Term t) => false,
            day: day,
          );

      expect(pick(DateTime(2026, 11, 5)), pick(DateTime(2026, 11, 5)));
      expect(pick(DateTime(2026, 11, 5)), isNot(pick(DateTime(2026, 11, 6))));
      expect(pick(DateTime(2026, 11, 5)), hasLength(10));
    });

    test('kelimelerin okunma sırası sonucu değiştirmez', () {
      final DateTime day = DateTime(2026, 11, 5);
      expect(
        pickDailyWords(terms: terms, isLearned: (Term t) => false, day: day),
        pickDailyWords(
          terms: terms.reversed.toList(),
          isLearned: (Term t) => false,
          day: day,
        ),
      );
    });

    test('öğrenilmemiş kelimeler önce gelir, yetmezse öğrenilmişlerle '
        'tamamlanır', () {
      // Yalnızca 3 kelime öğrenilmemiş.
      final Set<String> unlearned = <String>{'word00', 'word01', 'word02'};
      final List<String> picked = pickDailyWords(
        terms: terms,
        isLearned: (Term t) => !unlearned.contains(t.term),
        day: DateTime(2026, 11, 5),
      );

      expect(picked.take(3).toSet(), unlearned);
      expect(picked, hasLength(10));
    });

    test('kelime azsa olanların hepsini verir', () {
      expect(
        pickDailyWords(
          terms: terms.take(4).toList(),
          isLearned: (Term t) => false,
          day: DateTime(2026, 11, 5),
        ),
        hasLength(4),
      );
    });
  });

  group('DailyWordsService', () {
    test('set gün boyu sabit kalır, kelimeler öğrenilse bile', () async {
      DateTime now = DateTime(2026, 11, 5, 9);
      final ProgressService progress = ProgressService.forTest(now: () => now);
      final DailyWordsService service = DailyWordsService.forTest(
        progress: progress,
        source: _FakeRepository(terms),
      );

      final List<String> first = await service.ensureToday();
      await progress.setLearned(_term(first.first), learned: true);
      now = DateTime(2026, 11, 5, 22);

      expect(await service.ensureToday(), first);
      expect(service.isTodayWord(_term(first.first)), isTrue);
    });

    test('ertesi gün yeni bir set seçilir', () async {
      DateTime now = DateTime(2026, 11, 5, 9);
      final ProgressService progress = ProgressService.forTest(now: () => now);
      final DailyWordsService service = DailyWordsService.forTest(
        progress: progress,
        source: _FakeRepository(terms),
      );
      final List<String> first = await service.ensureToday();

      now = DateTime(2026, 11, 6, 9);

      expect(progress.todayWordKeys, isEmpty);
      expect(await service.ensureToday(), isNot(first));
    });

    test('seçilen set kaydedilir ve uygulama yeniden açılınca aynısı gelir',
        () async {
      final DateTime now = DateTime(2026, 11, 5, 9);
      final ProgressService first = ProgressService.forTest(now: () => now);
      final List<String> picked = await DailyWordsService.forTest(
        progress: first,
        source: _FakeRepository(terms),
      ).ensureToday();

      final ProgressService second = ProgressService.forTest(now: () => now);
      await second.load();

      expect(second.todayWordKeys, picked);
    });
  });

  testWidgets("Daily Goal kartındaki buton Today's Words ekranını açar",
      (WidgetTester tester) async {
    await tester.pumpWidget(const ItEnglishApp());

    await tester.tap(find.text("Today's words"));
    // Kelimeler yüklenirken gösterge döndüğü için pumpAndSettle kullanılmıyor.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(TodaysWordsScreen), findsOneWidget);
  });
}
