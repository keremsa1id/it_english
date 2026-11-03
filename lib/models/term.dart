/// Uygulamadaki tek bir IT terimini temsil eder.
class Term {
  const Term({
    required this.term,
    required this.category,
    required this.definition,
    required this.exampleSentence,
    this.turkish = '',
    this.fullForm = '',
  });

  /// Terimin kendisi, ör. "firewall" veya "IP address".
  final String term;

  /// Kategori anahtarı: hardware, software, networking, security, data,
  /// verb, noun, adjective, adverb, phrase, phrasal, idiom, linker veya
  /// preposition.
  final String category;

  /// Terimin İngilizce açıklaması.
  final String definition;

  /// Terimi içeren, en az 8 kelimelik örnek cümle.
  final String exampleSentence;

  /// Terimin Türkçe karşılığı. Verilmemişse boş metindir.
  final String turkish;

  /// Kısaltmanın açılımı, ör. "AI" için "Artificial Intelligence".
  /// Kısaltma olmayan terimlerde boş metindir.
  final String fullForm;

  /// JSON verisinden [Term] oluşturur.
  ///
  /// Zorunlu bir alan eksikse veya String değilse [FormatException] fırlatır.
  /// "turkish" ve "fullForm" alanları isteğe bağlıdır.
  factory Term.fromJson(Map<String, dynamic> json) {
    return Term(
      term: _readString(json, 'term'),
      category: _readString(json, 'category'),
      definition: _readString(json, 'definition'),
      exampleSentence: _readString(json, 'exampleSentence'),
      turkish: json.containsKey('turkish') ? _readString(json, 'turkish') : '',
      fullForm:
          json.containsKey('fullForm') ? _readString(json, 'fullForm') : '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'term': term,
      'fullForm': fullForm,
      'turkish': turkish,
      'category': category,
      'definition': definition,
      'exampleSentence': exampleSentence,
    };
  }

  static String _readString(Map<String, dynamic> json, String key) {
    final Object? value = json[key];
    if (value == null) {
      throw FormatException('Term JSON verisinde "$key" alanı eksik.', json);
    }
    if (value is! String) {
      throw FormatException(
        'Term JSON verisinde "$key" alanı String olmalı, '
        'ama ${value.runtimeType} geldi.',
        json,
      );
    }
    return value;
  }

  @override
  String toString() => 'Term($term, $category)';
}
