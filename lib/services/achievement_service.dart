import 'package:flutter/material.dart';

import '../models/section.dart';
import '../models/term.dart';
import 'progress_service.dart';
import 'term_repository.dart';

/// Rozetlerin ilerlemesini hesaplamak için gereken bilgiler.
class AchievementContext {
  const AchievementContext({required this.progress, required this.groupKeys});

  final ProgressService progress;

  /// Klasör adı → klasördeki bütün kelimelerin anahtarları.
  final Map<String, Set<String>> groupKeys;

  /// IT klasörlerinin adları ("Bütün IT bölümleri" rozeti için).
  static const List<String> itGroups = <String>['IT Terms', 'Advanced IT'];

  /// [groups] klasörlerinde öğrenilen ve toplam kelime sayısı.
  (int, int) learnedIn(Iterable<String> groups) {
    final Set<String> keys = <String>{
      for (final String group in groups) ...?groupKeys[group],
    };
    return (progress.learnedAmong(keys), keys.length);
  }

  /// Öğrenilme oranı en yüksek klasörün (öğrenilen, toplam) sayıları.
  (int, int) bestGroup() {
    (int, int) best = (0, 0);
    for (final String group in groupKeys.keys) {
      final (int learned, int total) = learnedIn(<String>[group]);
      final (int bestLearned, int bestTotal) = best;
      if (total > 0 &&
          (bestTotal == 0 || learned * bestTotal > bestLearned * total)) {
        best = (learned, total);
      }
    }
    return best;
  }
}

/// Bir rozet: hedefe ulaşınca kazanılır.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.measure,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;

  /// (şu anki değer, hedef). Hedef 0 ise henüz hesaplanamıyor demektir.
  final (int, int) Function(AchievementContext context) measure;

  bool isUnlocked(AchievementContext context) {
    final (int current, int target) = measure(context);
    return target > 0 && current >= target;
  }

  static (int, int) Function(AchievementContext) _learned(int target) =>
      (AchievementContext c) => (c.progress.learnedTotal, target);

  static (int, int) Function(AchievementContext) _streak(int target) =>
      (AchievementContext c) => (c.progress.bestStreak, target);

  /// Bütün rozetler, gösterim sırasıyla.
  static final List<Achievement> all = <Achievement>[
    Achievement(
      id: 'learned_10',
      title: 'First 10 words',
      description: 'Learn 10 words',
      icon: Icons.emoji_objects_rounded,
      measure: _learned(10),
    ),
    Achievement(
      id: 'learned_100',
      title: 'First 100 words',
      description: 'Learn 100 words',
      icon: Icons.school_rounded,
      measure: _learned(100),
    ),
    Achievement(
      id: 'learned_500',
      title: '500 words',
      description: 'Learn 500 words',
      icon: Icons.auto_stories_rounded,
      measure: _learned(500),
    ),
    Achievement(
      id: 'learned_1000',
      title: '1000 words',
      description: 'Learn 1000 words',
      icon: Icons.workspace_premium_rounded,
      measure: _learned(1000),
    ),
    Achievement(
      id: 'streak_3',
      title: '3-day streak',
      description: 'Reach your daily goal 3 days in a row',
      icon: Icons.local_fire_department_rounded,
      measure: _streak(3),
    ),
    Achievement(
      id: 'streak_7',
      title: '7-day streak',
      description: 'Reach your daily goal 7 days in a row',
      icon: Icons.whatshot_rounded,
      measure: _streak(7),
    ),
    Achievement(
      id: 'streak_30',
      title: '30-day streak',
      description: 'Reach your daily goal 30 days in a row',
      icon: Icons.military_tech_rounded,
      measure: _streak(30),
    ),
    Achievement(
      id: 'all_it',
      title: 'IT master',
      description: 'Learn every word in IT Terms and Advanced IT',
      icon: Icons.computer_rounded,
      measure: (AchievementContext c) =>
          c.learnedIn(AchievementContext.itGroups),
    ),
    Achievement(
      id: 'folder_complete',
      title: 'Folder complete',
      description: 'Learn every word in one folder',
      icon: Icons.folder_special_rounded,
      measure: (AchievementContext c) => c.bestGroup(),
    ),
    Achievement(
      id: 'perfect_quiz',
      title: 'Perfect quiz',
      description: 'Answer every question right on the first try',
      icon: Icons.verified_rounded,
      measure: (AchievementContext c) => (c.progress.perfectQuizzes, 1),
    ),
    Achievement(
      id: 'mastered_10',
      title: 'Long-term memory',
      description: 'Master 10 words with spaced repetition',
      icon: Icons.psychology_rounded,
      measure: (AchievementContext c) => (c.progress.masteredTotal, 10),
    ),
    Achievement(
      id: 'study_10h',
      title: '10 hours of study',
      description: 'Spend 10 hours in quizzes and games',
      icon: Icons.timer_rounded,
      measure: (AchievementContext c) =>
          (c.progress.studyTimeTotal.inHours, 10),
    ),
  ];
}

