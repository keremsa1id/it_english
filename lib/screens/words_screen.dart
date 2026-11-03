import 'package:flutter/material.dart';

import '../models/term.dart';
import '../services/term_repository.dart';
import '../services/tts_service.dart';
import '../widgets/category_style.dart';
import '../widgets/speak_button.dart';
import '../widgets/term_pager.dart';

/// Terimleri İngilizce tanımlarıyla gösteren ekran (İngilizceden İngilizceye).
class WordsScreen extends StatelessWidget {
  const WordsScreen({super.key, this.repository = const TermRepository()});

  final TermRepository repository;

  @override
  Widget build(BuildContext context) {
    return TermPager(
      title: 'Words',
      repository: repository,
      cardBuilder: (BuildContext context, Term term) => _WordCard(term: term),
    );
  }
}

/// Tek terimin kartı: kategori, terim, tanım ve dinleme butonu.
class _WordCard extends StatelessWidget {
  const _WordCard({required this.term});

  final Term term;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CategoryStyle style = CategoryStyle.of(term.category);

    return TermCardFrame(
      color: style.color,
      child: Column(
        children: [
          CategoryChip(category: term.category),
          Expanded(
            // Kısa ekranlarda tanım taşmasın, kaydırılabilsin.
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        term.term,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: style.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SpeakButton(
                      color: style.color,
                      onPressed: () => TtsService.instance.speak(term.term),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'DEFINITION',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      term.definition,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
