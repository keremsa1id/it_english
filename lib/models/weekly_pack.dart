import 'section.dart';

/// Belirli bir tarihte açılan 40 kelimelik haftalık paket.
///
/// Paketlerin listesi assets/data/weekly/index.json dosyasındadır; her
/// paketin kelimeleri aynı klasördeki kendi dosyasındadır.
class WeeklyPack {
  const WeeklyPack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.file,
    required this.releaseDate,
  });

  /// Benzersiz kimlik, ör. "week_01".
  final String id;
  final String title;
  final String subtitle;

  /// Kelimelerin bulunduğu dosyanın adı, ör. "week_01.json".
  final String file;

  /// Paketin açıldığı gün (saat bilgisi yok).
  final DateTime releaseDate;

  /// index.json'daki bir kayıttan [WeeklyPack] oluşturur.
  ///
  /// Alan eksikse, String değilse ya da tarih "yyyy-mm-dd" biçiminde
  /// değilse [FormatException] fırlatır.
  factory WeeklyPack.fromJson(Map<String, dynamic> json) {
    String read(String key) {
      final Object? value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Paket kaydında "$key" alanı eksik.', json);
      }
      return value;
    }

    final DateTime date = DateTime.parse(read('releaseDate'));
    final String file = read('file');
    // Liste internetten de gelebildiği için yalnızca düz dosya adına izin
    // verilir ("../" gibi yollar reddedilir).
    if (!RegExp(r'^[A-Za-z0-9_-]+\.json$').hasMatch(file)) {
      throw FormatException('Geçersiz paket dosya adı: "$file".', json);
    }
    return WeeklyPack(
      id: read('id'),
      title: read('title'),
      subtitle: read('subtitle'),
      file: file,
      releaseDate: DateTime(date.year, date.month, date.day),
    );
  }

  /// [now] gününde paket açık mı.
  bool isReleasedOn(DateTime now) =>
      !DateTime(now.year, now.month, now.day).isBefore(releaseDate);

  /// Paket bir bölüm gibi gösterilir. [Section.assetPath] burada ilerleme ve
  /// skorların saklandığı benzersiz anahtardır (gerçek dosya yolu değil).
  Section toSection() => Section(
        title: title,
        subtitle: subtitle,
        kind: SectionKind.weekly,
        assetPath: 'pack:$id',
      );
}
