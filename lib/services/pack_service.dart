import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/section.dart';
import '../models/term.dart';
import '../models/weekly_pack.dart';
import 'section_lock.dart';
import 'term_repository.dart';

/// Haftalık paketleri okur ve hangilerinin açıldığını hesaplar.
///
/// Paketler üç yerden gelir: uygulamanın içindekiler, daha önce internetten
/// indirilip cihazda saklananlar ve GitHub'daki güncel liste. Böylece main
/// dalına yeni bir paket eklenince uygulama yeniden derlenmeden görünür.
///
/// Uygulama genelinde tek bir örnek kullanılır: `PackService.instance`.
class PackService {
  PackService._()
      : _now = DateTime.now,
        _loadString = rootBundle.loadString,
        _fetch = _download;

  /// Testler için: [now] "bugün"ü, [loadString] uygulama içi dosya okumayı,
  /// [fetch] internetten indirmeyi değiştirir (varsayılan: internet yok).
  @visibleForTesting
  PackService.forTest({
    DateTime Function()? now,
    Future<String> Function(String path)? loadString,
    Future<String?> Function(Uri uri)? fetch,
  })  : _now = now ?? DateTime.now,
        _loadString = loadString ?? rootBundle.loadString,
        _fetch = fetch ?? _noNetwork;

  static final PackService instance = PackService._();

  /// Paket dosyalarının uygulama içindeki klasörü.
  static const String directory = 'assets/data/weekly/';
  static const String indexPath = '${directory}index.json';

  /// Güncel paketlerin indirildiği adres (repodaki aynı klasör).
  static const String remoteBase =
      'https://raw.githubusercontent.com/keremsa1id/it_english/main/'
      'assets/data/weekly/';

  /// İnternetten paket indirme açık mı. Uygulama açılışında (main) açılır;
  /// testlerde kapalı kalır ki testler internete çıkmasın.
  static bool remoteEnabled = false;

  static const Duration _timeout = Duration(seconds: 8);
  static const String _indexCacheKey = 'remotePackIndex';
  static String _fileCacheKey(String file) => 'remotePack:$file';

  final DateTime Function() _now;
  final Future<String> Function(String path) _loadString;
  final Future<String?> Function(Uri uri) _fetch;
  Future<List<WeeklyPack>>? _packsFuture;
  Future<void>? _refreshFuture;

  /// [uri]'yi indirir; başarısızsa (internet yok, 404...) null döner.
  static Future<String?> _download(Uri uri) async {
    try {
      final http.Response response = await http.get(uri).timeout(_timeout);
      return response.statusCode == 200 ? utf8.decode(response.bodyBytes) : null;
    } catch (error) {
      debugPrint('Paket indirilemedi ($uri): $error');
      return null;
    }
  }

  static Future<String?> _noNetwork(Uri uri) async => null;

