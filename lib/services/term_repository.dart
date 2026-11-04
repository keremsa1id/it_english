import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../models/term.dart';

/// Terim verisi okunamadığında veya bozuk olduğunda fırlatılır.
class TermRepositoryException implements Exception {
  const TermRepositoryException(this.message, [this.cause]);

  /// Kullanıcıya gösterilebilecek kısa açıklama.
  final String message;

  /// Asıl hata (hata ayıklama için).
  final Object? cause;

  @override
  String toString() => 'TermRepositoryException: $message'
      '${cause == null ? '' : ' ($cause)'}';
}

/// Terimleri assets/data/ altındaki JSON dosyasından okur.
class TermRepository {
  const TermRepository({this.assetPath = defaultAssetPath});

  static const String defaultAssetPath = 'assets/data/it_terms_1.json';

  final String assetPath;

  /// [assetPath] dosyasındaki terimleri dosyadaki sırayla yükler.
  ///
  /// Dosya boşsa boş liste döner. Dosya bulunamazsa ya da JSON biçimi
  /// hatalıysa [TermRepositoryException] fırlatır.
  Future<List<Term>> loadTerms() async {
    final String raw;
    try {
      raw = await rootBundle.loadString(assetPath);
    } catch (error) {
      throw TermRepositoryException('Could not open the word list.', error);
    }

    if (raw.trim().isEmpty) {
      return const <Term>[];
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw TermRepositoryException('Could not read the word list.', error);
    }

    if (decoded is! List) {
      throw const TermRepositoryException('The word list must be a list.');
    }

    final List<Term> terms = <Term>[];
    for (int i = 0; i < decoded.length; i++) {
      final Object? item = decoded[i];
      if (item is! Map<String, dynamic>) {
        throw TermRepositoryException('Entry ${i + 1} in the word list is invalid.');
      }
      try {
        terms.add(Term.fromJson(item));
      } on FormatException catch (error) {
        throw TermRepositoryException(
          'Entry ${i + 1} in the word list is invalid.',
          error,
        );
      }
    }
    return List<Term>.unmodifiable(terms);
  }

  /// [loadTerms] gibi yükler ama terimleri rastgele sıraya dizer;
  /// böylece ekran her açılışta farklı bir terimle başlar.
  Future<List<Term>> loadShuffledTerms({Random? random}) async {
    final List<Term> terms = List<Term>.of(await loadTerms())..shuffle(random);
    return List<Term>.unmodifiable(terms);
  }
}

/// Birden çok JSON dosyasındaki terimleri tek listede birleştirir.
/// Karışık quiz bütün bölümlerin kelimelerini bununla yükler.
class MixedTermRepository extends TermRepository {
  const MixedTermRepository(this.assetPaths);

  final List<String> assetPaths;

  @override
  Future<List<Term>> loadTerms() async {
    final List<Term> terms = <Term>[];
    for (final String path in assetPaths) {
      terms.addAll(await TermRepository(assetPath: path).loadTerms());
    }
    return List<Term>.unmodifiable(terms);
  }
}

/// [source] deposundan yalnızca [include]'u sağlayan terimleri yükler;
/// Review ve Favorites kartları seçili kelimeleri bununla gösterir.
class FilteredTermRepository extends TermRepository {
  const FilteredTermRepository(this.source, {required this.include});

  final TermRepository source;
  final bool Function(Term term) include;

  @override
  Future<List<Term>> loadTerms() async {
    final List<Term> terms = await source.loadTerms();
    return List<Term>.unmodifiable(terms.where(include));
  }
}
