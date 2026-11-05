import 'package:flutter/material.dart';

import '../services/progress_service.dart';
import 'study_list_screen.dart';

/// Tekrar edilmesi gereken kelimelerin çalışma ekranı: quiz'de yanlış
/// bilinenler ve aralıklı tekrar günü gelenler.
///
/// Yanlış bilinen kelime art arda [ProgressService.reviewCorrectNeeded] kez
/// ilk denemede doğru bilinince desteden çıkar. Doğru bilinen kelimeler
/// [ProgressService.repetitionDays] günlerinde yeniden buraya düşer.
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  static const String _emptyMessage =
      'Nothing to review today. Words you get wrong, and words that are due '
      'for repetition, will appear here.';

  static String _describe(ProgressService progress) {
    final int total = progress.reviewTotal;
    if (total == 0) {
      return _emptyMessage;
    }
    final List<String> parts = <String>[
      if (progress.reviewCount > 0) '${progress.reviewCount} answered wrong',
      if (progress.dueCount > 0) '${progress.dueCount} due for repetition',
    ];
    final String days = ProgressService.repetitionDays.join(', ');
    return '$total words to review (${parts.join(', ')}). '
        'Words you know come back after $days days.';
  }

  @override
  Widget build(BuildContext context) {
    return StudyListScreen(
      title: 'Review',
      include: ProgressService.instance.needsReview,
      description: _describe,
      emptyMessage: _emptyMessage,
      wordsSubtitle: 'Study the words you need to repeat',
      quizSubtitle: 'Practice only the words you need to repeat',
    );
  }
}
