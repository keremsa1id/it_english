import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:it_english/main.dart';
import 'package:it_english/models/section.dart';
import 'package:it_english/screens/group_screen.dart';
import 'package:it_english/screens/quiz_screen.dart';
import 'package:it_english/screens/section_screen.dart';
import 'package:it_english/screens/sentences_screen.dart';
import 'package:it_english/screens/words_screen.dart';

void main() {
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

  testWidgets('Tek bölümlü klasör doğrudan bölümü açar',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ItEnglishApp());

    await tester.scrollUntilVisible(find.text('Advanced IT'), 100);
    await tester.tap(find.text('Advanced IT'));
    await tester.pumpAndSettle();

    expect(find.byType(GroupScreen), findsNothing);
    expect(find.byType(SectionScreen), findsOneWidget);
  });

  testWidgets('Mixed Quiz kartı quiz ekranını açar', (WidgetTester tester) async {
    await tester.pumpWidget(const ItEnglishApp());

    await tester.tap(find.text('Mixed Quiz'));
    // Yükleme göstergesi sürekli döndüğü için pumpAndSettle kullanılmıyor.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(QuizScreen), findsOneWidget);
  });

  for (final (String label, Type screen) in <(String, Type)>[
    ('Words', WordsScreen),
    ('Sentences', SentencesScreen),
    ('Quiz', QuizScreen),
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
