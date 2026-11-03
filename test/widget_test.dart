import 'package:flutter_test/flutter_test.dart';

import 'package:it_english/main.dart';
import 'package:it_english/screens/quiz_screen.dart';
import 'package:it_english/screens/sentences_screen.dart';
import 'package:it_english/screens/words_screen.dart';

void main() {
  testWidgets('Ana ekran üç bölümü gösterir', (WidgetTester tester) async {
    await tester.pumpWidget(const ItEnglishApp());

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
      await tester.pumpWidget(const ItEnglishApp());

      await tester.tap(find.text(label));
      // Yükleme göstergesi sürekli döndüğü için pumpAndSettle kullanılmıyor.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(screen), findsOneWidget);
    });
  }
}
