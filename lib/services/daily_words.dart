import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/term.dart';
import 'pack_service.dart';
import 'progress_service.dart';
import 'term_repository.dart';

/// Günün kelimelerini seçer: [day] tarihinden türetilen sabit bir sayıyla
/// karıştırır, böylece aynı gün hep aynı seti verir. Öğrenilmemiş kelimeler
/// önce gelir; yetmezse öğrenilmişlerden tamamlanır.
List<String> pickDailyWords({
  required List<Term> terms,
  required bool Function(Term term) isLearned,
  required DateTime day,
  int count = 10,
}) {
  final Random random = Random(day.year * 10000 + day.month * 100 + day.day);
  final Map<String, Term> unique = <String, Term>{
    for (final Term term in terms) ProgressService.keyOf(term): term,
  };
  // Karıştırmadan önce sırala ki sonuç dosyaların okunma sırasına bağlı
  // olmasın.
  final List<String> keys = unique.keys.toList()..sort();
  final List<String> unlearned = <String>[
    for (final String key in keys)
      if (!isLearned(unique[key]!)) key,
  ]..shuffle(random);
  final List<String> learned = <String>[
    for (final String key in keys)
      if (isLearned(unique[key]!)) key,
  ]..shuffle(random);
  return <String>[...unlearned, ...learned].take(count).toList();
}

/// Günün kelimelerini hazırlar ve gün boyu sabit tutar.
///
/// Uygulama genelinde tek bir örnek kullanılır: `DailyWordsService.instance`.
class DailyWordsService {
  DailyWordsService._()
      : _progress = ProgressService.instance,
        _source = const AllTermsRepository();

  /// Testler için: ilerleme ve kelime kaynağı dışarıdan verilir.
  @visibleForTesting
  DailyWordsService.forTest({
    required ProgressService progress,
    required TermRepository source,
  })  : _progress = progress,
        _source = source;

  static final DailyWordsService instance = DailyWordsService._();

  /// Günde kaç kelime seçileceği.
  static const int wordsPerDay = 10;

  final ProgressService _progress;

  /// Açık bölümlerin ve açılmış paketlerin kelimeleri.
  final TermRepository _source;

  /// Bugünün kelimelerini döndürür; bugün henüz seçilmediyse seçip kaydeder.
  Future<List<String>> ensureToday() async {
    await _progress.load();
    final List<String> current = _progress.todayWordKeys;
    if (current.isNotEmpty) {
      return current;
    }
    final List<String> keys = pickDailyWords(
      terms: await _source.loadTerms(),
      isLearned: _progress.isLearned,
      day: _progress.today,
      count: wordsPerDay,
    );
    await _progress.setTodayWords(keys);
    return keys;
  }

  /// [term] bugünün kelimelerinden mi.
  bool isTodayWord(Term term) => _progress.isTodayWord(term);
}
