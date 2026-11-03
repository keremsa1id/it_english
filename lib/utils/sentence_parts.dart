/// Cümlenin bir parçası. [isTerm] true ise öğrenilen terimdir.
class SentencePart {
  const SentencePart(this.text, {this.isTerm = false});

  final String text;
  final bool isTerm;

  @override
  bool operator ==(Object other) =>
      other is SentencePart && other.text == text && other.isTerm == isTerm;

  @override
  int get hashCode => Object.hash(text, isTerm);

  @override
  String toString() => 'SentencePart("$text", $isTerm)';
}

/// [sentence] içinde [term] teriminin geçtiği yerleri ayırır.
///
/// Büyük/küçük harfe bakılmaz ve yalnızca tam kelime eşleşir: "bug",
/// "debugging" içinde bulunmaz. Tire içeren terimler ("Wi-Fi") de tek parça
/// sayılır. Terim bulunamazsa cümlenin tamamı tek parça olarak döner.
///
/// Cümleler ekranı terimi vurgulamak, Quiz ise yerine boşluk koymak için
/// kullanır.
List<SentencePart> splitSentence(String sentence, String term) {
  final String target = term.trim();
  if (target.isEmpty) {
    return <SentencePart>[SentencePart(sentence)];
  }

  // \b tire karakterini kelime sınırı saydığı için ayrı kontrol ediliyor.
  final RegExp pattern = RegExp(
    '(?<![\\w-])${RegExp.escape(target)}(?![\\w-])',
    caseSensitive: false,
  );
  final List<SentencePart> parts = <SentencePart>[];
  int start = 0;
  for (final RegExpMatch match in pattern.allMatches(sentence)) {
    if (match.start > start) {
      parts.add(SentencePart(sentence.substring(start, match.start)));
    }
    parts.add(SentencePart(match[0]!, isTerm: true));
    start = match.end;
  }
  if (start < sentence.length) {
    parts.add(SentencePart(sentence.substring(start)));
  }
  return parts.isEmpty ? <SentencePart>[SentencePart(sentence)] : parts;
}
