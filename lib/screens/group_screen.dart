import 'package:flutter/material.dart';

import '../models/section.dart';
import '../widgets/menu_card.dart';
import '../widgets/section_icon.dart';
import 'section_screen.dart';

/// Bir klasörün içindeki bölümleri listeler, ör. "Nouns" için
/// Nouns 1 ve Nouns 2.
class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key, required this.group});

  final SectionGroup group;

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final Section section in group.sections) ...[
                    MenuCard(
                      title: section.title,
                      subtitle: section.subtitle,
                      icon: sectionIcon(section.kind),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) =>
                              SectionScreen(section: section),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
