import 'package:flutter/material.dart';

import '../models/section.dart';
import '../services/progress_service.dart';
import '../services/section_lock.dart';
import '../widgets/locked_card.dart';
import '../widgets/menu_card.dart';
import '../widgets/progress_footer.dart';
import '../widgets/section_icon.dart';
import 'section_screen.dart';

/// Bir klasörün içindeki bölümleri listeler, ör. "Nouns" için
/// Nouns 1, 2 ve 3.
///
/// Bölümler sırayla açılır (bkz. [isSectionUnlocked]); kilitli bölüm,
/// nasıl açılacağını anlatan bir kartla gösterilir. Quiz bitip bu ekrana
/// dönülünce kilitler kendiliğinden güncellenir.
class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key, required this.group});

  final SectionGroup group;

  void _showLockedMessage(BuildContext context, Section previous) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Finish any quiz in ${previous.title} to unlock this section.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(group.title), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListenableBuilder(
                listenable: ProgressService.instance,
                builder: (BuildContext context, Widget? child) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final Section section in group.sections) ...[
                      _buildSectionCard(context, section),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, Section section) {
    final Section? previous = previousSection(section);
    if (previous != null && !isSectionUnlocked(section)) {
      return LockedCard(
        title: section.title,
        message: 'Finish a quiz in ${previous.title} to unlock.',
        onTap: () => _showLockedMessage(context, previous),
      );
    }

    return MenuCard(
      title: section.title,
      subtitle: section.subtitle,
      icon: sectionIcon(section.kind),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => SectionScreen(section: section),
        ),
      ),
      footer: ProgressFooter(
        sections: <Section>[section],
        quizId: section.assetPath,
      ),
    );
  }
}
