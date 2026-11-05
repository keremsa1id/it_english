import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cihazdaki bir seslendirme sesi.
typedef TtsVoice = ({String name, String locale});

/// [voice]'un ne kadar doğal duyulduğuna dair puan; İngilizce değilse null.
///
/// En iyiler: Chrome'da "Google US English", Edge'de "Natural" Microsoft
/// sesleri, iPhone'da "Premium"/"Enhanced" sesler, Android'de ağ tabanlı
/// Google sesleri. Eşit puanda ABD İngilizcesi, sonra İngiliz İngilizcesi
/// önde gelir.
int? voiceScore(TtsVoice voice) {
  final String locale = voice.locale.toLowerCase().replaceAll('_', '-');
  if (!locale.startsWith('en')) {
    return null;
  }
  final String name = voice.name.toLowerCase();
  int score = 0;
  if (name.contains('google') && name.contains('english')) {
    score = 100;
  } else if (name.contains('natural')) {
    score = 90;
  } else if (name.contains('premium')) {
    score = 85;
  } else if (name.contains('enhanced')) {
    score = 80;
  } else if (name.contains('network')) {
    score = 70;
  } else if (name.contains('local')) {
    // Android'deki cihaz içi (daha düşük kaliteli) sesler.
    score = 10;
  } else {
    score = 30;
  }
  if (locale == 'en-us') {
    score += 5;
  } else if (locale == 'en-gb') {
    score += 3;
  }
  return score;
}

/// [voices] içinden en doğal İngilizce sesi seçer; hiç yoksa null.
TtsVoice? bestVoice(Iterable<TtsVoice> voices) {
  TtsVoice? best;
  int bestScore = -1;
  for (final TtsVoice voice in voices) {
    final int? score = voiceScore(voice);
    if (score != null && score > bestScore) {
      best = voice;
      bestScore = score;
    }
  }
  return best;
}

/// İngilizce terimleri ve cümleleri sesli okur.
///
/// Açılışta cihazdaki en doğal İngilizce sesi seçer (bkz. [bestVoice]);
/// kullanıcı başka bir ses seçtiyse ([selectVoice]) onu kullanır.
///
/// Uygulama genelinde tek bir örnek kullanılır: `TtsService.instance`.
class TtsService {
  TtsService._();

  static final TtsService instance = TtsService._();

  static const String language = 'en-US';
  static const double pitch = 1.0;
  static const double volume = 1.0;
  static const String _voiceKey = 'ttsVoice';

  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;
  Future<void>? _initFuture;

  /// Şu an kullanılan ses; cihazın varsayılanıysa null.
  TtsVoice? _currentVoice;

  /// Normalden biraz yavaş, anlaşılır konuşma hızı.
  ///
  /// flutter_tts Android ve iOS'ta 0.5'i normal hız kabul eder,
  /// web'de ise normal hız 1.0'dır.
  static double get speechRate => kIsWeb ? 0.9 : 0.45;

  /// Şu an kullanılan sesin adı; cihazın varsayılan sesiyse null.
  String? get currentVoiceName => _currentVoice?.name;

  /// Motoru ilk kullanımda bir kez ayarlar.
  Future<void> _ensureInitialized() {
    if (_initialized) {
      return Future<void>.value();
    }
    return _initFuture ??= _init();
  }

  Future<void> _init() async {
    try {
      await _tts.setLanguage(language);
      await _tts.setSpeechRate(speechRate);
      await _tts.setPitch(pitch);
      await _tts.setVolume(volume);
      await _applyVoice();
      _initialized = true;
    } finally {
      // Hata olursa bir sonraki çağrıda yeniden denenir.
      _initFuture = null;
    }
  }

  /// Kullanıcının seçtiği sesi, yoksa en doğal İngilizce sesi ayarlar.
  /// Uygun ses bulunamazsa cihazın varsayılan İngilizce sesi kalır.
  Future<void> _applyVoice() async {
    try {
      final List<TtsVoice> voices = await englishVoices();
      final String? saved = await _savedVoiceName();
      TtsVoice? voice = bestVoice(voices);
      for (final TtsVoice candidate in voices) {
        if (candidate.name == saved) {
          voice = candidate;
        }
      }
      if (voice != null) {
        await _tts.setVoice(<String, String>{
          'name': voice.name,
          'locale': voice.locale,
        });
      }
      _currentVoice = voice;
    } catch (error) {
      debugPrint('TtsService: ses seçilemedi: $error');
    }
  }

  /// Cihazdaki İngilizce sesler, en doğalı başta.
  ///
  /// Chrome sesleri sayfa açıldıktan biraz sonra yüklediği için liste boş
  /// gelirse birkaç kez yeniden denenir.
  Future<List<TtsVoice>> englishVoices() async {
    for (int attempt = 0; attempt < 4; attempt++) {
      final List<TtsVoice> voices = _parseVoices(await _tts.getVoices)
          .where((TtsVoice v) => voiceScore(v) != null)
          .toList()
        ..sort((TtsVoice a, TtsVoice b) =>
            voiceScore(b)!.compareTo(voiceScore(a)!));
      if (voices.isNotEmpty) {
        return voices;
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return const <TtsVoice>[];
  }

  static List<TtsVoice> _parseVoices(Object? raw) {
    if (raw is! List) {
      return const <TtsVoice>[];
    }
    return <TtsVoice>[
      for (final Object? item in raw)
        if (item is Map &&
            item['name'] is String &&
            item['locale'] is String)
          (name: item['name'] as String, locale: item['locale'] as String),
    ];
  }

  static Future<String?> _savedVoiceName() async {
    try {
      final String? name =
          (await SharedPreferences.getInstance()).getString(_voiceKey);
      return name == null || name.isEmpty ? null : name;
    } catch (_) {
      return null;
    }
  }

  /// Kullanılacak sesi seçer ve kaydeder; [name] null ise otomatik seçime
  /// döner. Hemen uygulanır.
  Future<void> selectVoice(String? name) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (name == null) {
        await prefs.remove(_voiceKey);
      } else {
        await prefs.setString(_voiceKey, name);
      }
    } catch (error) {
      debugPrint('TtsService: ses seçimi kaydedilemedi: $error');
    }
    await _ensureInitialized();
    await _applyVoice();
  }

  /// Kullanıcının kaydettiği ses; otomatik seçimdeyse null.
  Future<String?> savedVoiceName() => _savedVoiceName();

  /// [text] metnini okur. Önceki konuşma varsa önce durdurulur.
  ///
  /// Boş metin yok sayılır. Okuma hataları arayüze yansıtılmaz.
  Future<void> speak(String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    try {
      await _ensureInitialized();
      await _tts.stop();
      await _tts.speak(trimmed);
    } catch (error) {
      debugPrint('TtsService.speak hatası: $error');
    }
  }

  /// Süren konuşmayı durdurur.
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (error) {
      debugPrint('TtsService.stop hatası: $error');
    }
  }
}
