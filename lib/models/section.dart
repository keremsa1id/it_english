/// Bölümün türü; ana ekrandaki simgeyi belirler.
enum SectionKind {
  itTerms,
  advancedIt,
  verbs,
  nouns,
  adjectives,
  adverbs,
  phrases,
  phrasalVerbs,
  idioms,
  linkers,
  prepositions,
}

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

  static const Section itTerms1 = Section(
    title: 'IT Terms 1',
    subtitle: 'Hardware, software, networking and more',
    kind: SectionKind.itTerms,
    assetPath: 'assets/data/it_terms_1.json',
  );
  static const Section itTerms2 = Section(
    title: 'IT Terms 2',
    subtitle: 'More words people use in technology',
    kind: SectionKind.itTerms,
    assetPath: 'assets/data/it_terms_2.json',
  );
  static const Section advancedIt = Section(
    title: 'Advanced IT',
    subtitle: 'Tech abbreviations and what they stand for',
    kind: SectionKind.advancedIt,
    assetPath: 'assets/data/advanced_it.json',
  );
  static const Section verbs1 = Section(
    title: 'Verbs 1',
    subtitle: 'The most common English verbs',
    kind: SectionKind.verbs,
    assetPath: 'assets/data/verbs_1.json',
  );
  static const Section verbs2 = Section(
    title: 'Verbs 2',
    subtitle: 'The next 40 common verbs',
    kind: SectionKind.verbs,
    assetPath: 'assets/data/verbs_2.json',
  );
  static const Section nouns1 = Section(
    title: 'Nouns 1',
    subtitle: 'The most common English nouns',
    kind: SectionKind.nouns,
    assetPath: 'assets/data/nouns_1.json',
  );
  static const Section nouns2 = Section(
    title: 'Nouns 2',
    subtitle: 'The next 40 common nouns',
    kind: SectionKind.nouns,
    assetPath: 'assets/data/nouns_2.json',
  );
  static const Section adjectives1 = Section(
    title: 'Adjectives 1',
    subtitle: 'The most common English adjectives',
    kind: SectionKind.adjectives,
    assetPath: 'assets/data/adjectives_1.json',
  );
  static const Section adjectives2 = Section(
    title: 'Adjectives 2',
    subtitle: 'Useful adjectives for work and daily life',
    kind: SectionKind.adjectives,
    assetPath: 'assets/data/adjectives_2.json',
  );
  static const Section adverbs1 = Section(
    title: 'Adverbs 1',
    subtitle: 'Time, frequency and manner',
    kind: SectionKind.adverbs,
    assetPath: 'assets/data/adverbs_1.json',
  );
  static const Section adverbs2 = Section(
    title: 'Adverbs 2',
    subtitle: 'More adverbs for natural English',
    kind: SectionKind.adverbs,
    assetPath: 'assets/data/adverbs_2.json',
  );
  static const Section phrasalVerbs1 = Section(
    title: 'Phrasal Verbs 1',
    subtitle: 'Everyday phrasal verbs',
    kind: SectionKind.phrasalVerbs,
    assetPath: 'assets/data/phrasal_verbs_1.json',
  );
  static const Section phrasalVerbs2 = Section(
    title: 'Phrasal Verbs 2',
    subtitle: 'Phrasal verbs for work and computers',
    kind: SectionKind.phrasalVerbs,
    assetPath: 'assets/data/phrasal_verbs_2.json',
  );
  static const Section idioms1 = Section(
    title: 'Idioms 1',
    subtitle: 'Common everyday idioms',
    kind: SectionKind.idioms,
    assetPath: 'assets/data/idioms_1.json',
  );
  static const Section idioms2 = Section(
    title: 'Idioms 2',
    subtitle: 'Idioms you hear at work',
    kind: SectionKind.idioms,
    assetPath: 'assets/data/idioms_2.json',
  );
  static const Section linkers1 = Section(
    title: 'Linking Words 1',
    subtitle: 'Conjunctions and transition words',
    kind: SectionKind.linkers,
    assetPath: 'assets/data/linkers_1.json',
  );
  static const Section linkers2 = Section(
    title: 'Linking Words 2',
    subtitle: 'More words to connect your ideas',
    kind: SectionKind.linkers,
    assetPath: 'assets/data/linkers_2.json',
  );
  static const Section prepositions1 = Section(
    title: 'Prepositions 1',
    subtitle: 'Place, time and direction',
    kind: SectionKind.prepositions,
    assetPath: 'assets/data/prepositions_1.json',
  );
  static const Section prepositions2 = Section(
    title: 'Prepositions 2',
    subtitle: 'Verbs and adjectives with prepositions',
    kind: SectionKind.prepositions,
    assetPath: 'assets/data/prepositions_2.json',
  );
  static const Section phrases1 = Section(
    title: 'Phrases 1',
    subtitle: 'Everyday English expressions',
    kind: SectionKind.phrases,
    assetPath: 'assets/data/phrases_1.json',
  );
  static const Section phrases2 = Section(
    title: 'Phrases 2',
    subtitle: 'Common phrasal verbs and work phrases',
    kind: SectionKind.phrases,
    assetPath: 'assets/data/phrases_2.json',
  );

  /// Bütün bölümler. Karışık quiz ve veri testleri bunu kullanır.
  static const List<Section> all = <Section>[
    itTerms1,
    itTerms2,
    advancedIt,
    verbs1,
    verbs2,
    nouns1,
    nouns2,
    adjectives1,
    adjectives2,
    adverbs1,
    adverbs2,
    phrases1,
    phrases2,
    phrasalVerbs1,
    phrasalVerbs2,
    idioms1,
    idioms2,
    linkers1,
    linkers2,
    prepositions1,
    prepositions2,
  ];
}

