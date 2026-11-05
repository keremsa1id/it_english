import 'package:flutter/material.dart';

import '../models/term.dart';
import '../services/term_repository.dart';
import '../services/tts_service.dart';
import '../utils/sentence_parts.dart';
import '../widgets/category_style.dart';
import '../widgets/favorite_button.dart';
import '../widgets/speak_button.dart';
import '../widgets/term_pager.dart';

/// Terimleri en az 8 kelimelik örnek cümleler içinde gösteren ekran.
/// Cümledeki terim kategori renginde ve kalın yazılır.
class SentencesScreen extends StatelessWidget {
  const SentencesScreen({super.key, this.repository = const TermRepository()});

  final TermRepository repository;

  @override
  Widget build(BuildContext context) {
    return TermPager(
      title: 'Sentences',
      repository: repository,
      cardBuilder: (BuildContext context, Term term) =>
          _SentenceCard(term: term),
      speechText: (Term term) => term.exampleSentence,
    );
  }
}

/// Tek cümlenin kartı: terim, vurgulu cümle, kısa tanım ve dinleme butonu.
class _SentenceCard extends StatelessWidget {
  const _SentenceCard({required this.term});

  final Term term;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CategoryStyle style = CategoryStyle.of(term.category);
    final TextStyle baseStyle = theme.textTheme.headlineSmall!.copyWith(
      fontSize: 28,
      height: 1.4,
      color: theme.colorScheme.onSurface,
    );
    final TextStyle termStyle = baseStyle.copyWith(
      fontWeight: FontWeight.bold,
      color: style.color,
      decoration: TextDecoration.underline,
      decorationColor: style.color,
    );

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
          const SizedBox(height: 16),
          Text(
            term.term,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: style.color,
            ),
          ),
          if (term.fullForm.isNotEmpty)
            Text(
              term.fullForm,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: style.color,
              ),
            ),
          Expanded(
            // Uzun cümle kart genişliğinde sarılır; yüksekliğe sığmazsa
            // bütün olarak küçültülür.
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: constraints.maxWidth),
                      child: Text.rich(
                        TextSpan(
                          children: <TextSpan>[
                            for (final SentencePart part in splitSentence(
                              term.exampleSentence,
                              term.term,
                            ))
                              TextSpan(
                                text: part.text,
                                style: part.isTerm ? termStyle : baseStyle,
                              ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Text(
            term.definition,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SpeakButton(
            color: style.color,
            onPressed: () => TtsService.instance.speak(term.exampleSentence),
          ),
        ],
      ),
    );
  }
}