  static Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (error) {
      debugPrint('PackService: cihaz kaydı okunamadı: $error');
      return null;
    }
  }

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

  /// Bütün paketler (açılmamış olanlar dahil), tarih sırasıyla.
  ///
  /// Uygulamadaki ve cihazda saklanan listeler hemen kullanılır; internet
  /// açıksa güncel liste arka planda indirilir ve bir sonraki çağrıdan
  /// itibaren dahil olur. Hiçbir liste okunamazsa boş liste döner ve sonraki
  /// çağrıda yeniden denenir.
  Future<List<WeeklyPack>> loadPacks() => _packsFuture ??= _loadPacks();

  Future<List<WeeklyPack>> _loadPacks() async {
    final Map<String, WeeklyPack> byId = <String, WeeklyPack>{};
    try {
      _mergeInto(byId, parseIndex(await _loadString(indexPath)));
    } catch (error) {
      debugPrint('PackService: uygulama içi liste okunamadı: $error');
    }
    final String? cached = (await _prefs())?.getString(_indexCacheKey);
    if (cached != null) {
      try {
        _mergeInto(byId, parseIndex(cached));
      } on FormatException catch (error) {
        debugPrint('PackService: saklanan liste bozuk: $error');
      }
    }

    final List<WeeklyPack> packs = _sorted(byId);
    if (packs.isEmpty) {
      _packsFuture = null;
    }
    if (remoteEnabled) {
      _refreshFuture ??= _refreshFromRemote(byId);
    }
    return packs;
  }

  /// Testler için: arka plandaki internet güncellemesinin bitmesini bekler.
  @visibleForTesting
  Future<void> waitForRefresh() => _refreshFuture ?? Future<void>.value();

  static void _mergeInto(Map<String, WeeklyPack> byId, List<WeeklyPack> packs) {
    for (final WeeklyPack pack in packs) {
      byId[pack.id] = pack;
    }
  }

  static List<WeeklyPack> _sorted(Map<String, WeeklyPack> byId) =>
      List<WeeklyPack>.unmodifiable(
        byId.values.toList()
          ..sort((WeeklyPack a, WeeklyPack b) =>
              a.releaseDate.compareTo(b.releaseDate)),
      );

  /// GitHub'daki güncel listeyi indirir, cihazda saklar ve yeni paketlerin
  /// dosyalarını önceden indirir (sonra internetsiz de açılsın diye).
  Future<void> _refreshFromRemote(Map<String, WeeklyPack> local) async {
    final String? raw = await _fetch(Uri.parse('${remoteBase}index.json'));
    if (raw == null) {
      return;
    }
    final List<WeeklyPack> remote;
    try {
      remote = parseIndex(raw);
    } on FormatException catch (error) {
      debugPrint('PackService: indirilen liste bozuk: $error');
      return;
    }
    await (await _prefs())?.setString(_indexCacheKey, raw);

    final Map<String, WeeklyPack> merged = <String, WeeklyPack>{...local};
    _mergeInto(merged, remote);
    _packsFuture = Future<List<WeeklyPack>>.value(_sorted(merged));

    for (final WeeklyPack pack in remote) {
      if (!local.containsKey(pack.id)) {
        try {
          await loadPackJson(pack);
        } on TermRepositoryException {
          // Sonraki açılışta yeniden denenir.
        }
      }
    }
  }

  /// [pack]'in kelime dosyasının içeriği: uygulamadaysa oradan, değilse
  /// cihazda saklanandan, o da yoksa internetten (indirilen saklanır).
  ///
  /// Hiçbiri olmazsa [TermRepositoryException] fırlatır.
  Future<String> loadPackJson(WeeklyPack pack) async {
    try {
      return await _loadString('$directory${pack.file}');
    } catch (_) {
      // Uygulamada yok: internetten gelmiş bir paket.
    }
    final SharedPreferences? prefs = await _prefs();
    final String? cached = prefs?.getString(_fileCacheKey(pack.file));
    if (cached != null) {
      return cached;
    }
    final String? raw = await _fetch(Uri.parse('$remoteBase${pack.file}'));
    if (raw == null) {
      throw const TermRepositoryException(
        'This weekly pack could not be downloaded. Check your internet '
        'connection.',
      );
    }
    // Bozuk dosya saklanmasın; çözülemezse burada hata fırlar.
    if (TermRepository.parseTerms(raw).isEmpty) {
      throw const TermRepositoryException('This weekly pack is empty.');
    }
    await prefs?.setString(_fileCacheKey(pack.file), raw);
    return raw;
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

  /// [pack]'in kelimelerini yükleyen depo (bkz. [loadPackJson]).
  TermRepository repositoryFor(WeeklyPack pack) => PackTermRepository(this, pack);
}

/// Bir haftalık paketin kelimeleri; uygulamada yoksa cihazdan ya da
/// internetten gelir.
class PackTermRepository extends TermRepository {
  PackTermRepository(this._service, this.pack);

  final PackService _service;
  final WeeklyPack pack;

  @override
  Future<List<Term>> loadTerms() async =>
      TermRepository.parseTerms(await _service.loadPackJson(pack));
}

/// Açılmış bütün bölümlerin ve haftalık paketlerin kelimeleri.
///
/// Mixed Quiz, Review ve Favorites bunu kullanır; yeni bir bölüm ya da paket
/// açılınca kelimeleri bir sonraki yüklemede kendiliğinden dahil olur.
/// Kilitli bölümlerin kelimeleri (bkz. [isSectionUnlocked]) dahil edilmez.
class AllTermsRepository extends TermRepository {
  const AllTermsRepository();

  @override
  Future<List<Term>> loadTerms() async {
    final List<Term> terms = <Term>[
      ...await MixedTermRepository(<String>[
        for (final Section section in Section.all)
          if (isSectionUnlocked(section)) section.assetPath,
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
