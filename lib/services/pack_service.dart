import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/section.dart';
import '../models/term.dart';
import '../models/weekly_pack.dart';
import 'term_repository.dart';

/// Haftalık paketleri okur ve hangilerinin açıldığını hesaplar.
///
/// Uygulama genelinde tek bir örnek kullanılır: `PackService.instance`.
class PackService {
  PackService._()
      : _now = DateTime.now,
        _loadString = rootBundle.loadString;

  /// Testler için: [now] "bugün"ü, [loadString] dosya okumayı değiştirir.
  @visibleForTesting
  PackService.forTest({
    DateTime Function()? now,
    Future<String> Function(String path)? loadString,
  })  : _now = now ?? DateTime.now,
        _loadString = loadString ?? rootBundle.loadString;

  static final PackService instance = PackService._();

  /// Paket dosyalarının bulunduğu klasör.
  static const String directory = 'assets/data/weekly/';
  static const String indexPath = '${directory}index.json';

  final DateTime Function() _now;
  final Future<String> Function(String path) _loadString;
  Future<List<WeeklyPack>>? _packsFuture;

  /// index.json içeriğini çözer; paketleri açılış tarihine göre sıralar.
  ///
  /// Biçim hatalıysa [FormatException] fırlatır.
  static List<WeeklyPack> parseIndex(String raw) {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Paket listesi bir liste olmalı.');
    }
    final List<WeeklyPack> packs = <WeeklyPack>[
      for (final Object? item in decoded)
        if (item is Map<String, dynamic>)
          WeeklyPack.fromJson(item)
        else
          throw const FormatException('Paket kaydı geçersiz.'),
    ]..sort((WeeklyPack a, WeeklyPack b) =>
        a.releaseDate.compareTo(b.releaseDate));
    return List<WeeklyPack>.unmodifiable(packs);
  }

  /// Bütün paketler (açılmamış olanlar dahil), tarih sırasıyla. Okunamazsa
  /// boş liste döner ve sonraki çağrıda yeniden denenir.
  Future<List<WeeklyPack>> loadPacks() => _packsFuture ??= _loadPacks();

  Future<List<WeeklyPack>> _loadPacks() async {
    try {
      return parseIndex(await _loadString(indexPath));
    } catch (error) {
      debugPrint('PackService.loadPacks hatası: $error');
      _packsFuture = null;
      return const <WeeklyPack>[];
    }
  }

  /// Açılmış paketler, en yenisi başta.
  Future<List<WeeklyPack>> releasedPacks() async {
    final DateTime now = _now();
    final List<WeeklyPack> packs = await loadPacks();
    return packs
        .where((WeeklyPack pack) => pack.isReleasedOn(now))
        .toList()
        .reversed
        .toList();
  }

  /// Henüz açılmamış en yakın paket; yoksa null.
  Future<WeeklyPack?> nextPack() async {
    final DateTime now = _now();
    for (final WeeklyPack pack in await loadPacks()) {
      if (!pack.isReleasedOn(now)) {
        return pack;
      }
    }
    return null;
  }

  /// [pack] açılana kadar kalan gün sayısı (bugün açıldıysa 0).
  int daysUntil(WeeklyPack pack) {
    final DateTime now = _now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final int days = pack.releaseDate.difference(today).inDays;
    return days < 0 ? 0 : days;
  }

  /// [pack]'in kelimelerini yükleyen depo.
  TermRepository repositoryFor(WeeklyPack pack) =>
      TermRepository(assetPath: '$directory${pack.file}');
}

/// Bütün bölümlerin ve açılmış haftalık paketlerin kelimeleri.
///
/// Mixed Quiz, Review ve Favorites bunu kullanır; yeni bir paket açılınca
/// kelimeleri bir sonraki yüklemede kendiliğinden dahil olur.
class AllTermsRepository extends TermRepository {
  const AllTermsRepository();

  @override
  Future<List<Term>> loadTerms() async {
    final List<Term> terms = <Term>[
      ...await MixedTermRepository(<String>[
        for (final Section section in Section.all) section.assetPath,
      ]).loadTerms(),
    ];
    final PackService packs = PackService.instance;
    for (final WeeklyPack pack in await packs.releasedPacks()) {
      try {
        terms.addAll(await packs.repositoryFor(pack).loadTerms());
      } on TermRepositoryException catch (error) {
        // Bozuk bir paket diğer kelimeleri engellemesin.
        debugPrint('Paket yüklenemedi (${pack.id}): $error');
      }
    }
    return List<Term>.unmodifiable(terms);
  }
}
