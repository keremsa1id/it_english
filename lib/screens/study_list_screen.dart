import 'package:flutter/material.dart';

import '../models/term.dart';
import '../services/pack_service.dart';
import '../services/progress_service.dart';
import '../services/term_repository.dart';
import '../widgets/menu_card.dart';
import 'quiz_mode_screen.dart';
import 'words_screen.dart';

/// Bütün bölümlerden ve açılmış haftalık paketlerden seçilmiş kelimelerin
/// (Review destesi, favoriler...)
/// çalışma ekranı: Words kartları ve quiz.
///
/// Hangi kelimelerin listede olduğunu [include] belirler; her açılışta
/// yeniden uygulanır.
class StudyListScreen extends StatelessWidget {
  const StudyListScreen({
    super.key,
    required this.title,
    required this.include,
    required this.description,
    required this.emptyMessage,
    required this.wordsSubtitle,
    required this.quizSubtitle,
  });

  final String title;
  final bool Function(Term term) include;

  /// Listenin üstündeki açıklama; ilerleme değişince yeniden oluşturulur.
  final String Function(ProgressService progress) description;

  /// Listede kelime yoksa quiz'de gösterilen mesaj.
  final String emptyMessage;

  final String wordsSubtitle;
  final String quizSubtitle;

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (BuildContext context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ProgressService progress = ProgressService.instance;

    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
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
                  ListenableBuilder(
                    listenable: progress,
                    builder: (BuildContext context, Widget? child) => Text(
                      description(progress),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  MenuCard(
                    title: 'Words',
                    subtitle: wordsSubtitle,
                    icon: Icons.menu_book_rounded,
                    onTap: () => _open(
                      context,
                      WordsScreen(
                        repository: FilteredTermRepository(
                          const AllTermsRepository(),
                          include: include,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  MenuCard(
                    title: 'Quiz',
                    subtitle: quizSubtitle,
                    icon: Icons.quiz_rounded,
                    onTap: () => _open(
                      context,
                      QuizModeScreen(
                        setup: QuizSetup(
                          title: '$title Quiz',
                          questionCount: 20,
                          // Yanlış şıklar bütün kelimelerden seçilsin.
                          repository: const AllTermsRepository(),
                          askOnly: include,
                          emptyMessage: emptyMessage,
                        ),
                      ),
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
