import 'package:flutter/material.dart';

import '../services/progress_service.dart';
import 'study_list_screen.dart';

/// Quiz'de yanlış bilinen kelimelerin (Review destesi) çalışma ekranı.
///
/// Bir kelime art arda [ProgressService.reviewCorrectNeeded] kez ilk
/// denemede doğru bilinince desteden çıkar.
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  static const String _emptyMessage =
      'Nothing to review. Words you get wrong in a quiz will appear here.';

  @override
  Widget build(BuildContext context) {
    return StudyListScreen(
      title: 'Review',
      include: ProgressService.instance.isInReview,
      description: (ProgressService progress) => progress.reviewCount == 0
          ? _emptyMessage
          : '${progress.reviewCount} words to review. '
              'Answer a word correctly '
              '${ProgressService.reviewCorrectNeeded} times '
              'in a row to remove it.',
      emptyMessage: _emptyMessage,
      wordsSubtitle: 'Study the words you got wrong',
      quizSubtitle: 'Practice only the words you got wrong',
    );
  }
}
