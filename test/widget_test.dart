import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:it_english/main.dart';
import 'package:it_english/models/section.dart';
import 'package:it_english/screens/group_screen.dart';
import 'package:it_english/models/quiz_mode.dart';
import 'package:it_english/models/term.dart';
import 'package:it_english/screens/cyber_screen.dart';
import 'package:it_english/screens/favorites_screen.dart';
import 'package:it_english/screens/quiz_mode_screen.dart';
import 'package:it_english/screens/quiz_screen.dart';
import 'package:it_english/services/progress_service.dart';
import 'package:it_english/services/term_repository.dart';
import 'package:it_english/widgets/favorite_button.dart';
import 'package:it_english/widgets/locked_card.dart';
import 'package:it_english/screens/review_screen.dart';
import 'package:it_english/screens/section_screen.dart';
import 'package:it_english/screens/search_screen.dart';
import 'package:it_english/screens/sentences_screen.dart';
import 'package:it_english/screens/statistics_screen.dart';
import 'package:it_english/screens/weekly_screen.dart';
import 'package:it_english/screens/word_groups_screen.dart';
import 'package:it_english/screens/words_screen.dart';

const Term _sampleTerm = Term(
  term: 'firewall',
  category: 'security',
  definition: 'A security system that blocks unwanted network traffic.',
  exampleSentence: 'The firewall blocked a suspicious connection last night.',
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('Ana ekranda altı kart var, klasörler orada değil',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ItEnglishApp());

    for (final String title in <String>[
      'Daily Goal',
      'Word Groups',
      'Mixed Quiz',
      'Weekly Words',
      'Review',
      'Favorites',
    ]) {
      await tester.scrollUntilVisible(find.text(title), 100);
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Verbs'), findsNothing);
  });

  testWidgets('Sağ üstteki simge istatistik ekranını açar',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ItEnglishApp());

    await tester.tap(find.byTooltip('Statistics'));
    // Ses seçimi cihazdaki sesleri yüklerken gösterge döndüğü için
    // (testte seslendirme motoru yok) pumpAndSettle kullanılmıyor. Ses
    // listesinin yeniden denemeleri (4 × 300 ms) bitsin diye 2 sn beklenir.
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(StatisticsScreen), findsOneWidget);
    expect(find.text('LAST 7 DAYS'), findsOneWidget);
  });

  testWidgets('Sağ üstteki simge arama ekranını açar',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ItEnglishApp());

    await tester.tap(find.byTooltip('Search'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SearchScreen), findsOneWidget);
  });

  testWidgets('Word Groups kartı bütün klasörleri gösterir',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ItEnglishApp());

    await tester.scrollUntilVisible(find.text('Word Groups'), 100);
    await tester.tap(find.text('Word Groups'));
    await tester.pumpAndSettle();

    expect(find.byType(WordGroupsScreen), findsOneWidget);
    for (final SectionGroup group in SectionGroup.menu) {
      await tester.scrollUntilVisible(find.text(group.title), 100);
      expect(find.text(group.title), findsOneWidget);
    }
    // Cyber alt grupları ayrı kart değil, tek "Cyber" kartının içindedir.
    await tester.scrollUntilVisible(find.text(CyberScreen.title), 100);
    expect(find.text(CyberScreen.title), findsOneWidget);
    expect(find.text('Cyber Basics'), findsNothing);
  });

  testWidgets('Cyber klasörü 5 alt grubu, alt grup da 2 bölümü gösterir',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: WordGroupsScreen()));

    await tester.scrollUntilVisible(find.text(CyberScreen.title), 100);
    await tester.tap(find.text(CyberScreen.title));
    await tester.pumpAndSettle();

    expect(find.byType(CyberScreen), findsOneWidget);
    expect(SectionGroup.cyberGroups, hasLength(5));
    for (final SectionGroup group in SectionGroup.cyberGroups) {
      expect(group.sections, hasLength(2));
      await tester.scrollUntilVisible(find.text(group.title), 100);
      expect(find.text(group.title), findsOneWidget);
    }

    // Döngüde aşağı kaydırdığımız için "Cyber Basics" ekrandan çıkmış
    // olabilir; tıklamadan önce tekrar görünür yap.
    await tester.scrollUntilVisible(find.text('Cyber Basics'), 100);
    await tester.tap(find.text('Cyber Basics'));
    await tester.pumpAndSettle();

    expect(find.byType(GroupScreen), findsOneWidget);
    expect(find.text('Cyber Basics 1'), findsOneWidget);
    expect(find.text('Cyber Basics 2'), findsOneWidget);
  });

  test('Her bölüm bir klasörde yer alır', () {
    final List<Section> grouped = <Section>[
      for (final SectionGroup group in SectionGroup.all) ...group.sections,
    ];
    expect(grouped, unorderedEquals(Section.all));
  });

  testWidgets('Klasör içindeki bölümleri, bölüm de kendi ekranını açar',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: WordGroupsScreen()));

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
    await tester.pumpWidget(const MaterialApp(home: WordGroupsScreen()));

    await tester.scrollUntilVisible(find.text('Advanced IT'), 100);
    await tester.tap(find.text('Advanced IT'));
    await tester.pumpAndSettle();

    expect(find.byType(GroupScreen), findsOneWidget);
    expect(find.text('Advanced IT 1'), findsOneWidget);
    expect(find.text('Advanced IT 2'), findsOneWidget);
  });

  testWidgets('Kilitli bölüm açılmaz, nasıl açılacağını söyler',
      (WidgetTester tester) async {
    // Hiç quiz bitirilmedi: Adverbs 2 ve 3 kilitli.
    final SectionGroup adverbs = SectionGroup.all
        .firstWhere((SectionGroup group) => group.title == 'Adverbs');
    await tester.pumpWidget(MaterialApp(home: GroupScreen(group: adverbs)));

    expect(find.byType(LockedCard), findsNWidgets(2));

    await tester.tap(find.text('Adverbs 2'));
    await tester.pump();

    expect(find.byType(SectionScreen), findsNothing);
    expect(
      find.text('Finish any quiz in Adverbs 1 to unlock this section.'),
      findsOneWidget,
    );
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

    // Kartların sırası değişebilir; önce görünür yap.
    await tester.scrollUntilVisible(find.text('Daily Goal'), 100);
    await tester.tap(find.text('Daily Goal'));
    await tester.pumpAndSettle();

    for (final int goal in ProgressService.dailyGoalOptions) {
      expect(find.text('$goal questions a day'), findsOneWidget);
    }
  });

  testWidgets('Weekly Words kartı haftalık paketler ekranını açar',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ItEnglishApp());

    await tester.scrollUntilVisible(find.text('Weekly Words'), 100);
    await tester.tap(find.text('Weekly Words'));
    // Yükleme göstergesi sürekli döndüğü için pumpAndSettle kullanılmıyor.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(WeeklyScreen), findsOneWidget);
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

      // Kartlar küçük test ekranına sığmayabilir; önce görünür yap.
      await tester.ensureVisible(find.text(mode.title));
      await tester.pumpAndSettle();
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
