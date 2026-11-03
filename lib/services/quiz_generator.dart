import 'dart:math';

import '../models/term.dart';
import '../utils/sentence_parts.dart';

/// Quiz'deki tek bir soru: [answer] teriminin örnek cümlesinde terim yerine
/// boşluk vardır, [options] arasından doğru terim seçilir.
/// [options] her zaman [answer]'ı içerir.
class QuizQuestion {
  const QuizQuestion({required this.answer, required this.options});

  final Term answer;
  final List<Term> options;
}

/// Terim listesinden rastgele boşluk doldurma soruları üretir.
class QuizGenerator {
  QuizGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// En fazla [questionCount] soru üretir; her soru farklı bir terimi sorar.
  ///
  /// Örnek cümlesinde terim geçmeyen kayıtlar soru olarak kullanılmaz
  /// (boşluk konamaz) ama yanlış şık olabilir. Yanlış şıklar önce aynı
  /// kategoriden seçilir, yetmezse diğer kategorilerden tamamlanır.
  /// Terim sayısı [optionCount]'tan azsa şık sayısı terim sayısına düşer.
  ///
  /// [askOnly] verilirse yalnızca onu sağlayan terimler sorulur; diğerleri
  /// yine yanlış şık olarak kullanılır (ör. Review quiz'i).
  ///
  /// [requireBlank] false ise örnek cümlesinde terim geçmeyen kayıtlar da
  /// sorulabilir (ör. tanımdan bulma quiz'i).
  List<QuizQuestion> generate(
    List<Term> terms, {
    int questionCount = 10,
    int optionCount = 4,
    bool Function(Term term)? askOnly,
    bool requireBlank = true,
  }) {
    // Aynı terim iki kez gelirse şıklarda tekrar olmasın.
    final Map<String, Term> unique = <String, Term>{};
    for (final Term term in terms) {
      unique.putIfAbsent(term.term.toLowerCase(), () => term);
    }
    final List<Term> pool = unique.values.toList();
    if (pool.length < 2) {
      return const <QuizQuestion>[];
    }

    final List<Term> answers = pool
        .where(
          (Term t) =>
              (!requireBlank || hasBlank(t)) && (askOnly?.call(t) ?? true),
        )
        .toList()
      ..shuffle(_random);
    final int optionsPerQuestion = min(optionCount, pool.length);

    return <QuizQuestion>[
      for (final Term answer in answers.take(questionCount))
        QuizQuestion(
          answer: answer,
          options: _optionsFor(answer, pool, optionsPerQuestion),
        ),
    ];
  }

  /// [term]'in örnek cümlesinde boşluk bırakılacak bir yer var mı.
  static bool hasBlank(Term term) => splitSentence(
        term.exampleSentence,
        term.term,
      ).any((SentencePart part) => part.isTerm);

  List<Term> _optionsFor(Term answer, List<Term> pool, int optionCount) {
    final List<Term> sameCategory = <Term>[];
    final List<Term> otherCategory = <Term>[];
    for (final Term term in pool) {
      if (identical(term, answer)) {
        continue;
      }
      (term.category == answer.category ? sameCategory : otherCategory)
          .add(term);
    }
    sameCategory.shuffle(_random);
    otherCategory.shuffle(_random);

    final List<Term> options = <Term>[
      answer,
      ...<Term>[...sameCategory, ...otherCategory].take(optionCount - 1),
    ]..shuffle(_random);
    return List<Term>.unmodifiable(options);
  }
}
