import 'package:flutter/material.dart';

import '../models/quiz_mode.dart';
import '../models/term.dart';
import '../services/term_repository.dart';
import '../widgets/menu_card.dart';
import 'quiz_screen.dart';

/// Bir quiz'in hangi kelimelerle, kaç soruyla oynanacağı. Tür seçme
/// ekranı her tür için [QuizScreen]'i bununla oluşturur.
class QuizSetup {
  const QuizSetup({
    required this.title,
    required this.repository,
    this.quizId,
    this.questionCount = 10,
    this.askOnly,
    this.emptyMessage = 'There are not enough words for a quiz.',
  });

  final String title;
  final TermRepository repository;

  /// Verilirse skorlar her tür için ayrı anahtarla kaydedilir
  /// (bkz. [QuizMode.scoreId]).
  final String? quizId;

  final int questionCount;
  final bool Function(Term term)? askOnly;
  final String emptyMessage;

  QuizScreen buildQuiz(QuizMode mode) {
    final String? id = quizId;
    return QuizScreen(
      title: mode.title,
      mode: mode,
      repository: repository,
      quizId: id == null ? null : mode.scoreId(id),
      questionCount: questionCount,
      askOnly: askOnly,
      emptyMessage: emptyMessage,
    );
  }
}

/// Quiz türünü (boşluk doldurma, tanımdan bulma...) seçtiren ekran.
class QuizModeScreen extends StatelessWidget {
  const QuizModeScreen({super.key, required this.setup});

  final QuizSetup setup;

  static IconData _iconOf(QuizMode mode) => switch (mode) {
        QuizMode.fillBlank => Icons.edit_note_rounded,
        QuizMode.definition => Icons.menu_book_rounded,
        QuizMode.listening => Icons.headphones_rounded,
        QuizMode.typing => Icons.keyboard_rounded,
        QuizMode.speaking => Icons.mic_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(setup.title), centerTitle: true),
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
                  for (final QuizMode mode in QuizMode.values) ...[
                    MenuCard(
                      title: mode.title,
                      subtitle: mode.subtitle,
                      icon: _iconOf(mode),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) =>
                              setup.buildQuiz(mode),
                        ),
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
