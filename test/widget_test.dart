import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:it_english/main.dart';
import 'package:it_english/models/section.dart';
import 'package:it_english/screens/quiz_screen.dart';
import 'package:it_english/screens/section_screen.dart';
import 'package:it_english/screens/sentences_screen.dart';
import 'package:it_english/screens/words_screen.dart';

void main() {
  testWidgets('Ana ekran bütün bölümleri gösterir', (WidgetTester tester) async {
    await tester.pumpWidget(const ItEnglishApp());

    for (final Section section in Section.all) {
      await tester.scrollUntilVisible(find.text(section.title), 100);
      expect(find.text(section.title), findsOneWidget);
    }
  });

  testWidgets('Bölüm kartı bölüm ekranını açar', (WidgetTester tester) async {
    await tester.pumpWidget(const ItEnglishApp());

    await tester.tap(find.text('Verbs 1'));
    await tester.pumpAndSettle();

    expect(find.byType(SectionScreen), findsOneWidget);
    expect(find.text('Words'), findsOneWidget);
    expect(find.text('Sentences'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
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
