import 'package:flutter/material.dart';

import '../models/section.dart';
import '../models/term.dart';
import '../models/weekly_pack.dart';
import '../services/pack_service.dart';
import '../services/term_repository.dart';
import '../utils/search.dart';
import '../widgets/category_style.dart';
import 'word_detail_screen.dart';

/// Aranabilir bir kelime ve bulunduğu bölümün adı.
typedef SearchEntry = ({Term term, String section});

/// Bütün kelimeler (kilitli bölümler ve açılmış haftalık paketler dahil)
/// içinde İngilizce ya da Türkçe arama. Bir sonuca dokununca kelimenin
/// ayrıntıları açılır.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  /// Gösterilecek en fazla sonuç.
  static const int maxResults = 50;

  /// [entries] içinde [query]'yi arar; en uygun sonuçlar başta.
  static List<SearchEntry> search(List<SearchEntry> entries, String query) {
    final String normalized = normalizeForSearch(query);
    final List<(int, SearchEntry)> matches = <(int, SearchEntry)>[
      for (final SearchEntry entry in entries)
        if (searchRank(entry.term, normalized) case final int rank)
          (rank, entry),
    ]..sort(((int, SearchEntry) a, (int, SearchEntry) b) {
        final int byRank = a.$1.compareTo(b.$1);
        return byRank != 0
            ? byRank
            : a.$2.term.term.toLowerCase().compareTo(b.$2.term.term.toLowerCase());
      });
    return <SearchEntry>[
      for (final (int _, SearchEntry entry) in matches.take(maxResults)) entry,
    ];
  }

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final Future<List<SearchEntry>> _entriesFuture = _loadEntries();
  String _query = '';

  Future<List<SearchEntry>> _loadEntries() async {
    final List<SearchEntry> entries = <SearchEntry>[];
    for (final Section section in Section.all) {
      try {
        for (final Term term
            in await TermRepository(assetPath: section.assetPath).loadTerms()) {
          entries.add((term: term, section: section.title));
        }
      } on TermRepositoryException {
        // Okunamayan bölüm aramayı engellemesin.
      }
    }
    final PackService packs = PackService.instance;
    for (final WeeklyPack pack in await packs.releasedPacks()) {
      try {
        for (final Term term in await packs.repositoryFor(pack).loadTerms()) {
          entries.add((term: term, section: pack.title));
        }
      } on TermRepositoryException {
        // Bozuk paket aramayı engellemesin.
      }
    }
    return entries;
  }

  void _open(SearchEntry entry) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            WordDetailScreen(term: entry.term, sectionTitle: entry.section),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Search'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: TextField(
                    autofocus: true,
                    autocorrect: false,
                    textInputAction: TextInputAction.search,
                    onChanged: (String value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Search in English or Turkish',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<SearchEntry>>(
                    future: _entriesFuture,
                    builder: (
                      BuildContext context,
                      AsyncSnapshot<List<SearchEntry>> snapshot,
                    ) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final List<SearchEntry> entries =
                          snapshot.data ?? const <SearchEntry>[];
                      if (normalizeForSearch(_query).isEmpty) {
                        return _Hint(
                          '${entries.length} words. Type a word, its Turkish '
                          'meaning or an abbreviation.',
                        );
                      }
                      final List<SearchEntry> results =
                          SearchScreen.search(entries, _query);
                      if (results.isEmpty) {
                        return const _Hint('No words found.');
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: results.length,
                        separatorBuilder: (BuildContext context, int index) =>
                            const Divider(height: 1),
                        itemBuilder: (BuildContext context, int index) {
                          final SearchEntry entry = results[index];
                          final CategoryStyle style =
                              CategoryStyle.of(entry.term.category);
                          return ListTile(
                            leading: Icon(style.icon, color: style.color),
                            title: Text(
                              entry.term.displayTerm,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              entry.term.turkish.isEmpty
                                  ? entry.section
                                  : '${entry.term.turkish} · ${entry.section}',
                            ),
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            onTap: () => _open(entry),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
