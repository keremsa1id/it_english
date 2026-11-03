/// Yazılan [input] cevabının [term] ile aynı olup olmadığı.
///
/// Büyük/küçük harf, boşluklar ve noktalama (tire, eğik çizgi, kesme
/// işareti...) önemsenmez: "wifi", "Wi-Fi" için doğru sayılır. Boş cevap
/// hiçbir zaman doğru değildir.
bool isCorrectAnswer(String input, String term) {
  final String answer = _normalize(input);
  return answer.isNotEmpty && answer == _normalize(term);
}

final RegExp _ignored = RegExp(r'[^\p{L}\p{N}]', unicode: true);

String _normalize(String text) => text.toLowerCase().replaceAll(_ignored, '');
