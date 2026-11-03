import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/term.dart';

/// Bir quiz turunun sonucu.
class QuizScore {
  const QuizScore(this.score, this.total);

  final int score;
  final int total;

  /// [other]'dan daha yüksek oranda doğru mu.
  bool isBetterThan(QuizScore other) => score * other.total > other.score * total;
}

/// Öğrenilen kelimeleri, quiz skorlarını, Review destesini, favorileri ve
/// günlük hedefi cihazda saklar.
///
/// Uygulama genelinde tek bir örnek kullanılır: `ProgressService.instance`.
/// Değişince dinleyicilere haber verir; kartlardaki ilerleme çubukları
/// böylece kendiliğinden güncellenir.
class ProgressService extends ChangeNotifier {
  ProgressService._() : _now = DateTime.now;

  /// Testlerde birbirinden bağımsız örnekler oluşturmak için. [now] verilirse
  /// "bugün" ondan hesaplanır.
  @visibleForTesting
  ProgressService.forTest({DateTime Function()? now})
      : _now = now ?? DateTime.now;

  static final ProgressService instance = ProgressService._();

  static const String _learnedKey = 'learnedTerms';
  static const String _scoresKey = 'bestQuizScores';
  static const String _reviewKey = 'reviewTerms';
  static const String _favoritesKey = 'favoriteTerms';
  static const String _goalKey = 'dailyGoal';
  static const String _practiceDayKey = 'practiceDay';
  static const String _practiceCountKey = 'practiceCount';
  static const String _streakKey = 'streak';
  static const String _bestStreakKey = 'bestStreak';
  static const String _lastGoalDayKey = 'lastGoalDay';

  /// Varsayılan günlük hedef (günde bitirilecek quiz sorusu).
  static const int defaultDailyGoal = 10;

  /// Kullanıcının seçebileceği günlük hedefler.
  static const List<int> dailyGoalOptions = <int>[5, 10, 20, 30];

  final DateTime Function() _now;

  /// Review destesindeki bir kelimenin desteden çıkması için art arda kaç
  /// kez ilk denemede doğru bilinmesi gerektiği.
  static const int reviewCorrectNeeded = 2;

  SharedPreferences? _prefs;
  Future<void>? _loadFuture;
  final Set<String> _learned = <String>{};
  final Map<String, QuizScore> _bestScores = <String, QuizScore>{};

  /// Review destesi: kelime anahtarı → desteden çıkması için kalan doğru
  /// cevap sayısı.
  final Map<String, int> _review = <String, int>{};

  /// Yıldızlanan kelimelerin anahtarları.
  final Set<String> _favorites = <String>{};

  int _dailyGoal = defaultDailyGoal;

  /// [_practiceCount]'un ait olduğu gün ("yyyy-mm-dd").
  String? _practiceDay;
  int _practiceCount = 0;

  /// Hedefin tutturulduğu son güne kadar art arda gün sayısı.
  int _streak = 0;
  int _bestStreak = 0;

  /// Hedefin en son tutturulduğu gün ("yyyy-mm-dd").
  String? _lastGoalDay;

