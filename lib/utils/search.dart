import '../models/term.dart';

const Map<String, String> _turkishFolds = <String, String>{
  'ç': 'c',
  'ğ': 'g',
  'ı': 'i',
  'ö': 'o',
  'ş': 's',
  'ü': 'u',
  'â': 'a',
  'î': 'i',
  'û': 'u',
  // "İ".toLowerCase() sonucu "i" + üstteki nokta işareti olur.
  '̇': '',
};

/// Arama için metni sadeleştirir: küçük harf, Türkçe karakterler Latin
/// karşılıklarına ("güvenlik" → "guvenlik"), fazla boşluklar teke iner.
String normalizeForSearch(String text) {
  final StringBuffer buffer = StringBuffer();
  for (final String char in text.toLowerCase().split('')) {
    buffer.write(_turkishFolds[char] ?? char);
  }
  return buffer.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// [term]'in [query] aramasına uygunluğu; küçük sayı daha iyi. Eşleşmiyorsa
/// null. [query] önceden [normalizeForSearch] ile sadeleştirilmiş olmalı.
///
/// 0: kelimenin tam kendisi, 1: kelime aramayla başlıyor, 2: kelimenin
/// içinde geçiyor, 3: Türkçesinde ya da kısaltma açılımında geçiyor.
int? searchRank(Term term, String query) {
  if (query.isEmpty) {
    return null;
  }
  final String name = normalizeForSearch(term.term);
  if (name == query) {
    return 0;
  }
  if (name.startsWith(query)) {
    return 1;
  }
  if (name.contains(query)) {
    return 2;
  }
  if (normalizeForSearch(term.turkish).contains(query) ||
      normalizeForSearch(term.fullForm).contains(query)) {
    return 3;
  }
  return null;
}
