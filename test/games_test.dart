import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:it_english/models/term.dart';
import 'package:it_english/screens/matching_screen.dart';
import 'package:it_english/screens/sentence_builder_screen.dart';
import 'package:it_english/services/term_repository.dart';

/// Dosya okumadan sabit kelimeler döndüren depo.
class _FakeRepository extends TermRepository {
  const _FakeRepository(this.terms);

  final List<Term> terms;

  @override
  Future<List<Term>> loadTerms() async => terms;
}

Term _term(String term, String turkish, {String? sentence}) => Term(
      term: term,
      turkish: turkish,
      category: 'noun',
      definition: 'Definition of $term.',
      exampleSentence: sentence ?? 'This long example sentence uses the $term word.',
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  final List<Term> sixTerms = <Term>[
    _term('cache', 'önbellek'),
    _term('folder', 'klasör'),
    _term('printer', 'yazıcı'),
    _term('router', 'yönlendirici'),
    _term('server', 'sunucu'),
    _term('mouse', 'fare'),
  ];

  group('Match the Words', () {
    testWidgets('bütün çiftler eşleşince tur tamamlanır',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: MatchingScreen(repository: _FakeRepository(sixTerms))),
      );
      await tester.pump();

      for (final Term term in sixTerms) {
        await tester.tap(find.text(term.term));
        await tester.pump();
        await tester.tap(find.text(term.turkish));
        await tester.pump();
      }

      expect(find.text('Round complete!'), findsOneWidget);
      expect(find.textContaining('Mistakes: 0'), findsOneWidget);
    });

    testWidgets('yanlış eşleştirme hata sayısını artırır',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: MatchingScreen(repository: _FakeRepository(sixTerms))),
      );
      await tester.pump();

      await tester.tap(find.text('cache'));
      await tester.pump();
      await tester.tap(find.text('klasör'));
      await tester.pump();

      expect(find.textContaining('Mistakes: 1'), findsOneWidget);
      // Turuncu uyarının kalkmasını bekle (bekleyen zamanlayıcı kalmasın).
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('aynı Türkçe karşılık aynı turda iki kez çıkmaz',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MatchingScreen(
            repository: _FakeRepository(<Term>[
              _term('rather', 'oldukça'),
              _term('fairly', 'oldukça'),
              _term('quite', 'oldukça'),
              ...sixTerms,
            ]),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('oldukça'), findsAtMostNWidgets(1));
    });

    testWidgets('ikiden az kelime varsa oyun başlamaz',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MatchingScreen(
            repository: _FakeRepository(<Term>[sixTerms.first]),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('There are not enough words to play.'), findsOneWidget);
    });
  });

  group('Build the Sentence', () {
    const String sentence =
        'The firewall blocked a suspicious connection last night.';
    final List<String> words = sentence.split(' ');

    Future<void> pumpBuilder(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SentenceBuilderScreen(
            repository: _FakeRepository(<Term>[
              _term('firewall', 'güvenlik duvarı', sentence: sentence),
            ]),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('kelimeler doğru sıraya dizilince doğru sayılır',
        (WidgetTester tester) async {
      await pumpBuilder(tester);

      for (final String word in words) {
        await tester.tap(find.text(word));
        await tester.pump();
      }
      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(find.text('Correct!'), findsOneWidget);

      await tester.tap(find.text('See results'));
      await tester.pump();
      expect(find.text('1 / 1 correct on the first try'), findsOneWidget);
    });

    testWidgets('yanlış sıra uyarı verir ve sonradan düzeltmek puan getirmez',
        (WidgetTester tester) async {
      await pumpBuilder(tester);

      // İlk iki kelimenin yeri değişik.
      for (final String word in <String>[words[1], words[0], ...words.skip(2)]) {
        await tester.tap(find.text(word));
        await tester.pump();
      }
      await tester.tap(find.text('Check'));
      await tester.pump();
      expect(find.textContaining('Not quite'), findsOneWidget);

      // Bütün kelimeleri geri alıp doğru sırayla diz.
      for (final String word in words) {
        await tester.tap(find.text(word));
        await tester.pump();
      }
      for (final String word in words) {
        await tester.tap(find.text(word));
        await tester.pump();
      }
      await tester.tap(find.text('Check'));
      await tester.pump();
      expect(find.text('Correct!'), findsOneWidget);

      await tester.tap(find.text('See results'));
      await tester.pump();
      expect(find.text('0 / 1 correct on the first try'), findsOneWidget);
    });
  });
}
