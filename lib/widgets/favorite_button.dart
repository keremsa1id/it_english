import 'package:flutter/material.dart';

import '../models/term.dart';
import '../services/progress_service.dart';

/// Kelimeyi favorilere ekleyen ya da çıkaran yıldız butonu.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.term});

  static const Color _starColor = Color(0xFFFFC107);

  final Term term;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ProgressService progress = ProgressService.instance;

    return ListenableBuilder(
      listenable: progress,
      builder: (BuildContext context, Widget? child) {
        final bool favorite = progress.isFavorite(term);
        return IconButton(
          tooltip: favorite ? 'Remove from favorites' : 'Add to favorites',
          iconSize: 30,
          onPressed: () => progress.toggleFavorite(term),
          icon: Icon(
            favorite ? Icons.star_rounded : Icons.star_outline_rounded,
            color: favorite ? _starColor : theme.colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }
}
