import 'sentence_parts.dart';

/// Yazılan [input] cevabının [term] ile aynı olup olmadığı.
///
/// Büyük/küçük harf, boşluklar ve noktalama (tire, eğik çizgi, kesme
/// işareti...) önemsenmez: "wifi", "Wi-Fi" için doğru sayılır. Boş cevap
/// hiçbir zaman doğru değildir.
bool isCorrectAnswer(String input, String term) {
  final String answer = _normalize(input);
  return answer.isNotEmpty && answer == _normalize(term);
}

/// Ses tanımanın döndürdüğü tahminlerden ([heard]) biri [term] ise true.
///
/// Tahmin tam olarak terim olabilir ("Firewall.") ya da terimi tek başına
/// içerebilir ("the firewall"); kısaltmalar harf harf söylenebilir
/// ("s q l" → "SQL").
bool isSpokenMatch(List<String> heard, String term) {
  return heard.any(
    (String text) =>
        isCorrectAnswer(text, term) ||
        splitSentence(text, term).any((SentencePart part) => part.isTerm),
  );
}

final RegExp _ignored = RegExp(r'[^\p{L}\p{N}]', unicode: true);

String _normalize(String text) => text.toLowerCase().replaceAll(_ignored, '');
