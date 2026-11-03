import 'package:flutter/material.dart';

import '../services/progress_service.dart';
import 'menu_card.dart';

/// Ana ekrandaki günlük hedef kartı: bugünkü ilerleme ve seri. Dokununca
/// hedef seçme penceresi açılır.
class DailyGoalCard extends StatelessWidget {
  const DailyGoalCard({super.key});

  static const Color _fireColor = Color(0xFFFF9800);

  void _chooseGoal(BuildContext context) {
    final ProgressService progress = ProgressService.instance;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Daily goal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'How many quiz questions do you want to finish each day?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            for (final int goal in ProgressService.dailyGoalOptions)
              ListTile(
                title: Text('$goal questions a day'),
                trailing: goal == progress.dailyGoal
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () {
                  progress.setDailyGoal(goal);
                  Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = theme.colorScheme.onPrimaryContainer;
    final ProgressService progress = ProgressService.instance;

    return MenuCard(
      title: 'Daily Goal',
      subtitle: 'Finish quiz questions every day',
      icon: Icons.local_fire_department_rounded,
      onTap: () => _chooseGoal(context),
      footer: ListenableBuilder(
        listenable: progress,
        builder: (BuildContext context, Widget? child) {
          final int today = progress.todayCount;
          final int goal = progress.dailyGoal;
          final int streak = progress.streak;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (today / goal).clamp(0.0, 1.0),
                  minHeight: 6,
                  color: progress.goalReachedToday ? _fireColor : null,
                  backgroundColor: color.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      progress.goalReachedToday
                          ? '$today / $goal today — goal reached!'
                          : '$today / $goal today',
                      style: theme.textTheme.bodySmall?.copyWith(color: color),
                    ),
                  ),
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 18,
                    color: streak > 0 ? _fireColor : color.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$streak-day streak',
                    style: theme.textTheme.bodySmall?.copyWith(color: color),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
