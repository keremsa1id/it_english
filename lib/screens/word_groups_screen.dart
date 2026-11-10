import 'package:flutter/material.dart';

import '../models/section.dart';
import '../widgets/menu_card.dart';
import '../widgets/progress_footer.dart';
import '../widgets/section_icon.dart';
import 'cyber_screen.dart';
import 'group_screen.dart';
import 'section_screen.dart';

/// Bütün kelime klasörlerini (IT Terms, Verbs, Nouns, Phrases...) listeler.
/// Ana ekrandaki "Word Groups" kartı bunu açar.
class WordGroupsScreen extends StatelessWidget {
  const WordGroupsScreen({super.key});

  void _open(BuildContext context, SectionGroup group) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => group.sections.length == 1
            // Tek bölümlü klasör doğrudan bölümü açar.
            ? SectionScreen(section: group.sections.single)
            : GroupScreen(group: group),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Word Groups'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final SectionGroup group in SectionGroup.menu) ...[
                    MenuCard(
                      title: group.title,
                      subtitle: group.subtitle,
                      icon: sectionIcon(group.kind),
                      onTap: () => _open(context, group),
                      footer: ProgressFooter(
                        sections: group.sections,
                        quizId: group.sections.length == 1
                            ? group.sections.single.assetPath
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Cyber klasörü Advanced IT'nin hemen altında durur.
                    if (group.kind == SectionKind.advancedIt) ...[
                      MenuCard(
                        title: CyberScreen.title,
                        subtitle: CyberScreen.subtitle,
                        icon: sectionIcon(SectionKind.cyber),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) =>
                                const CyberScreen(),
                          ),
                        ),
                        footer: ProgressFooter(sections: CyberScreen.sections),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
