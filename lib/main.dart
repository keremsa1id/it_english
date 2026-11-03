import 'package:flutter/material.dart';

import 'models/section.dart';
import 'screens/group_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/section_screen.dart';
import 'services/term_repository.dart';
import 'widgets/menu_card.dart';
import 'widgets/section_icon.dart';

void main() {
  runApp(const ItEnglishApp());
}

class ItEnglishApp extends StatelessWidget {
  const ItEnglishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IT English',
      // Siyah zemin, kırmızı vurgular.
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD32F2F),
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFFE53935),
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFF3A0D0D),
          onPrimaryContainer: Colors.white,
          surface: Colors.black,
          onSurface: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

/// Karışık quiz'i ve klasörleri (IT Terms, Verbs, Nouns...) listeleyen ana
/// ekran.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (BuildContext context) => screen),
    );
  }

  /// Bütün bölümlerin kelimelerinden rastgele sorular soran quiz.
  void _openMixedQuiz(BuildContext context) {
    _open(
      context,
      QuizScreen(
        title: 'Mixed Quiz',
        questionCount: 25,
        repository: MixedTermRepository(<String>[
          for (final Section section in Section.all) section.assetPath,
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.terminal_rounded,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'IT English',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Learn IT terms and the most common English words.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),
                  MenuCard(
                    title: 'Mixed Quiz',
                    subtitle: 'Random questions from every section',
                    icon: Icons.shuffle_rounded,
                    onTap: () => _openMixedQuiz(context),
                  ),
                  const SizedBox(height: 16),
                  for (final SectionGroup group in SectionGroup.all) ...[
                    MenuCard(
                      title: group.title,
                      subtitle: group.subtitle,
                      icon: sectionIcon(group.kind),
                      // Tek bölümlü klasör doğrudan bölümü açar.
                      onTap: () => _open(
                        context,
                        group.sections.length == 1
                            ? SectionScreen(section: group.sections.single)
                            : GroupScreen(group: group),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
