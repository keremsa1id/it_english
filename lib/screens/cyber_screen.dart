import 'package:flutter/material.dart';

import '../models/section.dart';
import '../widgets/menu_card.dart';
import '../widgets/progress_footer.dart';
import '../widgets/section_icon.dart';
import 'group_screen.dart';

/// "Cyber" klasörü: siber güvenlik kelimelerinin 5 alt grubunu listeler
/// (Basics, Attacks, Defense, Cryptography, Careers). Her alt grup kendi
/// iki bölümünü GroupScreen'de gösterir.
class CyberScreen extends StatelessWidget {
  const CyberScreen({super.key});

  /// Word Groups ekranındaki "Cyber" kartının metinleri.
  static const String title = 'Cyber';
  static const String subtitle = 'Cybersecurity: attacks, defense, crypto, careers';

  /// Cyber klasöründeki bütün bölümler (ilerleme çubuğu için).
  static List<Section> get sections => <Section>[
        for (final SectionGroup group in SectionGroup.cyberGroups)
          ...group.sections,
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(title), centerTitle: true),
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
                  for (final SectionGroup group in SectionGroup.cyberGroups) ...[
                    MenuCard(
                      title: group.title,
                      subtitle: group.subtitle,
                      icon: sectionIcon(group.kind),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) =>
                              GroupScreen(group: group),
                        ),
                      ),
                      footer: ProgressFooter(sections: group.sections),
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
