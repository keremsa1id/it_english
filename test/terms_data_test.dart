import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:it_english/models/section.dart';
import 'package:it_english/models/term.dart';
import 'package:it_english/models/weekly_pack.dart';
import 'package:it_english/services/pack_service.dart';
import 'package:it_english/utils/sentence_parts.dart';

/// Kontrol edilecek bir kelime dosyası: bir bölüm ya da haftalık paket.
class _WordFile {
  const _WordFile(this.title, this.path, {this.needsFullForm = false});

  final String title;
  final String path;
  final bool needsFullForm;
}

/// Bölümlerin ve haftalık paketlerin JSON dosyalarının uygulamanın
/// kurallarına uyduğunu kontrol eder. Yeni kelime eklenince bu testler de
/// çalıştırılmalı.
void main() {
  const int wordsPerFile = 40;

  final List<WeeklyPack> packs = PackService.parseIndex(
    File(PackService.indexPath).readAsStringSync(),
  );

  final List<_WordFile> files = <_WordFile>[
    for (final Section section in Section.all)
      _WordFile(
        section.title,
        section.assetPath,
        needsFullForm: section.kind == SectionKind.advancedIt,
      ),
    for (final WeeklyPack pack in packs)
      _WordFile(pack.title, '${PackService.directory}${pack.file}'),
  ];

  List<Term> load(_WordFile file) => (jsonDecode(
        File(file.path).readAsStringSync(),
      ) as List<dynamic>)
          .map((dynamic e) => Term.fromJson(e as Map<String, dynamic>))
          .toList();

  test('bir kelime iki bölümde ya da pakette birden geçmez', () {
    final List<String> names = <String>[
      for (final _WordFile file in files)
        for (final Term term in load(file)) term.term.toLowerCase(),
    ];
    expect(names.toSet(), hasLength(names.length));
  });

  group('haftalık paket listesi', () {
    test('en az bir paket var ve kimlikler benzersiz', () {
      expect(packs, isNotEmpty);
      expect(
        packs.map((WeeklyPack p) => p.id).toSet(),
        hasLength(packs.length),
      );
    });

    test('her paketin dosyası var', () {
      for (final WeeklyPack pack in packs) {
        expect(
          File('${PackService.directory}${pack.file}').existsSync(),
          isTrue,
          reason: '${pack.file} bulunamadı.',
        );
      }
    });

    test('açılış tarihleri farklı günlerde', () {
      expect(
        packs.map((WeeklyPack p) => p.releaseDate).toSet(),
        hasLength(packs.length),
      );
    });
  });

  for (final _WordFile file in files) {
    group(file.title, () {
      final List<Term> terms = load(file);

      test('$wordsPerFile kelime içerir', () {
        expect(terms, hasLength(wordsPerFile));
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
          if (file.needsFullForm) {
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
