import 'package:flutter/material.dart';

import '../models/term.dart';
import '../services/tts_service.dart';
import '../utils/sentence_parts.dart';
import '../widgets/category_style.dart';
import '../widgets/favorite_button.dart';
import '../widgets/speak_button.dart';

/// Tek bir kelimenin bütün bilgileri: Türkçesi, açılımı, tanımı ve örnek
/// cümlesi. Aramadan açılır.
class WordDetailScreen extends StatelessWidget {
  const WordDetailScreen({super.key, required this.term, this.sectionTitle});

  final Term term;

  /// Kelimenin bulunduğu bölüm, ör. "IT Terms 1".
  final String? sectionTitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CategoryStyle style = CategoryStyle.of(term.category);
    final TextStyle sentenceStyle = theme.textTheme.titleLarge!.copyWith(
      height: 1.4,
      color: theme.colorScheme.onSurface,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(sectionTitle ?? 'Word'),
        centerTitle: true,
        actions: [FavoriteButton(term: term)],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  CategoryChip(category: term.category),
                  const SizedBox(height: 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      term.term,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: style.color,
                      ),
                    ),
                  ),
                  if (term.fullForm.isNotEmpty)
                    Text(
                      term.fullForm,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: style.color),
                    ),
                  if (term.turkish.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      term.turkish,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SpeakButton(
                    color: style.color,
                    onPressed: () => TtsService.instance.speak(term.term),
                  ),
                  const SizedBox(height: 28),
                  const _Label('DEFINITION'),
                  const SizedBox(height: 8),
                  Text(
                    term.definition,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 28),
                  const _Label('EXAMPLE'),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        for (final SentencePart part
                            in splitSentence(term.exampleSentence, term.term))
                          TextSpan(
                            text: part.text,
                            style: part.isTerm
                                ? sentenceStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: style.color,
                                  )
                                : sentenceStyle,
                          ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () =>
                        TtsService.instance.speak(term.exampleSentence),
                    icon: const Icon(Icons.volume_up_rounded),
                    label: const Text('Listen to the sentence'),
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

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1.5,
      ),
    );
  }
}
