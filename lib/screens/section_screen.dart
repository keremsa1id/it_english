import 'package:flutter/material.dart';

import '../models/section.dart';
import '../services/term_repository.dart';
import '../widgets/menu_card.dart';
import '../widgets/progress_footer.dart';
import 'quiz_mode_screen.dart';
import 'sentences_screen.dart';
import 'words_screen.dart';

/// Seçilen bölümün üç çalışma şeklini (Words, Sentences, Quiz) gösterir.
class SectionScreen extends StatelessWidget {
  const SectionScreen({super.key, required this.section});

  final Section section;

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (BuildContext context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TermRepository repository =
        TermRepository(assetPath: section.assetPath);

    return Scaffold(
      appBar: AppBar(title: Text(section.title), centerTitle: true),
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
                  MenuCard(
                    title: 'Words',
                    subtitle: 'Each word with a simple English definition',
                    icon: Icons.menu_book_rounded,
                    onTap: () =>
                        _open(context, WordsScreen(repository: repository)),
                  ),
                  const SizedBox(height: 16),
                  MenuCard(
                    title: 'Sentences',
                    subtitle: 'See each word used in a real sentence',
                    icon: Icons.notes_rounded,
                    onTap: () =>
                        _open(context, SentencesScreen(repository: repository)),
                  ),
                  const SizedBox(height: 16),
                  MenuCard(
                    title: 'Quiz',
                    subtitle: 'Test yourself in different ways',
                    icon: Icons.quiz_rounded,
                    onTap: () => _open(
                      context,
                      QuizModeScreen(
                        setup: QuizSetup(
                          title: '${section.title} Quiz',
                          repository: repository,
                          quizId: section.assetPath,
                        ),
                      ),
                    ),
                    footer: ProgressFooter(
                      sections: <Section>[section],
                      quizId: section.assetPath,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
