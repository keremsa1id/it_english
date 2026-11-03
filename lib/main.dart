import 'package:flutter/material.dart';

import 'models/section.dart';
import 'screens/section_screen.dart';
import 'widgets/menu_card.dart';

void main() {
  runApp(const ItEnglishApp());
}

class ItEnglishApp extends StatelessWidget {
  const ItEnglishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IT English',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const HomeScreen(),
    );
  }
}

/// Bölümleri (IT Terms, Verbs, Nouns) listeleyen ana ekran.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static IconData _iconOf(SectionKind kind) => switch (kind) {
        SectionKind.itTerms => Icons.computer_rounded,
        SectionKind.verbs => Icons.directions_run_rounded,
        SectionKind.nouns => Icons.category_rounded,
      };

  void _open(BuildContext context, Section section) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SectionScreen(section: section),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
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
                  Icon(
                    Icons.terminal_rounded,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'IT English',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Learn IT terms and the most common English words.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),
                  for (final Section section in Section.all) ...[
                    MenuCard(
                      title: section.title,
                      subtitle: section.subtitle,
                      icon: _iconOf(section.kind),
                      onTap: () => _open(context, section),
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
