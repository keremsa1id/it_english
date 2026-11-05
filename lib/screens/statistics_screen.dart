import 'package:flutter/material.dart';

import '../models/section.dart';
import '../models/term.dart';
import '../models/weekly_pack.dart';
import '../services/achievement_service.dart';
import '../services/pack_service.dart';
import '../services/progress_service.dart';
import '../services/term_repository.dart';
import '../widgets/backup_section.dart';
import '../widgets/voice_section.dart';

/// "1 h 20 min", "12 min" ya da "0 min" biçiminde süre.
String formatStudyTime(Duration duration) {
  final int hours = duration.inHours;
  final int minutes = duration.inMinutes.remainder(60);
  return hours > 0 ? '$hours h $minutes min' : '$minutes min';
}

/// İstatistikler: özet sayılar, son 7 günün grafiği, çalışma süresi ve en çok
/// yanlış yapılan kelimeler.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  /// Kelime anahtarı → kelime; yanlış listesinde Türkçeyi göstermek için.
  /// Kilitli bölümler dahil bütün kelimeler.
  late final Future<Map<String, Term>> _termsFuture = _loadTerms();

  Future<Map<String, Term>> _loadTerms() async {
    final List<Term> terms = <Term>[
      ...await MixedTermRepository(<String>[
        for (final Section section in Section.all) section.assetPath,
      ]).loadTerms(),
    ];
    final PackService packs = PackService.instance;
    for (final WeeklyPack pack in await packs.releasedPacks()) {
      try {
        terms.addAll(await packs.repositoryFor(pack).loadTerms());
      } on TermRepositoryException {
        // Bozuk paket istatistik ekranını engellemesin.
      }
    }
    return <String, Term>{
      for (final Term term in terms) ProgressService.keyOf(term): term,
    };
  }

  @override
  Widget build(BuildContext context) {
    final ProgressService progress = ProgressService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics'), centerTitle: true),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: progress,
          builder: (BuildContext context, Widget? child) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummary(context, progress),
                    const SizedBox(height: 24),
                    const _SectionTitle('LAST 7 DAYS'),
                    const SizedBox(height: 12),
                    _WeeklyChart(
                      days: progress.recentPractice(),
                      goal: progress.dailyGoal,
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(
                      'BADGES  ${Achievement.all.where((Achievement a) => progress.isEarned(a.id)).length}'
                      ' / ${Achievement.all.length}',
                    ),
                    const SizedBox(height: 12),
                    _buildBadges(context, progress),
                    const SizedBox(height: 24),
                    const _SectionTitle('STUDY TIME'),
                    const SizedBox(height: 8),
                    Text(
                      'Today: ${formatStudyTime(progress.studyTimeToday)}'
                      '   ·   Total: ${formatStudyTime(progress.studyTimeTotal)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle('MOST MISSED WORDS'),
                    const SizedBox(height: 8),
                    _buildMostMissed(context, progress),
                    const SizedBox(height: 24),
                    const _SectionTitle('VOICE'),
                    const SizedBox(height: 4),
                    Text(
                      'Choose when words are read aloud. The most natural '
                      'English voice on your device is chosen automatically; '
                      'you can pick another one.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    const VoiceSection(),
                    const SizedBox(height: 24),
                    const _SectionTitle('BACKUP'),
                    const SizedBox(height: 4),
                    Text(
                      'Moving to a new phone? Export your progress here and '
                      'import it on the new device.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    const BackupSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, ProgressService progress) {
    final List<(String, String, IconData)> tiles = <(String, String, IconData)>[
      ('${progress.learnedTotal}', 'Words learned', Icons.school_rounded),
      ('${progress.masteredTotal}', 'Mastered', Icons.workspace_premium_rounded),
      (
        '${progress.bestStreak}',
        'Best streak (days)',
        Icons.local_fire_department_rounded,
      ),
      ('${progress.quizzesCompleted}', 'Quizzes finished', Icons.quiz_rounded),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        for (final (String value, String label, IconData icon) in tiles)
          _StatTile(value: value, label: label, icon: icon),
      ],
    );
  }

  Widget _buildBadges(BuildContext context, ProgressService progress) {
    final AchievementContext achievements =
        AchievementService.instance.context;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.8,
      children: [
        for (final Achievement achievement in Achievement.all)
          _BadgeTile(
            achievement: achievement,
            earned: progress.isEarned(achievement.id),
            progress: achievement.measure(achievements),
          ),
      ],
    );
  }

  Widget _buildMostMissed(BuildContext context, ProgressService progress) {
    final ThemeData theme = Theme.of(context);
    final List<(String, int)> missed = progress.mostMissed();
    if (missed.isEmpty) {
      return Text(
        'No mistakes yet. Words you get wrong in a quiz will appear here.',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return FutureBuilder<Map<String, Term>>(
      future: _termsFuture,
      builder: (BuildContext context, AsyncSnapshot<Map<String, Term>> snap) {
        final Map<String, Term> terms = snap.data ?? const <String, Term>{};
        return Column(
          children: [
            for (final (String key, int count) in missed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  terms[key]?.displayTerm ?? key,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: terms[key]?.turkish.isNotEmpty ?? false
                    ? Text(terms[key]!.turkish)
                    : null,
                trailing: Text(
                  count == 1 ? '1 mistake' : '$count mistakes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFFFA726),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Tek bir rozet: kazanıldıysa renkli, değilse gri ve kilitli; altında
/// ilerleme ("62 / 100").
class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.achievement,
    required this.earned,
    required this.progress,
  });

  static const Color _gold = Color(0xFFFFB300);

  final Achievement achievement;
  final bool earned;
  final (int, int) progress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color muted = theme.colorScheme.onSurfaceVariant;
    final (int current, int target) = progress;
    final String status = earned
        ? 'Earned'
        : target == 0
            ? '—'
            : '${current > target ? target : current} / $target';

    return Tooltip(
      message: achievement.description,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: earned
              ? _gold.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: earned ? _gold : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              earned ? achievement.icon : Icons.lock_rounded,
              size: 36,
              color: earned ? _gold : muted,
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: earned ? null : muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Son günlerin soru sayılarını çubuklarla gösterir. Günlük hedefe ulaşan
/// günler turuncu çizilir.
class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.days, required this.goal});

  static const double _maxBarHeight = 140;
  static const Color _goalColor = Color(0xFFFF9800);
  static const List<String> _weekdays = <String>[
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', //
  ];

  final List<(DateTime, int)> days;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int top = <int>[goal, for (final (DateTime _, int count) in days) count]
        .reduce((int a, int b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _maxBarHeight + 40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (DateTime day, int count) in days)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('$count', style: theme.textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Container(
                          height: top == 0
                              ? 2
                              : (count / top * _maxBarHeight)
                                  .clamp(2.0, _maxBarHeight)
                                  .toDouble(),
                          decoration: BoxDecoration(
                            color: count >= goal && count > 0
                                ? _goalColor
                                : theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _weekdays[day.weekday - 1],
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Daily goal: $goal questions (orange = goal reached)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
