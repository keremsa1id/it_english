/// Bölümün türü; ana ekrandaki simgeyi belirler.
enum SectionKind { itTerms, verbs, nouns }

/// Uygulamadaki bir çalışma bölümü, ör. "Verbs 1".
///
/// Her bölümün 40 kelimesi assets/data/ altındaki kendi JSON dosyasındadır.
class Section {
  const Section({
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.assetPath,
  });

  final String title;
  final String subtitle;
  final SectionKind kind;

  /// Bölümün kelimelerinin bulunduğu JSON dosyası.
  final String assetPath;

  /// Ana ekranda gösterilen bölümler, gösterim sırasıyla.
  static const List<Section> all = <Section>[
    Section(
      title: 'IT Terms 1',
      subtitle: 'Hardware, software, networking and more',
      kind: SectionKind.itTerms,
      assetPath: 'assets/data/it_terms_1.json',
    ),
    Section(
      title: 'IT Terms 2',
      subtitle: 'More words people use in technology',
      kind: SectionKind.itTerms,
      assetPath: 'assets/data/it_terms_2.json',
    ),
    Section(
      title: 'Verbs 1',
      subtitle: 'The most common English verbs',
      kind: SectionKind.verbs,
      assetPath: 'assets/data/verbs_1.json',
    ),
    Section(
      title: 'Verbs 2',
      subtitle: 'The next 40 common verbs',
      kind: SectionKind.verbs,
      assetPath: 'assets/data/verbs_2.json',
    ),
    Section(
      title: 'Nouns 1',
      subtitle: 'The most common English nouns',
      kind: SectionKind.nouns,
      assetPath: 'assets/data/nouns_1.json',
    ),
    Section(
      title: 'Nouns 2',
      subtitle: 'The next 40 common nouns',
      kind: SectionKind.nouns,
      assetPath: 'assets/data/nouns_2.json',
    ),
  ];
}
