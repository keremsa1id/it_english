import 'package:flutter/material.dart';

import '../models/term.dart';
import '../services/term_repository.dart';
import '../services/tts_service.dart';
import '../widgets/category_style.dart';
import '../widgets/favorite_button.dart';
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
/// Terime dokununca Türkçe karşılığı açılır, tekrar dokununca kapanır.
class _WordCard extends StatefulWidget {
  const _WordCard({required this.term});

  final Term term;

  @override
  State<_WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<_WordCard> {
  bool _showTurkish = false;

  @override
  Widget build(BuildContext context) {
    final Term term = widget.term;
    final ThemeData theme = Theme.of(context);
    final CategoryStyle style = CategoryStyle.of(term.category);
    final bool hasTurkish = term.turkish.isNotEmpty;

    return TermCardFrame(
      color: style.color,
      child: Column(
        children: [
          // Kategori ortada, yıldız sağ üstte.
          Stack(
            alignment: Alignment.center,
            children: [
              CategoryChip(category: term.category),
              Align(
                alignment: Alignment.centerRight,
                child: FavoriteButton(term: term),
              ),
            ],
          ),
          Expanded(
            // Kısa ekranlarda tanım taşmasın, kaydırılabilsin.
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: hasTurkish
                          ? () => setState(() => _showTurkish = !_showTurkish)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: FittedBox(
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
                      ),
                    ),
                    if (term.fullForm.isNotEmpty)
                      Text(
                        term.fullForm,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: style.color,
                        ),
                      ),
                    if (hasTurkish) ...[
                      const SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _showTurkish
                            ? Text(
                                term.turkish,
                                key: const ValueKey<bool>(true),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              )
                            : Text(
                                'Tap the word to see Turkish',
                                key: const ValueKey<bool>(false),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                    ],
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