  /// Kayıtlı ilerlemeyi bir kez okur. Hata olursa ilerleme boş kalır ve
  /// sonraki çağrıda yeniden denenir.
  Future<void> load() => _loadFuture ??= _load();

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      _learned
        ..clear()
        ..addAll(prefs.getStringList(_learnedKey) ?? const <String>[]);
      _bestScores
        ..clear()
        ..addAll(_decodeScores(prefs.getString(_scoresKey)));
      _review
        ..clear()
        ..addAll(_decodeReview(prefs.getString(_reviewKey)));
      _favorites
        ..clear()
        ..addAll(prefs.getStringList(_favoritesKey) ?? const <String>[]);
      final int goal = prefs.getInt(_goalKey) ?? defaultDailyGoal;
      _dailyGoal = goal > 0 ? goal : defaultDailyGoal;
      _practiceDay = prefs.getString(_practiceDayKey);
      _practiceCount = prefs.getInt(_practiceCountKey) ?? 0;
      _streak = prefs.getInt(_streakKey) ?? 0;
      _bestStreak = prefs.getInt(_bestStreakKey) ?? 0;
      _lastGoalDay = prefs.getString(_lastGoalDayKey);
      notifyListeners();
    } catch (error) {
      _loadFuture = null;
      debugPrint('ProgressService.load hatası: $error');
    }
  }

  /// [raw] JSON nesnesini okur; yoksa ya da bozuksa boş döner.
  static Map<String, dynamic> _decodeMap(String? raw) {
    if (raw == null) {
      return const <String, dynamic>{};
    }
    try {
      final Object? decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic>
          ? decoded
          : const <String, dynamic>{};
    } on FormatException {
      return const <String, dynamic>{};
    }
  }

  static Map<String, QuizScore> _decodeScores(String? raw) {
    return <String, QuizScore>{
      for (final MapEntry<String, dynamic> entry in _decodeMap(raw).entries)
        if (entry.value case [final int score, final int total])
          entry.key: QuizScore(score, total),
    };
  }

  static Map<String, int> _decodeReview(String? raw) {
    return <String, int>{
      for (final MapEntry<String, dynamic> entry in _decodeMap(raw).entries)
        if (entry.value case final int remaining when remaining > 0)
          entry.key: remaining,
    };
  }

  // Terimler bölümler arasında tekrar etmediği için anahtar olarak yeterli.
  static String _keyOf(Term term) => term.term.toLowerCase();

  bool isLearned(Term term) => _learned.contains(_keyOf(term));

  /// [terms] içinden kaç tanesinin öğrenildiği.
  int learnedCount(Iterable<Term> terms) => terms.where(isLearned).length;

  /// [quizId] quiz'inde şimdiye kadarki en iyi sonuç; hiç oynanmadıysa null.
  QuizScore? bestScore(String quizId) => _bestScores[quizId];

  /// [term] Review destesinde mi.
  bool isInReview(Term term) => _review.containsKey(_keyOf(term));

  /// Review destesindeki kelime sayısı.
  int get reviewCount => _review.length;

  /// [term] yıldızlanmış mı.
  bool isFavorite(Term term) => _favorites.contains(_keyOf(term));

  /// Yıldızlanan kelime sayısı.
  int get favoriteCount => _favorites.length;

  /// Günde bitirilmesi hedeflenen quiz sorusu sayısı.
  int get dailyGoal => _dailyGoal;

  /// Bugün bitirilen quiz sorusu sayısı.
  int get todayCount => _practiceDay == _today ? _practiceCount : 0;

  /// Bugünün hedefi tutturuldu mu.
  bool get goalReachedToday => _lastGoalDay == _today;

  /// Hedefin art arda tutturulduğu gün sayısı. Dün de bugün de tutturulmadıysa
  /// seri bozulmuştur ve 0 döner.
  int get streak =>
      _lastGoalDay == _today || _lastGoalDay == _yesterday ? _streak : 0;

  /// Şimdiye kadarki en uzun seri.
  int get bestStreak => _bestStreak;

  String get _today => _dayOf(_now());

  String get _yesterday {
    final DateTime now = _now();
    return _dayOf(DateTime(now.year, now.month, now.day - 1));
  }

  static String _dayOf(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Bitirilen bir quiz sorusunu bugünün sayacına ekler.
  ///
  /// Bu soruyla günlük hedef tutturulduysa true döner (kutlama için).
  Future<bool> recordPractice() async {
    await load();
    final String today = _today;
    if (_practiceDay != today) {
      _practiceDay = today;
      _practiceCount = 0;
    }
    _practiceCount++;
    final bool reachedNow = _checkGoal();
    notifyListeners();
    await _persist(_saveDaily);
    return reachedNow;
  }

  /// Günlük hedefi değiştirir. Bugünkü sayı yeni hedefe zaten ulaşıyorsa
  /// hedef tutturulmuş sayılır.
  Future<void> setDailyGoal(int goal) async {
    await load();
    if (goal <= 0 || goal == _dailyGoal) {
      return;
    }
    _dailyGoal = goal;
    _checkGoal();
    notifyListeners();
    await _persist(_saveDaily);
  }

  /// Bugünkü sayı hedefe ulaştıysa ve bugün daha önce ulaşılmadıysa seriyi
  /// günceller ve true döner.
  bool _checkGoal() {
    final String today = _today;
    if (todayCount < _dailyGoal || _lastGoalDay == today) {
      return false;
    }
    _streak = _lastGoalDay == _yesterday ? _streak + 1 : 1;
    if (_streak > _bestStreak) {
      _bestStreak = _streak;
    }
    _lastGoalDay = today;
    return true;
  }

  Future<bool> _saveDaily(SharedPreferences prefs) async {
    final List<bool> results = await Future.wait(<Future<bool>>[
      prefs.setInt(_goalKey, _dailyGoal),
      prefs.setString(_practiceDayKey, _practiceDay ?? ''),
      prefs.setInt(_practiceCountKey, _practiceCount),
      prefs.setInt(_streakKey, _streak),
      prefs.setInt(_bestStreakKey, _bestStreak),
      prefs.setString(_lastGoalDayKey, _lastGoalDay ?? ''),
    ]);
    return results.every((bool saved) => saved);
  }

  /// [term]'i favorilere ekler; zaten favoriyse çıkarır.
  Future<void> toggleFavorite(Term term) async {
    await load();
    final String key = _keyOf(term);
    if (!_favorites.remove(key)) {
      _favorites.add(key);
    }
    notifyListeners();
    await _persist(
      (SharedPreferences prefs) =>
          prefs.setStringList(_favoritesKey, _favorites.toList()),
    );
  }

  /// Bir quiz cevabını kaydeder.
  ///
  /// İlk denemede doğru bilinen kelime öğrenilmiş sayılır ve Review'dan
  /// çıkmaya bir adım yaklaşır. Yanlış bilinen kelime öğrenilmiş sayılmaz
  /// ve Review destesine girer (zaten oradaysa sayacı baştan başlar).
  Future<void> recordAnswer(Term term, {required bool correct}) async {
    await load();
    final String key = _keyOf(term);
    bool changed;
    if (correct) {
      changed = _learned.add(key);
      final int? remaining = _review[key];
      if (remaining != null) {
        if (remaining <= 1) {
          _review.remove(key);
        } else {
          _review[key] = remaining - 1;
        }
        changed = true;
      }
    } else {
      changed = _learned.remove(key);
      if (_review[key] != reviewCorrectNeeded) {
        _review[key] = reviewCorrectNeeded;
        changed = true;
      }
    }
    if (!changed) {
      return;
    }
    notifyListeners();
    await _persist((SharedPreferences prefs) async {
      final bool learnedSaved =
          await prefs.setStringList(_learnedKey, _learned.toList());
      final bool reviewSaved =
          await prefs.setString(_reviewKey, jsonEncode(_review));
      return learnedSaved && reviewSaved;
    });
  }

  /// [term]'i öğrenildi ya da öğrenilmedi olarak işaretler.
  Future<void> setLearned(Term term, {required bool learned}) async {
    await load();
    final String key = _keyOf(term);
    final bool changed = learned ? _learned.add(key) : _learned.remove(key);
    if (!changed) {
      return;
    }
    notifyListeners();
    await _persist(
      (SharedPreferences prefs) =>
          prefs.setStringList(_learnedKey, _learned.toList()),
    );
  }

  /// Bir quiz turunun sonucunu kaydeder; önceki en iyi sonuçtan iyiyse
  /// onun yerine geçer.
  Future<void> recordQuiz(String quizId, int score, int total) async {
    if (total <= 0) {
      return;
    }
    await load();
    final QuizScore result = QuizScore(score, total);
    final QuizScore? best = _bestScores[quizId];
    if (best != null && !result.isBetterThan(best)) {
      return;
    }
    _bestScores[quizId] = result;
    notifyListeners();
    await _persist(
      (SharedPreferences prefs) => prefs.setString(
        _scoresKey,
        jsonEncode(<String, List<int>>{
          for (final MapEntry<String, QuizScore> entry in _bestScores.entries)
            entry.key: <int>[entry.value.score, entry.value.total],
        }),
      ),
    );
  }

  Future<void> _persist(
    Future<bool> Function(SharedPreferences prefs) write,
  ) async {
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) {
      return;
    }
    try {
      await write(prefs);
    } catch (error) {
      debugPrint('ProgressService kayıt hatası: $error');
    }
  }
}
