import 'package:flutter/material.dart';

import '../models/section.dart';
import '../models/term.dart';
import '../services/progress_service.dart';
import '../services/term_repository.dart';

/// Menü kartlarının altındaki ilerleme çubuğu: "28 / 40 learned".
///
/// Kelimeler [sections] bölümlerinin dosyalarından ve [repositories]
/// depolarından (ör. haftalık paketler) toplanır. [quizId] verilirse o
/// quiz'in en iyi skoru da yazılır. İlerleme değişince kendiliğinden
/// güncellenir.
class ProgressFooter extends StatefulWidget {
  const ProgressFooter({
    super.key,
    this.sections = const <Section>[],
    this.repositories = const <TermRepository>[],
    this.quizId,
  });

  final List<Section> sections;
  final List<TermRepository> repositories;
  final String? quizId;

  @override
  State<ProgressFooter> createState() => _ProgressFooterState();
}

class _ProgressFooterState extends State<ProgressFooter> {
  late final Future<List<Term>> _termsFuture = _loadTerms();

  Future<List<Term>> _loadTerms() async {
    final List<List<Term>> lists = await Future.wait(<Future<List<Term>>>[
      for (final Section section in widget.sections)
        TermRepository(assetPath: section.assetPath).loadTerms(),
      for (final TermRepository repository in widget.repositories)
        repository.loadTerms(),
    ]);
    return <Term>[for (final List<Term> list in lists) ...list];
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = theme.colorScheme.onPrimaryContainer;

    return FutureBuilder<List<Term>>(
      future: _termsFuture,
      builder: (BuildContext context, AsyncSnapshot<List<Term>> snapshot) {
        // Yüklenirken veya hata olursa kart ilerlemesiz görünür.
        final List<Term>? terms = snapshot.data;
        if (terms == null || terms.isEmpty) {
          return const SizedBox.shrink();
        }

        return ListenableBuilder(
          listenable: ProgressService.instance,
          builder: (BuildContext context, Widget? child) {
            final ProgressService progress = ProgressService.instance;
            final int learned = progress.learnedCount(terms);
            final String? quizId = widget.quizId;
            final QuizScore? best =
                quizId == null ? null : progress.bestScore(quizId);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: learned / terms.length,
                    minHeight: 6,
                    backgroundColor: color.withValues(alpha: 0.15),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$learned / ${terms.length} learned'
                  '${best == null ? '' : '  ·  Best quiz: ${best.score}/${best.total}'}',
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
