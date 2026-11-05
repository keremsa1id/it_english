import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:it_english/models/section.dart';
import 'package:it_english/models/weekly_pack.dart';
import 'package:it_english/services/pack_service.dart';
import 'package:it_english/services/term_repository.dart';

String _index(List<(String id, String date)> packs) => jsonEncode(<Object>[
      for (final (String id, String date) in packs)
        <String, String>{
          'id': id,
          'title': id,
          'subtitle': 'Subtitle of $id',
          'file': '$id.json',
          'releaseDate': date,
        },
    ]);

void main() {
  // Sırası karışık verilir; servis tarihe göre sıralamalı.
  final String index = _index(<(String, String)>[
    ('week_02', '2026-11-09'),
    ('week_01', '2026-11-02'),
    ('week_03', '2026-11-16'),
  ]);

  PackService create(DateTime now, {String? raw}) => PackService.forTest(
        now: () => now,
        loadString: (String path) async => raw ?? index,
      );

  test('açılmış paketler en yenisi başta gelir', () async {
    final PackService packs = create(DateTime(2026, 11, 10, 8));

    final List<WeeklyPack> released = await packs.releasedPacks();

    expect(released.map((WeeklyPack p) => p.id), <String>['week_02', 'week_01']);
  });

  test('paket açılış günü sabahın erken saatinde de açıktır', () async {
    final PackService packs = create(DateTime(2026, 11, 9, 0, 1));

    final List<WeeklyPack> released = await packs.releasedPacks();

    expect(released.first.id, 'week_02');
  });

  test('sıradaki paket ve kalan gün doğru hesaplanır', () async {
    final PackService packs = create(DateTime(2026, 11, 4, 22));

    final WeeklyPack? next = await packs.nextPack();

    expect(next?.id, 'week_02');
    expect(packs.daysUntil(next!), 5);
  });

  test('bütün paketler açıldıysa sıradaki paket yoktur', () async {
    final PackService packs = create(DateTime(2027, 1, 1));

    expect(await packs.nextPack(), isNull);
    expect(await packs.releasedPacks(), hasLength(3));
  });

  test('liste okunamazsa uygulama çökmez, boş liste döner', () async {
    final PackService packs = create(DateTime(2026, 11, 10), raw: 'bozuk');

    expect(await packs.releasedPacks(), isEmpty);
    expect(await packs.nextPack(), isNull);
  });

  test('tarih biçimi hatalıysa liste reddedilir', () {
    expect(
      () => PackService.parseIndex(
        _index(<(String, String)>[('week_01', '2 Kasım')]),
      ),
      throwsFormatException,
    );
  });

  test('dosya adı düz bir JSON adı değilse paket reddedilir', () {
    expect(
      () => PackService.parseIndex(jsonEncode(<Object>[
        <String, String>{
          'id': 'evil',
          'title': 'Evil',
          'subtitle': 'Evil',
          'file': '../secrets.json',
          'releaseDate': '2026-11-02',
        },
      ])),
      throwsFormatException,
    );
  });

  group('internetten paket', () {
    final String localIndex =
        _index(<(String, String)>[('week_01', '2026-11-02')]);
    final String remoteIndex = _index(<(String, String)>[
      ('week_01', '2026-11-02'),
      ('week_02', '2026-11-09'),
    ]);
    final String week2 = jsonEncode(<Object>[
      <String, String>{
        'term': 'roadmap',
        'turkish': 'yol haritası',
        'category': 'noun',
        'definition': 'A long-term plan.',
        'exampleSentence': 'Our product roadmap includes a new mobile app.',
      },
    ]);

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      PackService.remoteEnabled = true;
    });
    tearDown(() => PackService.remoteEnabled = false);

    /// Uygulamada yalnızca liste ve week_01 var.
    Future<String> bundle(String path) async {
      if (path == PackService.indexPath) {
        return localIndex;
      }
      throw Exception('Uygulamada yok: $path');
    }

    final DateTime now = DateTime(2026, 11, 10);

    test("GitHub'daki yeni paket indirilir ve sonraki açılışta internetsiz "
        'de görünür', () async {
      final List<Uri> requested = <Uri>[];
      final PackService online = PackService.forTest(
        now: () => now,
        loadString: bundle,
        fetch: (Uri uri) async {
          requested.add(uri);
          if (uri.path.endsWith('index.json')) {
            return remoteIndex;
          }
          return uri.path.endsWith('week_02.json') ? week2 : null;
        },
      );

      // İlk çağrı uygulamadaki listeyi hemen verir.
      expect(await online.loadPacks(), hasLength(1));
      await online.waitForRefresh();
      expect(await online.loadPacks(), hasLength(2));
      expect(
        requested.map((Uri u) => u.toString()),
        contains('${PackService.remoteBase}week_02.json'),
      );

      // Yeni açılış, internet yok: liste ve paket cihazdan gelir.
      final PackService offline =
          PackService.forTest(now: () => now, loadString: bundle);
      final List<WeeklyPack> packs = await offline.loadPacks();
      expect(packs.map((WeeklyPack p) => p.id), <String>['week_01', 'week_02']);
      final WeeklyPack second = packs.last;
      expect(
        (await offline.repositoryFor(second).loadTerms()).single.term,
        'roadmap',
      );
    });

    test('internet yoksa uygulamadaki paketlerle devam edilir', () async {
      final PackService packs =
          PackService.forTest(now: () => now, loadString: bundle);

      expect(await packs.loadPacks(), hasLength(1));
      await packs.waitForRefresh();
      expect(await packs.loadPacks(), hasLength(1));
    });

    test('bozuk indirilen liste yok sayılır', () async {
      final PackService packs = PackService.forTest(
        now: () => now,
        loadString: bundle,
        fetch: (Uri uri) async => 'bozuk',
      );

      await packs.loadPacks();
      await packs.waitForRefresh();

      expect(await packs.loadPacks(), hasLength(1));
    });

    test('indirilemeyen ya da bozuk paket dosyası hata verir ve saklanmaz',
        () async {
      final WeeklyPack pack = PackService.parseIndex(remoteIndex).last;
      final PackService broken = PackService.forTest(
        now: () => now,
        loadString: bundle,
        fetch: (Uri uri) async => 'bozuk',
      );

      await expectLater(
        broken.repositoryFor(pack).loadTerms(),
        throwsA(isA<TermRepositoryException>()),
      );

      final PackService offline =
          PackService.forTest(now: () => now, loadString: bundle);
      await expectLater(
        offline.repositoryFor(pack).loadTerms(),
        throwsA(isA<TermRepositoryException>()),
      );
    });
  });

  test('paket, ilerleme anahtarı benzersiz olan bir bölüm gibi gösterilir', () {
    final WeeklyPack pack = PackService.parseIndex(index).first;

    final Section section = pack.toSection();

    expect(section.kind, SectionKind.weekly);
    expect(section.assetPath, 'pack:week_01');
    expect(
      Section.all.map((Section s) => s.assetPath),
      isNot(contains(section.assetPath)),
    );
  });
}