/// Rozetleri kontrol eder; yeni kazanılanları kaydeder ve [onEarned] ile
/// haber verir.
///
/// Uygulama genelinde tek bir örnek kullanılır: `AchievementService.instance`.
class AchievementService {
  AchievementService._() : _progress = ProgressService.instance;

  /// Testler için: klasör kelimeleri dosyadan okunmadan verilir.
  @visibleForTesting
  AchievementService.forTest({
    required ProgressService progress,
    required Map<String, Set<String>> groupKeys,
  })  : _progress = progress,
        _groupKeys = groupKeys;

  static final AchievementService instance = AchievementService._();

  final ProgressService _progress;
  Map<String, Set<String>> _groupKeys = const <String, Set<String>>{};
  bool _checking = false;

  /// Yeni bir rozet kazanılınca çağrılır (ör. kutlama mesajı için).
  void Function(Achievement achievement)? onEarned;

  /// Rozet ilerlemelerini hesaplamak için anlık bilgiler.
  AchievementContext get context =>
      AchievementContext(progress: _progress, groupKeys: _groupKeys);

  /// Klasörlerin kelimelerini okur, zaten hak edilmiş rozetleri sessizce
  /// işaretler ve sonraki ilerlemeleri dinlemeye başlar.
  Future<void> start() async {
    _groupKeys = await _loadGroupKeys();
    check(silent: true);
    _progress.addListener(check);
  }

  static Future<Map<String, Set<String>>> _loadGroupKeys() async {
    final Map<String, Set<String>> keys = <String, Set<String>>{};
    for (final SectionGroup group in SectionGroup.all) {
      final Set<String> groupKeys = <String>{};
      for (final Section section in group.sections) {
        try {
          for (final Term term
              in await TermRepository(assetPath: section.assetPath)
                  .loadTerms()) {
            groupKeys.add(ProgressService.keyOf(term));
          }
        } on TermRepositoryException catch (error) {
          debugPrint('Rozetler için bölüm okunamadı: $error');
        }
      }
      keys[group.title] = groupKeys;
    }
    return keys;
  }

  /// Yeni kazanılan rozetleri işaretler ve döndürür. [silent] değilse her
  /// biri için [onEarned] çağrılır.
  List<Achievement> check({bool silent = false}) {
    if (_checking) {
      return const <Achievement>[];
    }
    _checking = true;
    try {
      final AchievementContext context = this.context;
      final List<Achievement> earned = <Achievement>[
        for (final Achievement achievement in Achievement.all)
          if (!_progress.isEarned(achievement.id) &&
              achievement.isUnlocked(context))
            achievement,
      ];
      if (earned.isNotEmpty) {
        _progress.markEarned(earned.map((Achievement a) => a.id));
        final void Function(Achievement)? notify = onEarned;
        if (!silent && notify != null) {
          for (final Achievement achievement in earned) {
            notify(achievement);
          }
        }
      }
      return earned;
    } finally {
      _checking = false;
    }
  }
}
