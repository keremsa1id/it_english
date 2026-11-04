import 'package:flutter/material.dart';

import 'models/section.dart';
import 'screens/group_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/quiz_mode_screen.dart';
import 'screens/review_screen.dart';
import 'screens/section_screen.dart';
import 'screens/weekly_screen.dart';
import 'services/pack_service.dart';
import 'services/progress_service.dart';
import 'services/term_repository.dart';
import 'widgets/daily_goal_card.dart';
import 'widgets/menu_card.dart';
import 'widgets/progress_footer.dart';
import 'widgets/section_icon.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProgressService.instance.load();
  runApp(const ItEnglishApp());
}

class ItEnglishApp extends StatelessWidget {
  const ItEnglishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IT English',
      // Siyah zemin, kırmızı vurgular.
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD32F2F),
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFFE53935),
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFF3A0D0D),
          onPrimaryContainer: Colors.white,
          surface: Colors.black,
          onSurface: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

/// Karışık quiz'i ve klasörleri (IT Terms, Verbs, Nouns...) listeleyen ana
/// ekran.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Karışık quiz'in skorları bu anahtarla saklanır.
  static const String mixedQuizId = 'mixed';

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (BuildContext context) => screen),
    );
  }

  /// Bütün bölümlerin ve açılmış haftalık paketlerin kelimelerinden rastgele
  /// sorular soran quiz.
  void _openMixedQuiz(BuildContext context) {
    _open(
      context,
      const QuizModeScreen(
        setup: QuizSetup(
          title: 'Mixed Quiz',
          quizId: mixedQuizId,
          questionCount: 25,
          repository: AllTermsRepository(),
        ),
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
                  const DailyGoalCard(),
                  const SizedBox(height: 16),
                  MenuCard(
                    title: 'Mixed Quiz',
                    subtitle: 'Random questions from every section',
                    icon: Icons.shuffle_rounded,
                    onTap: () => _openMixedQuiz(context),
                    footer: const ProgressFooter(
                      repositories: <TermRepository>[AllTermsRepository()],
                      quizId: mixedQuizId,
                    ),
                  ),
                  const SizedBox(height: 16),
                  MenuCard(
                    title: 'Weekly Words',
                    subtitle: '40 new work and IT words every Monday',
                    icon: Icons.calendar_month_rounded,
                    onTap: () => _open(context, const WeeklyScreen()),
                    footer: const WeeklyFooter(),
                  ),
                  const SizedBox(height: 16),
                  MenuCard(
                    title: 'Review',
                    subtitle: 'Practice the words you got wrong',
                    icon: Icons.replay_circle_filled_rounded,
                    onTap: () => _open(context, const ReviewScreen()),
                    footer: _CountFooter(
                      (ProgressService progress) => switch (
                          progress.reviewCount) {
                        0 => 'No words to review',
                        1 => '1 word to review',
                        final int count => '$count words to review',
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  MenuCard(
                    title: 'Favorites',
                    subtitle: 'Words you marked with a star',
                    icon: Icons.star_rounded,
                    onTap: () => _open(context, const FavoritesScreen()),
                    footer: _CountFooter(
                      (ProgressService progress) => switch (
                          progress.favoriteCount) {
                        0 => 'No favorites yet',
                        1 => '1 favorite word',
                        final int count => '$count favorite words',
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final SectionGroup group in SectionGroup.all) ...[
                    MenuCard(
                      title: group.title,
                      subtitle: group.subtitle,
                      icon: sectionIcon(group.kind),
                      // Tek bölümlü klasör doğrudan bölümü açar.
                      onTap: () => _open(
                        context,
                        group.sections.length == 1
                            ? SectionScreen(section: group.sections.single)
                            : GroupScreen(group: group),
                      ),
                      footer: ProgressFooter(
                        sections: group.sections,
                        quizId: group.sections.length == 1
                            ? group.sections.single.assetPath
                            : null,
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

/// Menü kartının altında, ilerleme değişince güncellenen kısa sayaç yazısı.
class _CountFooter extends StatelessWidget {
  const _CountFooter(this.text);

  final String Function(ProgressService progress) text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ListenableBuilder(
      listenable: ProgressService.instance,
      builder: (BuildContext context, Widget? child) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          text(ProgressService.instance),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
