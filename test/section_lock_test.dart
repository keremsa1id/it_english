import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:it_english/models/quiz_mode.dart';
import 'package:it_english/models/section.dart';
import 'package:it_english/services/progress_service.dart';
import 'package:it_english/services/section_lock.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('her klasörün ilk bölümü her zaman açıktır', () {
    final ProgressService progress = ProgressService.forTest();

    for (final SectionGroup group in SectionGroup.all) {
      expect(
        isSectionUnlocked(group.sections.first, progress: progress),
        isTrue,
        reason: '${group.sections.first.title} kilitli olmamalı.',
      );
    }
  });

  test('önceki bölümde quiz bitirilmeden sonraki bölüm kilitlidir', () {
    final ProgressService progress = ProgressService.forTest();

    expect(isSectionUnlocked(Section.adverbs2, progress: progress), isFalse);
    expect(isSectionUnlocked(Section.adverbs3, progress: progress), isFalse);
  });

  test('önceki bölümde bir quiz bitirilince sonraki açılır, düşük skor da '
      'yeter', () async {
    final ProgressService progress = ProgressService.forTest();

    await progress.recordQuiz(Section.adverbs1.assetPath, 0, 10);

    expect(isSectionUnlocked(Section.adverbs2, progress: progress), isTrue);
    // Bir sonraki bölüm için Adverbs 2'de de quiz bitirmek gerekir.
    expect(isSectionUnlocked(Section.adverbs3, progress: progress), isFalse);
  });

  test('hangi quiz türünde bitirildiği önemli değildir', () async {
    final ProgressService progress = ProgressService.forTest();

    await progress.recordQuiz(
      QuizMode.listening.scoreId(Section.verbs1.assetPath),
      7,
      10,
    );

    expect(isSectionUnlocked(Section.verbs2, progress: progress), isTrue);
  });

  test('bir klasördeki quiz başka klasörün kilidini açmaz', () async {
    final ProgressService progress = ProgressService.forTest();

    await progress.recordQuiz(Section.verbs1.assetPath, 10, 10);

    expect(isSectionUnlocked(Section.nouns2, progress: progress), isFalse);
  });

  test('önceki bölüm klasör içindeki sıraya göre bulunur', () {
    expect(previousSection(Section.itTerms1), isNull);
    expect(previousSection(Section.itTerms4), Section.itTerms3);
    expect(previousSection(Section.advancedIt2), Section.advancedIt1);
  });
}
