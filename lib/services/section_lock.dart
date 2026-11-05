import '../models/quiz_mode.dart';
import '../models/section.dart';
import 'progress_service.dart';

// Bölümlerin kademeli açılma kuralı.
//
// Her klasörün ilk bölümü her zaman açıktır. Sonraki bölüm, bir önceki
// bölümde herhangi bir türde en az bir quiz bitirilince açılır (skor önemli
// değil). Ör. Adverbs 1'de bir quiz bitirmeden Adverbs 2 açılmaz.

/// [section]'dan hemen önce gelen bölüm; klasörün ilk bölümüyse ya da hiçbir
/// klasörde değilse null.
Section? previousSection(Section section) {
  for (final SectionGroup group in SectionGroup.all) {
    final int index = group.sections.indexOf(section);
    if (index > 0) {
      return group.sections[index - 1];
    }
  }
  return null;
}

/// [section]'da herhangi bir türde en az bir quiz bitirildi mi.
bool hasCompletedQuiz(Section section, {ProgressService? progress}) {
  final ProgressService service = progress ?? ProgressService.instance;
  return QuizMode.values.any(
    (QuizMode mode) =>
        service.bestScore(mode.scoreId(section.assetPath)) != null,
  );
}

/// [section] açık mı.
bool isSectionUnlocked(Section section, {ProgressService? progress}) {
  final Section? previous = previousSection(section);
  return previous == null || hasCompletedQuiz(previous, progress: progress);
}
