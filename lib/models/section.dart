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

  /// Haftalık paketler (bkz. WeeklyPack).
  weekly,
}

/// Uygulamadaki bir çalışma bölümü, ör. "Verbs 1".
///
/// Her bölümün 40 kelimesi assets/data/ altındaki kendi JSON dosyasındadır.
/// Her klasörün son bölümü iş hayatında ve ofiste sık geçen kelimelere
/// ayrılmıştır.
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

  /// Bölümün kelimelerinin bulunduğu JSON dosyası. İlerleme ve skorlar da
  /// bu yolla saklandığı için değiştirilmemeli.
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
  static const Section itTerms3 = Section(
    title: 'IT Terms 3',
    subtitle: 'IT at work: projects, support and security',
    kind: SectionKind.itTerms,
    assetPath: 'assets/data/it_terms_3.json',
  );
  static const Section itTerms4 = Section(
    title: 'IT Terms 4',
    subtitle: 'AI agents, MCP and modern developer tools',
    kind: SectionKind.itTerms,
    assetPath: 'assets/data/it_terms_4.json',
  );
  static const Section advancedIt1 = Section(
    title: 'Advanced IT 1',
    subtitle: 'Tech abbreviations and what they stand for',
    kind: SectionKind.advancedIt,
    assetPath: 'assets/data/advanced_it.json',
  );
  static const Section advancedIt2 = Section(
    title: 'Advanced IT 2',
    subtitle: 'Business and office abbreviations: KPI, HR, ASAP',
    kind: SectionKind.advancedIt,
    assetPath: 'assets/data/advanced_it_2.json',
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
  static const Section verbs3 = Section(
    title: 'Verbs 3',
    subtitle: 'Verbs for work: manage, approve, deliver',
    kind: SectionKind.verbs,
    assetPath: 'assets/data/verbs_3.json',
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
  static const Section nouns3 = Section(
    title: 'Nouns 3',
    subtitle: 'Nouns for work: deadline, budget, client',
    kind: SectionKind.nouns,
    assetPath: 'assets/data/nouns_3.json',
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
  static const Section adjectives3 = Section(
    title: 'Adjectives 3',
    subtitle: 'Adjectives for work: urgent, confidential, remote',
    kind: SectionKind.adjectives,
    assetPath: 'assets/data/adjectives_3.json',
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
  static const Section adverbs3 = Section(
    title: 'Adverbs 3',
    subtitle: 'Adverbs for work: approximately, promptly',
    kind: SectionKind.adverbs,
    assetPath: 'assets/data/adverbs_3.json',
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
  static const Section phrases3 = Section(
    title: 'Phrases 3',
    subtitle: 'Office and email phrases: as per, on hold',
    kind: SectionKind.phrases,
    assetPath: 'assets/data/phrases_3.json',
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
  static const Section phrasalVerbs3 = Section(
    title: 'Phrasal Verbs 3',
    subtitle: 'Meetings and projects: kick off, wrap up',
    kind: SectionKind.phrasalVerbs,
    assetPath: 'assets/data/phrasal_verbs_3.json',
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
  static const Section idioms3 = Section(
    title: 'Idioms 3',
    subtitle: 'Business idioms: the bottom line, red tape',
    kind: SectionKind.idioms,
    assetPath: 'assets/data/idioms_3.json',
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
  static const Section linkers3 = Section(
    title: 'Linking Words 3',
    subtitle: 'Formal linkers for reports and emails',
    kind: SectionKind.linkers,
    assetPath: 'assets/data/linkers_3.json',
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
  static const Section prepositions3 = Section(
    title: 'Prepositions 3',
    subtitle: 'Business collocations: comply with, based on',
    kind: SectionKind.prepositions,
    assetPath: 'assets/data/prepositions_3.json',
  );

  /// Bütün bölümler. Karışık quiz ve veri testleri bunu kullanır.
  static const List<Section> all = <Section>[
    itTerms1,
    itTerms2,
    itTerms3,
    itTerms4,
    advancedIt1,
    advancedIt2,
    verbs1,
    verbs2,
    verbs3,
    nouns1,
    nouns2,
    nouns3,
    adjectives1,
    adjectives2,
    adjectives3,
    adverbs1,
    adverbs2,
    adverbs3,
    phrases1,
    phrases2,
    phrases3,
    phrasalVerbs1,
    phrasalVerbs2,
    phrasalVerbs3,
    idioms1,
    idioms2,
    idioms3,
    linkers1,
    linkers2,
    linkers3,
    prepositions1,
    prepositions2,
    prepositions3,
  ];
}

/// Ana ekrandaki bir klasör, ör. "Nouns" (içinde Nouns 1, 2 ve 3).
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
      sections: <Section>[
        Section.itTerms1,
        Section.itTerms2,
        Section.itTerms3,
        Section.itTerms4,
      ],
    ),
    SectionGroup(
      title: 'Advanced IT',
      subtitle: 'Tech and business abbreviations',
      kind: SectionKind.advancedIt,
      sections: <Section>[Section.advancedIt1, Section.advancedIt2],
    ),
    SectionGroup(
      title: 'Verbs',
      subtitle: 'The most common English verbs',
      kind: SectionKind.verbs,
      sections: <Section>[Section.verbs1, Section.verbs2, Section.verbs3],
    ),
    SectionGroup(
      title: 'Nouns',
      subtitle: 'The most common English nouns',
      kind: SectionKind.nouns,
      sections: <Section>[Section.nouns1, Section.nouns2, Section.nouns3],
    ),
    SectionGroup(
      title: 'Adjectives',
      subtitle: 'Words that describe things: big, reliable, expensive',
      kind: SectionKind.adjectives,
      sections: <Section>[
        Section.adjectives1,
        Section.adjectives2,
        Section.adjectives3,
      ],
    ),
    SectionGroup(
      title: 'Adverbs',
      subtitle: 'Words like usually, quickly, probably',
      kind: SectionKind.adverbs,
      sections: <Section>[Section.adverbs1, Section.adverbs2, Section.adverbs3],
    ),
    SectionGroup(
      title: 'Phrases',
      subtitle: 'Everyday expressions and useful patterns',
      kind: SectionKind.phrases,
      sections: <Section>[Section.phrases1, Section.phrases2, Section.phrases3],
    ),
    SectionGroup(
      title: 'Phrasal Verbs',
      subtitle: 'Verbs like look for, wake up, shut down',
      kind: SectionKind.phrasalVerbs,
      sections: <Section>[
        Section.phrasalVerbs1,
        Section.phrasalVerbs2,
        Section.phrasalVerbs3,
      ],
    ),
    SectionGroup(
      title: 'Idioms',
      subtitle: 'Expressions like break the ice, piece of cake',
      kind: SectionKind.idioms,
      sections: <Section>[Section.idioms1, Section.idioms2, Section.idioms3],
    ),
    SectionGroup(
      title: 'Linking Words',
      subtitle: 'Words like however, although, therefore',
      kind: SectionKind.linkers,
      sections: <Section>[Section.linkers1, Section.linkers2, Section.linkers3],
    ),
    SectionGroup(
      title: 'Prepositions',
      subtitle: 'Words like in, on, at and depend on',
      kind: SectionKind.prepositions,
      sections: <Section>[
        Section.prepositions1,
        Section.prepositions2,
        Section.prepositions3,
      ],
    ),
  ];
}
