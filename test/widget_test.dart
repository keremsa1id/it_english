import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:it_english/main.dart';
import 'package:it_english/models/section.dart';
import 'package:it_english/screens/group_screen.dart';
import 'package:it_english/models/quiz_mode.dart';
import 'package:it_english/models/term.dart';
import 'package:it_english/screens/favorites_screen.dart';
import 'package:it_english/screens/quiz_mode_screen.dart';
import 'package:it_english/screens/quiz_screen.dart';
import 'package:it_english/services/progress_service.dart';
import 'package:it_english/services/term_repository.dart';
import 'package:it_english/widgets/favorite_button.dart';
import 'package:it_english/screens/review_screen.dart';
import 'package:it_english/screens/section_screen.dart';
import 'package:it_english/screens/sentences_screen.dart';
import 'package:it_english/screens/words_screen.dart';

const Term _sampleTerm = Term(
  term: 'firewall',
  category: 'security',
  definition: 'A security system that blocks unwanted network traffic.',
  exampleSentence: 'The firewall blocked a suspicious connection last night.',
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('Ana ekran bütün klasörleri gösterir', (WidgetTester tester) async {
    await tester.pumpWidget(const ItEnglishApp());

    for (final SectionGroup group in SectionGroup.all) {
      await tester.scrollUntilVisible(find.text(group.title), 100);
      expect(find.text(group.title), findsOneWidget);
    }
  });

  test('Her bölüm bir klasörde yer alır', () {
    final List<Section> grouped = <Section>[
      for (final SectionGroup group in SectionGroup.all) ...group.sections,
    ];
    expect(grouped, unorderedEquals(Section.all));
  });

  testWidgets('Klasör içindeki bölümleri, bölüm de kendi ekranını açar',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ItEnglishApp());

    await tester.scrollUntilVisible(find.text('Verbs'), 100);
    await tester.tap(find.text('Verbs'));
    await tester.pumpAndSettle();

    expect(find.byType(GroupScreen), findsOneWidget);
    expect(find.text('Verbs 1'), findsOneWidget);
    expect(find.text('Verbs 2'), findsOneWidget);

    await tester.tap(find.text('Verbs 1'));
    await tester.pumpAndSettle();

    expect(find.byType(SectionScreen), findsOneWidget);
    expect(find.text('Words'), findsOneWidget);
    expect(find.text('Sentences'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
  });

  testWidgets('Advanced IT klasörü iki bölümünü gösterir',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ItEnglishApp());

    await tester.scrollUntilVisible(find.text('Advanced IT'), 100);
    await tester.tap(find.text('Advanced IT'));
    await tester.pumpAndSettle();

    expect(find.byType(GroupScreen), findsOneWidget);
    expect(find.text('Advanced IT 1'), findsOneWidget);
    expect(find.text('Advanced IT 2'), findsOneWidget);
  });

  testWidgets('Review kartı Review ekranını açar', (WidgetTester tester) async {
    await tester.pumpWidget(const ItEnglishApp());

    await tester.scrollUntilVisible(find.text('Review'), 100);
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    expect(find.byType(ReviewScreen), findsOneWidget);
    expect(find.text('Words'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
  });

  testWidgets('Daily Goal kartı hedef seçme penceresini açar',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ItEnglishApp());

    await tester.tap(find.text('Daily Goal'));
    await tester.pumpAndSettle();

    for (final int goal in ProgressService.dailyGoalOptions) {
      expect(find.text('$goal questions a day'), findsOneWidget);
    }
  });

  testWidgets('Favorites kartı Favorites ekranını açar',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ItEnglishApp());

    await tester.scrollUntilVisible(find.text('Favorites'), 100);
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();

    expect(find.byType(FavoritesScreen), findsOneWidget);
    expect(find.text('Words'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
  });

  testWidgets('Kelime kartındaki yıldız kelimeyi favorilere ekler',
      (WidgetTester tester) async {
    // Ayrı örnek: diğer testleri etkilemez. Yükleme de testin içinde
    // (aynı sahte zamanda) yapılır ki yıldıza basınca kayıt hemen bitsin.
    final ProgressService progress = ProgressService.forTest();
    await progress.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FavoriteButton(term: _sampleTerm, progress: progress),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.star_outline_rounded));
    await tester.pumpAndSettle();

    expect(progress.isFavorite(_sampleTerm), isTrue);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });

  testWidgets('Mixed Quiz kartı tür seçme ekranını açar',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ItEnglishApp());

    await tester.scrollUntilVisible(find.text('Mixed Quiz'), 100);
    await tester.tap(find.text('Mixed Quiz'));
    await tester.pumpAndSettle();

    expect(find.byType(QuizModeScreen), findsOneWidget);
  });

  for (final QuizMode mode in QuizMode.values) {
    testWidgets('"${mode.title}" kartı o türde quiz açar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizModeScreen(
            setup: QuizSetup(
              title: 'Test Quiz',
              repository: TermRepository(assetPath: Section.all.first.assetPath),
            ),
          ),
        ),
      );

      await tester.tap(find.text(mode.title));
      // Yükleme göstergesi sürekli döndüğü için pumpAndSettle kullanılmıyor.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final QuizScreen quiz = tester.widget(find.byType(QuizScreen));
      expect(quiz.mode, mode);
    });
  }

  for (final (String label, Type screen) in <(String, Type)>[
    ('Words', WordsScreen),
    ('Sentences', SentencesScreen),
    ('Quiz', QuizModeScreen),
  ]) {
    testWidgets('$label kartı kendi ekranını açar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: SectionScreen(section: Section.all.first)),
      );

      await tester.tap(find.text(label));
      // Yükleme göstergesi sürekli döndüğü için pumpAndSettle kullanılmıyor.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(screen), findsOneWidget);
    });
  }
}
