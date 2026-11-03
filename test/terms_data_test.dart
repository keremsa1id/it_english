import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:it_english/models/term.dart';
import 'package:it_english/utils/sentence_parts.dart';

/// assets/data/terms.json içeriğinin uygulamanın kurallarına uyduğunu
/// kontrol eder. Yeni terim eklenince bu testler de çalıştırılmalı.
void main() {
  final List<Term> terms = (jsonDecode(
    File('assets/data/terms.json').readAsStringSync(),
  ) as List<dynamic>)
      .map((dynamic e) => Term.fromJson(e as Map<String, dynamic>))
      .toList();

  test('terimler tekrar etmez', () {
    final Set<String> names =
        terms.map((Term t) => t.term.toLowerCase()).toSet();
    expect(names, hasLength(terms.length));
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
    });
  }
}
