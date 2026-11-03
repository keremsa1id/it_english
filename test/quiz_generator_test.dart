import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:it_english/models/term.dart';
import 'package:it_english/services/quiz_generator.dart';

Term _term(String term, String category, {String? sentence}) => Term(
      term: term,
      category: category,
      definition: 'Definition of $term.',
      exampleSentence: sentence ?? 'This long example sentence uses the $term word.',
    );

void main() {
  final List<Term> terms = <Term>[
    _term('router', 'networking'),
    _term('packet', 'networking'),
    _term('latency', 'networking'),
    _term('protocol', 'networking'),
    _term('bandwidth', 'networking'),
    _term('malware', 'security'),
    _term('firewall', 'security'),
    _term('backup', 'security'),
  ];

  QuizGenerator generator() => QuizGenerator(random: Random(1));

  test('istenen sayıda soru üretir ve her soru farklı terimi sorar', () {
    final List<QuizQuestion> questions =
        generator().generate(terms, questionCount: 5);

    expect(questions, hasLength(5));
    expect(questions.map((QuizQuestion q) => q.answer).toSet(), hasLength(5));
  });

  test('terim sayısından fazla soru üretmez', () {
    expect(generator().generate(terms, questionCount: 50), hasLength(8));
  });

  test('4 farklı şık üretir ve doğru cevap şıklarda vardır', () {
    for (final QuizQuestion q in generator().generate(terms)) {
      expect(q.options, hasLength(4));
      expect(q.options, contains(q.answer));
      expect(q.options.toSet(), hasLength(4));
    }
  });

  test('yanlış şıklar önce aynı kategoriden seçilir', () {
    for (final QuizQuestion q in generator().generate(terms)) {
      if (q.answer.category == 'networking') {
        expect(
          q.options.every((Term t) => t.category == 'networking'),
          isTrue,
        );
      }
    }
  });

  test('cümlesinde terim geçmeyen kayıt soru olmaz ama şık olabilir', () {
    final List<Term> withBroken = <Term>[
      ...terms.take(3),
      _term('server', 'hardware', sentence: 'This sentence has no term in it at all.'),
    ];
    final List<QuizQuestion> questions = generator().generate(withBroken);

    expect(questions, hasLength(3));
    expect(
      questions.any((QuizQuestion q) => q.answer.term == 'server'),
      isFalse,
    );
    expect(questions.first.options, hasLength(4));
  });

  test('ikiden az terimle soru üretmez', () {
    expect(generator().generate(terms.take(1).toList()), isEmpty);
    expect(generator().generate(const <Term>[]), isEmpty);
  });
}
