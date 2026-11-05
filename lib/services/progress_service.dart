import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/term.dart';

/// Yedekteki bir kaydın türü.
enum _BackupType { string, integer, stringList }

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
  static const String _repetitionKey = 'spacedRepetition';
  static const String _historyKey = 'practiceHistory';
  static const String _mistakesKey = 'mistakeCounts';
  static const String _studyTotalKey = 'studyTotalSeconds';
  static const String _studyDaysKey = 'studyDays';
  static const String _quizzesKey = 'quizzesCompleted';
  static const String _perfectQuizzesKey = 'perfectQuizzes';
  static const String _earnedKey = 'earnedAchievements';
  static const String _todayWordsKey = 'todayWords';
  static const String _todayWordsDayKey = 'todayWordsDay';
  static const String _reminderEnabledKey = 'reminderEnabled';
  static const String _reminderMinutesKey = 'reminderMinutes';

  /// Varsayılan hatırlatma saati: 20:00 (gün başından itibaren dakika).
  static const int defaultReminderMinutes = 20 * 60;

  /// Yedek biçiminin sürümü; biçim değişirse artırılır.
  static const int backupVersion = 1;

  /// Yedeğe giren kayıtlar ve türleri. Yedekte olmayan ya da türü uymayan
  /// anahtarlar geri yüklenmez.
  static const Map<String, _BackupType> _backupKeys = <String, _BackupType>{
    _learnedKey: _BackupType.stringList,
    _scoresKey: _BackupType.string,
    _reviewKey: _BackupType.string,
    _favoritesKey: _BackupType.stringList,
    _goalKey: _BackupType.integer,
    _practiceDayKey: _BackupType.string,
    _practiceCountKey: _BackupType.integer,
    _streakKey: _BackupType.integer,
    _bestStreakKey: _BackupType.integer,
    _lastGoalDayKey: _BackupType.string,
    _repetitionKey: _BackupType.string,
    _historyKey: _BackupType.string,
    _mistakesKey: _BackupType.string,
    _studyTotalKey: _BackupType.integer,
    _studyDaysKey: _BackupType.string,
    _quizzesKey: _BackupType.integer,
    _perfectQuizzesKey: _BackupType.integer,
    _earnedKey: _BackupType.stringList,
  };

  /// Gün gün istatistikler (soru sayısı, süre) bu kadar gün saklanır.
  static const int historyDays = 60;

  /// Tek bir çalışma oturumundan en fazla bu kadar süre sayılır; ekran açık
  /// unutulursa istatistik şişmesin.
  static const Duration maxSession = Duration(minutes: 30);

  /// Aralıklı tekrar: doğru bilinen kelime bu kadar gün sonra yeniden
  /// sorulur. Hepsi geçilince kelime kalıcı öğrenilmiş sayılır.
  static const List<int> repetitionDays = <int>[1, 3, 7, 30];

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

  /// Aralıklı tekrar takvimi: kelime anahtarı → (tamamlanan aşama, tekrar
  /// günü "yyyy-mm-dd"). Tekrar günü boşsa kelime kalıcı öğrenilmiştir.
  final Map<String, (int, String)> _repetitions = <String, (int, String)>{};

  /// Gün ("yyyy-mm-dd") → o gün bitirilen soru sayısı.
  final Map<String, int> _history = <String, int>{};

  /// Kelime anahtarı → toplam yanlış cevap sayısı.
  final Map<String, int> _mistakes = <String, int>{};

  /// Gün → o gün quiz ve oyunlarda geçen saniye.
  final Map<String, int> _studyDays = <String, int>{};
  int _studyTotalSeconds = 0;
  int _quizzesCompleted = 0;

  /// Bütün soruları ilk denemede doğru bilinen quiz turu sayısı.
  int _perfectQuizzes = 0;

  /// Kazanılmış rozetlerin kimlikleri; bir kez kazanılan rozet kaybolmaz.
  final Set<String> _earned = <String>{};

  /// Günün kelimeleri (anahtarlar) ve seçildikleri gün.
  List<String> _todayWords = const <String>[];
  String? _todayWordsDay;

  bool _reminderEnabled = false;
  int _reminderMinutes = defaultReminderMinutes;

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
      _repetitions
        ..clear()
        ..addAll(_decodeRepetitions(prefs.getString(_repetitionKey)));
      final int goal = prefs.getInt(_goalKey) ?? defaultDailyGoal;
      _dailyGoal = goal > 0 ? goal : defaultDailyGoal;
      _practiceDay = prefs.getString(_practiceDayKey);
      _practiceCount = prefs.getInt(_practiceCountKey) ?? 0;
      _streak = prefs.getInt(_streakKey) ?? 0;
      _bestStreak = prefs.getInt(_bestStreakKey) ?? 0;
      _lastGoalDay = prefs.getString(_lastGoalDayKey);
      _history
        ..clear()
        ..addAll(_decodeIntMap(prefs.getString(_historyKey)));
      _mistakes
        ..clear()
        ..addAll(_decodeIntMap(prefs.getString(_mistakesKey)));
      _studyDays
        ..clear()
        ..addAll(_decodeIntMap(prefs.getString(_studyDaysKey)));
      _studyTotalSeconds = prefs.getInt(_studyTotalKey) ?? 0;
      _quizzesCompleted = prefs.getInt(_quizzesKey) ?? 0;
      _perfectQuizzes = prefs.getInt(_perfectQuizzesKey) ?? 0;
      _earned
        ..clear()
        ..addAll(prefs.getStringList(_earnedKey) ?? const <String>[]);
      _todayWords = prefs.getStringList(_todayWordsKey) ?? const <String>[];
      _todayWordsDay = prefs.getString(_todayWordsDayKey);
      _reminderEnabled = prefs.getBool(_reminderEnabledKey) ?? false;
      final int minutes =
          prefs.getInt(_reminderMinutesKey) ?? defaultReminderMinutes;
      _reminderMinutes =
          minutes >= 0 && minutes < 24 * 60 ? minutes : defaultReminderMinutes;
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

  static Map<String, int> _decodeIntMap(String? raw) {
    return <String, int>{
      for (final MapEntry<String, dynamic> entry in _decodeMap(raw).entries)
        if (entry.value case final int value when value >= 0)
          entry.key: value,
    };
  }

  static Map<String, (int, String)> _decodeRepetitions(String? raw) {
    return <String, (int, String)>{
      for (final MapEntry<String, dynamic> entry in _decodeMap(raw).entries)
        if (entry.value case [final int stage, final String due])
          entry.key: (stage, due),
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

  /// [term]'in aralıklı tekrar günü geldi mi.
  bool isDue(Term term) => _isDueEntry(_repetitions[_keyOf(term)]);

  bool _isDueEntry((int, String)? entry) =>
      entry != null && entry.$2.isNotEmpty && entry.$2.compareTo(_today) <= 0;

  /// Tekrar günü gelmiş kelime sayısı.
  int get dueCount => _repetitions.values.where(_isDueEntry).length;

  /// [term] bütün tekrar aşamalarını geçti mi (kalıcı öğrenildi mi).
  bool isMastered(Term term) => _repetitions[_keyOf(term)]?.$2.isEmpty ?? false;

  /// [term] Review ekranında çalışılmalı mı: yanlış bilinmiş ya da tekrar
  /// günü gelmiş.
  bool needsReview(Term term) => isInReview(term) || isDue(term);

  /// Review ekranındaki kelime sayısı (yanlışlar + tekrar günü gelenler).
  int get reviewTotal => <String>{
        ..._review.keys,
        for (final MapEntry<String, (int, String)> entry
            in _repetitions.entries)
          if (_isDueEntry(entry.value)) entry.key,
      }.length;

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
    _history[today] = (_history[today] ?? 0) + 1;
    _pruneOldDays(_history);
    final bool reachedNow = _checkGoal();
    notifyListeners();
    await _persist((SharedPreferences prefs) async {
      final bool dailySaved = await _saveDaily(prefs);
      final bool historySaved =
          await prefs.setString(_historyKey, jsonEncode(_history));
      return dailySaved && historySaved;
    });
    return reachedNow;
  }

  /// [days] içinden [historyDays] günden eski kayıtları siler.
  void _pruneOldDays(Map<String, int> days) {
    final String oldest = _dayAfter(-historyDays);
    days.removeWhere((String day, int value) => day.compareTo(oldest) < 0);
  }

  /// Bir quiz ya da oyun ekranında geçen süreyi ekler; tek oturumdan en
  /// fazla [maxSession] sayılır.
  Future<void> addStudyTime(Duration duration) async {
    if (duration <= Duration.zero) {
      return;
    }
    await load();
    final int seconds =
        (duration > maxSession ? maxSession : duration).inSeconds;
    if (seconds == 0) {
      return;
    }
    final String today = _today;
    _studyDays[today] = (_studyDays[today] ?? 0) + seconds;
    _pruneOldDays(_studyDays);
    _studyTotalSeconds += seconds;
    notifyListeners();
    await _persist((SharedPreferences prefs) async {
      final bool daysSaved =
          await prefs.setString(_studyDaysKey, jsonEncode(_studyDays));
      final bool totalSaved =
          await prefs.setInt(_studyTotalKey, _studyTotalSeconds);
      return daysSaved && totalSaved;
    });
  }

  /// Son [days] günün (bugün dahil, eskiden yeniye) bitirilen soru sayıları.
  List<(DateTime, int)> recentPractice({int days = 7}) {
    final DateTime now = _now();
    final List<(DateTime, int)> result = <(DateTime, int)>[];
    for (int i = days - 1; i >= 0; i--) {
      final DateTime day = DateTime(now.year, now.month, now.day - i);
      result.add((day, _history[_dayOf(day)] ?? 0));
    }
    return result;
  }

  /// En çok yanlış yapılan [count] kelimenin anahtarları ve yanlış sayıları,
  /// en çoktan aza.
  List<(String, int)> mostMissed({int count = 10}) {
    final List<MapEntry<String, int>> entries = _mistakes.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
          b.value.compareTo(a.value));
    return <(String, int)>[
      for (final MapEntry<String, int> entry in entries.take(count))
        (entry.key, entry.value),
    ];
  }

  /// Bugün quiz ve oyunlarda geçen süre.
  Duration get studyTimeToday => Duration(seconds: _studyDays[_today] ?? 0);

  /// Toplam quiz ve oyun süresi.
  Duration get studyTimeTotal => Duration(seconds: _studyTotalSeconds);

  /// Bitirilen quiz turu sayısı (skordan bağımsız).
  int get quizzesCompleted => _quizzesCompleted;

  /// Öğrenilmiş kelime sayısı.
  int get learnedTotal => _learned.length;

  /// Bütün tekrar aşamalarını geçmiş (kalıcı öğrenilmiş) kelime sayısı.
  int get masteredTotal =>
      _repetitions.values.where(((int, String) e) => e.$2.isEmpty).length;

  /// Kelime anahtarı (bkz. [keyOf]) ile terimi eşleştirmek için.
  static String keyOf(Term term) => _keyOf(term);

  /// [keys] (bkz. [keyOf]) içinden kaç kelimenin öğrenildiği.
  int learnedAmong(Iterable<String> keys) => keys.where(_learned.contains).length;

  /// Bütün soruları ilk denemede doğru bilinen quiz turu sayısı.
  int get perfectQuizzes => _perfectQuizzes;

  /// [id] rozeti kazanıldı mı.
  bool isEarned(String id) => _earned.contains(id);

  /// Bugünün tarihi (saat bilgisi olmadan).
  DateTime get today {
    final DateTime now = _now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Bugün için seçilmiş kelimelerin anahtarları; bugün henüz seçilmediyse
  /// boş.
  List<String> get todayWordKeys =>
      _todayWordsDay == _today ? _todayWords : const <String>[];

  /// [term] bugünün kelimelerinden mi.
  bool isTodayWord(Term term) => todayWordKeys.contains(_keyOf(term));

  /// Günlük hatırlatma bildirimi açık mı.
  bool get reminderEnabled => _reminderEnabled;

  /// Hatırlatma saati, gün başından itibaren dakika (ör. 20:00 → 1200).
  int get reminderMinutes => _reminderMinutes;

  /// Hatırlatma ayarlarını değiştirir; verilmeyen değer aynen kalır.
  Future<void> setReminder({bool? enabled, int? minutes}) async {
    await load();
    if (minutes != null && (minutes < 0 || minutes >= 24 * 60)) {
      throw RangeError.range(minutes, 0, 24 * 60 - 1, 'minutes');
    }
    _reminderEnabled = enabled ?? _reminderEnabled;
    _reminderMinutes = minutes ?? _reminderMinutes;
    notifyListeners();
    await _persist((SharedPreferences prefs) async {
      final bool enabledSaved =
          await prefs.setBool(_reminderEnabledKey, _reminderEnabled);
      final bool minutesSaved =
          await prefs.setInt(_reminderMinutesKey, _reminderMinutes);
      return enabledSaved && minutesSaved;
    });
  }

  /// Bugünün kelimelerini kaydeder; ertesi gün geçersiz olur.
  Future<void> setTodayWords(List<String> keys) async {
    await load();
    _todayWords = List<String>.unmodifiable(keys);
    _todayWordsDay = _today;
    notifyListeners();
    await _persist((SharedPreferences prefs) async {
      final bool wordsSaved =
          await prefs.setStringList(_todayWordsKey, _todayWords);
      final bool daySaved = await prefs.setString(_todayWordsDayKey, _today);
      return wordsSaved && daySaved;
    });
  }

  /// Rozetleri kazanılmış olarak işaretler. Bellekteki durum hemen değişir;
  /// kayıt arkada yapılır.
  void markEarned(Iterable<String> ids) {
    final int before = _earned.length;
    _earned.addAll(ids);
    if (_earned.length == before) {
      return;
    }
    notifyListeners();
    _persist(
      (SharedPreferences prefs) =>
          prefs.setStringList(_earnedKey, _earned.toList()),
    );
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
  /// çıkmaya bir adım yaklaşır; Review'da değilse aralıklı tekrar takviminde
  /// ilerler (bkz. [repetitionDays]). Yanlış bilinen kelime öğrenilmiş
  /// sayılmaz, Review destesine girer (zaten oradaysa sayacı baştan başlar)
  /// ve tekrar takvimi sıfırlanır.
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
      if (!_review.containsKey(key) && _advanceRepetition(key)) {
        changed = true;
      }
    } else {
      changed = _learned.remove(key);
      if (_review[key] != reviewCorrectNeeded) {
        _review[key] = reviewCorrectNeeded;
        changed = true;
      }
      if (_repetitions.remove(key) != null) {
        changed = true;
      }
      _mistakes[key] = (_mistakes[key] ?? 0) + 1;
      changed = true;
    }
    if (!changed) {
      return;
    }
    notifyListeners();
    await _persist((SharedPreferences prefs) async {
      final List<bool> results = await Future.wait(<Future<bool>>[
        prefs.setStringList(_learnedKey, _learned.toList()),
        prefs.setString(_reviewKey, jsonEncode(_review)),
        prefs.setString(_mistakesKey, jsonEncode(_mistakes)),
        prefs.setString(
          _repetitionKey,
          jsonEncode(<String, List<Object>>{
            for (final MapEntry<String, (int, String)> entry
                in _repetitions.entries)
              entry.key: <Object>[entry.value.$1, entry.value.$2],
          }),
        ),
      ]);
      return results.every((bool saved) => saved);
    });
  }

  /// Doğru bilinen kelimenin tekrar takvimini ilerletir; değiştiyse true.
  ///
  /// İlk kez öğrenilen kelime 1 gün sonraya planlanır. Tekrar günü gelmiş
  /// kelime bir sonraki aralığa geçer; son aralık da geçilince kalıcı
  /// öğrenilmiş sayılır. Günü gelmemiş kelimede değişiklik olmaz.
  bool _advanceRepetition(String key) {
    final (int, String)? entry = _repetitions[key];
    if (entry == null) {
      _repetitions[key] = (1, _dayAfter(repetitionDays.first));
      return true;
    }
    if (!_isDueEntry(entry)) {
      return false;
    }
    final int next = entry.$1 + 1;
    _repetitions[key] = next > repetitionDays.length
        ? (next, '')
        : (next, _dayAfter(repetitionDays[next - 1]));
    return true;
  }

  String _dayAfter(int days) {
    final DateTime now = _now();
    return _dayOf(DateTime(now.year, now.month, now.day + days));
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
    _quizzesCompleted++;
    final bool perfect = score == total;
    if (perfect) {
      _perfectQuizzes++;
    }
    final QuizScore result = QuizScore(score, total);
    final QuizScore? best = _bestScores[quizId];
    final bool isBest = best == null || result.isBetterThan(best);
    if (isBest) {
      _bestScores[quizId] = result;
    }
    notifyListeners();
    await _persist((SharedPreferences prefs) async {
      bool countSaved = await prefs.setInt(_quizzesKey, _quizzesCompleted);
      if (perfect) {
        countSaved &=
            await prefs.setInt(_perfectQuizzesKey, _perfectQuizzes);
      }
      if (!isBest) {
        return countSaved;
      }
      final bool scoresSaved = await prefs.setString(
        _scoresKey,
        jsonEncode(<String, List<int>>{
          for (final MapEntry<String, QuizScore> entry in _bestScores.entries)
            entry.key: <int>[entry.value.score, entry.value.total],
        }),
      );
      return countSaved && scoresSaved;
    });
  }

  /// Bütün ilerlemeyi tek bir JSON metni olarak döndürür (kelime listeleri
  /// değil, yalnızca kullanıcının ilerlemesi).
  ///
  /// Kayıtlar okunamıyorsa [StateError] fırlatır.
  Future<String> exportBackup() async {
    await load();
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) {
      throw StateError('Progress could not be read on this device.');
    }
    return const JsonEncoder.withIndent(' ').convert(<String, Object>{
      'app': 'it_english',
      'version': backupVersion,
      'exportedAt': _now().toIso8601String(),
      'data': <String, Object>{
        for (final String key in _backupKeys.keys)
          if (prefs.get(key) case final Object value) key: value,
      },
    });
  }

  /// [raw] yedeğini geri yükler; mevcut ilerlemenin yerine geçer.
  ///
  /// Yedek geçersizse [FormatException] fırlatır ve mevcut ilerlemeye hiç
  /// dokunmaz: bütün değerler yazmadan önce kontrol edilir.
  Future<void> importBackup(String raw) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw.trim());
    } on FormatException {
      throw const FormatException('This is not a valid backup.');
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['app'] != 'it_english' ||
        decoded['data'] is! Map<String, dynamic>) {
      throw const FormatException('This is not an IT English backup.');
    }
    final Object? version = decoded['version'];
    if (version is! int || version > backupVersion) {
      throw const FormatException(
        'This backup was made by a newer version of the app.',
      );
    }

    final Map<String, dynamic> data = decoded['data'] as Map<String, dynamic>;
    final Map<String, Object> values = <String, Object>{};
    for (final MapEntry<String, _BackupType> entry in _backupKeys.entries) {
      final Object? value = data[entry.key];
      if (value == null) {
        continue;
      }
      final Object? checked = switch (entry.value) {
        _BackupType.string => value is String ? value : null,
        _BackupType.integer => value is int ? value : null,
        _BackupType.stringList => value is List && value.every((Object? e) => e is String)
            ? value.cast<String>().toList()
            : null,
      };
      if (checked == null) {
        throw FormatException('The backup is damaged ("${entry.key}").');
      }
      values[entry.key] = checked;
    }

    await load();
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) {
      throw StateError('Progress could not be saved on this device.');
    }
    for (final String key in _backupKeys.keys) {
      final Object? value = values[key];
      if (value == null) {
        await prefs.remove(key);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(key, value);
      }
    }
    // Yeni kayıtları belleğe oku ve ekranlara haber ver.
    _loadFuture = null;
    await load();
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
