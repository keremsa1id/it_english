import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:it_english/models/section.dart';
import 'package:it_english/models/weekly_pack.dart';
import 'package:it_english/services/pack_service.dart';

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
