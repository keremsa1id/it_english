import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:it_english/models/term.dart';
import 'package:it_english/screens/search_screen.dart';
import 'package:it_english/screens/word_detail_screen.dart';
import 'package:it_english/utils/search.dart';

Term _term(String term, String turkish, {String fullForm = ''}) => Term(
      term: term,
      turkish: turkish,
      fullForm: fullForm,
      category: 'software',
      definition: 'Definition of $term.',
      exampleSentence: 'This long example sentence uses the $term word.',
    );

void main() {
  group('normalizeForSearch', () {
    test('Türkçe karakterleri ve büyük harfleri sadeleştirir', () {
      expect(normalizeForSearch('Güvenlik Duvarı'), 'guvenlik duvari');
      expect(normalizeForSearch('İŞÇİ'), 'isci');
      expect(normalizeForSearch('  çok   boşluk '), 'cok bosluk');
    });
  });

  group('searchRank', () {
    final Term firewall = _term('firewall', 'güvenlik duvarı');

    test('tam eşleşme en iyisidir, sonra başlangıç, sonra içinde geçme', () {
      expect(searchRank(firewall, 'firewall'), 0);
      expect(searchRank(firewall, 'fire'), 1);
      expect(searchRank(firewall, 'wall'), 2);
    });

    test('Türkçe karşılıkta Türkçe karakter yazmadan da bulur', () {
      expect(searchRank(firewall, normalizeForSearch('guvenlik')), 3);
    });

    test('kısaltmanın açılımında arar', () {
      final Term pr = _term('PR', 'değişiklik isteği', fullForm: 'Pull Request');
      expect(searchRank(pr, 'pull request'), 3);
    });

    test('eşleşmeyen ve boş arama null döner', () {
      expect(searchRank(firewall, 'router'), isNull);
      expect(searchRank(firewall, ''), isNull);
    });
  });

  group('SearchScreen.search', () {
    final List<SearchEntry> entries = <SearchEntry>[
      (term: _term('wallpaper', 'duvar kâğıdı'), section: 'A'),
      (term: _term('firewall', 'güvenlik duvarı'), section: 'IT Terms 1'),
      (term: _term('wall', 'duvar'), section: 'B'),
    ];

    test('en uygun sonuçlar başta gelir', () {
      final List<SearchEntry> results = SearchScreen.search(entries, 'wall');

      expect(
        results.map((SearchEntry e) => e.term.term),
        <String>['wall', 'wallpaper', 'firewall'],
      );
    });

    test('Türkçe arama da çalışır', () {
      final List<SearchEntry> results =
          SearchScreen.search(entries, 'GÜVENLİK');

      expect(results.single.term.term, 'firewall');
      expect(results.single.section, 'IT Terms 1');
    });
  });

  testWidgets('kelime ayrıntı ekranı Türkçe, tanım ve cümleyi gösterir',
      (WidgetTester tester) async {
    final Term pr = _term('PR', 'değişiklik isteği', fullForm: 'Pull Request');
    await tester.pumpWidget(
      MaterialApp(home: WordDetailScreen(term: pr, sectionTitle: 'Chat')),
    );

    expect(find.text('Pull Request'), findsOneWidget);
    expect(find.text('değişiklik isteği'), findsOneWidget);
    expect(find.text('Definition of PR.'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
  });
}
