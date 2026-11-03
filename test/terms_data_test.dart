import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:it_english/models/section.dart';
import 'package:it_english/models/term.dart';
import 'package:it_english/utils/sentence_parts.dart';

/// Her bölüm için assets/data/ altındaki JSON dosyasının uygulamanın
/// kurallarına uyduğunu kontrol eder. Yeni kelime eklenince bu testler de
/// çalıştırılmalı.
void main() {
  const int wordsPerSection = 40;

  List<Term> load(Section section) => (jsonDecode(
        File(section.assetPath).readAsStringSync(),
      ) as List<dynamic>)
          .map((dynamic e) => Term.fromJson(e as Map<String, dynamic>))
          .toList();

  test('bir kelime iki bölümde birden geçmez', () {
    final List<String> names = <String>[
      for (final Section section in Section.all)
        for (final Term term in load(section)) term.term.toLowerCase(),
    ];
    expect(names.toSet(), hasLength(names.length));
  });

  for (final Section section in Section.all) {
    group(section.title, () {
      final List<Term> terms = load(section);

      test('$wordsPerSection kelime içerir', () {
        expect(terms, hasLength(wordsPerSection));
      });

      for (final Term term in terms) {
        test('"${term.term}" kurallara uyar', () {
          expect(
            term.exampleSentence.trim().split(RegExp(r'\s+')).length,
            greaterThanOrEqualTo(8),
            reason: 'Cümle en az 8 kelime olmalı.',
          );
          expect(
            splitSentence(term.exampleSentence, term.term)
                .where((SentencePart p) => p.isTerm),
            hasLength(1),
            reason: 'Terim cümlede tam olarak bir kez geçmeli (quiz boşluğu).',
          );
          expect(term.definition.trim(), isNotEmpty);
          expect(
            term.turkish.trim(),
            isNotEmpty,
            reason: 'Her kelimenin Türkçe karşılığı olmalı.',
          );
          if (section.kind == SectionKind.advancedIt) {
            expect(
              term.fullForm.trim(),
              isNotEmpty,
              reason: 'Kısaltmanın açılımı olmalı.',
            );
          }
        });
      }
    });
  }
}