/// Ana ekrandaki bir klasör, ör. "Nouns" (içinde Nouns 1 ve Nouns 2).
///
/// Tek bölümlü klasörler ana ekranda doğrudan o bölüm olarak gösterilir.
class SectionGroup {
  const SectionGroup({
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final SectionKind kind;
  final List<Section> sections;

  /// Ana ekranda gösterilen klasörler, gösterim sırasıyla.
  static const List<SectionGroup> all = <SectionGroup>[
    SectionGroup(
      title: 'IT Terms',
      subtitle: 'Everyday words people use in technology',
      kind: SectionKind.itTerms,
      sections: <Section>[Section.itTerms1, Section.itTerms2],
    ),
    SectionGroup(
      title: 'Advanced IT',
      subtitle: 'Tech abbreviations and what they stand for',
      kind: SectionKind.advancedIt,
      sections: <Section>[Section.advancedIt],
    ),
    SectionGroup(
      title: 'Verbs',
      subtitle: 'The most common English verbs',
      kind: SectionKind.verbs,
      sections: <Section>[Section.verbs1, Section.verbs2],
    ),
    SectionGroup(
      title: 'Nouns',
      subtitle: 'The most common English nouns',
      kind: SectionKind.nouns,
      sections: <Section>[Section.nouns1, Section.nouns2],
    ),
    SectionGroup(
      title: 'Adjectives',
      subtitle: 'Words that describe things: big, reliable, expensive',
      kind: SectionKind.adjectives,
      sections: <Section>[Section.adjectives1, Section.adjectives2],
    ),
    SectionGroup(
      title: 'Adverbs',
      subtitle: 'Words like usually, quickly, probably',
      kind: SectionKind.adverbs,
      sections: <Section>[Section.adverbs1, Section.adverbs2],
    ),
    SectionGroup(
      title: 'Phrases',
      subtitle: 'Everyday expressions and useful patterns',
      kind: SectionKind.phrases,
      sections: <Section>[Section.phrases1, Section.phrases2],
    ),
    SectionGroup(
      title: 'Phrasal Verbs',
      subtitle: 'Verbs like look for, wake up, shut down',
      kind: SectionKind.phrasalVerbs,
      sections: <Section>[Section.phrasalVerbs1, Section.phrasalVerbs2],
    ),
    SectionGroup(
      title: 'Idioms',
      subtitle: 'Expressions like break the ice, piece of cake',
      kind: SectionKind.idioms,
      sections: <Section>[Section.idioms1, Section.idioms2],
    ),
    SectionGroup(
      title: 'Linking Words',
      subtitle: 'Words like however, although, therefore',
      kind: SectionKind.linkers,
      sections: <Section>[Section.linkers1, Section.linkers2],
    ),
    SectionGroup(
      title: 'Prepositions',
      subtitle: 'Words like in, on, at and depend on',
      kind: SectionKind.prepositions,
      sections: <Section>[Section.prepositions1, Section.prepositions2],
    ),
  ];
}
