import 'package:flutter/material.dart';

import '../services/progress_service.dart';
import 'study_list_screen.dart';

/// Yıldızlanan kelimelerin çalışma ekranı.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  static const String _emptyMessage =
      'No favorites yet. Tap the star on a word card to add it here.';

  @override
  Widget build(BuildContext context) {
    return StudyListScreen(
      title: 'Favorites',
      include: ProgressService.instance.isFavorite,
      description: (ProgressService progress) => progress.favoriteCount == 0
          ? _emptyMessage
          : '${progress.favoriteCount} favorite '
              '${progress.favoriteCount == 1 ? 'word' : 'words'}.',
      emptyMessage: _emptyMessage,
      wordsSubtitle: 'Study your starred words',
      quizSubtitle: 'Practice only your starred words',
    );
  }
}
