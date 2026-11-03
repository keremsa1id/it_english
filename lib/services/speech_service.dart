import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Kullanıcının söylediği İngilizce kelimeyi yazıya çevirir.
///
/// Cihazın kendi ses tanıma motorunu kullanır (Android'de Google, iOS'ta
/// Apple, webde Chrome/Edge). Uygulama genelinde tek bir örnek kullanılır:
/// `SpeechService.instance`.
class SpeechService {
  SpeechService._();

  static final SpeechService instance = SpeechService._();

  final SpeechToText _speech = SpeechToText();

  bool _available = false;
  Future<bool>? _initFuture;
  String? _localeId;

  /// Süren dinlemenin sonucu; dinleme bitince tamamlanır.
  Completer<List<String>>? _pending;
  final List<String> _heard = <String>[];

  /// Motoru ilk kullanımda bir kez hazırlar (mikrofon izni burada istenir).
  Future<bool> _ensureInitialized() {
    if (_available) {
      return Future<bool>.value(true);
    }
    return _initFuture ??= _init();
  }

  Future<bool> _init() async {
    try {
      _available = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );
      if (_available) {
        _localeId = await _englishLocale();
      }
    } catch (error) {
      debugPrint('SpeechService.initialize hatası: $error');
      _available = false;
    } finally {
      // Kullanılamadıysa bir sonraki denemede yeniden sorulsun.
      _initFuture = null;
    }
    return _available;
  }

  /// Cihazdaki İngilizce dili seçer: önce ABD İngilizcesi, yoksa herhangi bir
  /// İngilizce; hiçbiri yoksa null (cihazın varsayılan dili).
  Future<String?> _englishLocale() async {
    final List<LocaleName> locales = await _speech.locales();
    String normalize(LocaleName locale) =>
        locale.localeId.toLowerCase().replaceAll('-', '_');
    for (final LocaleName locale in locales) {
      if (normalize(locale) == 'en_us') {
        return locale.localeId;
      }
    }
    for (final LocaleName locale in locales) {
      if (normalize(locale).startsWith('en')) {
        return locale.localeId;
      }
    }
    return null;
  }

  /// Bir kez dinler ve duyulan metni, en olası tahmin başta olacak şekilde
  /// döndürür. Hiçbir şey anlaşılmadıysa boş liste döner. Ses tanıma bu
  /// cihazda ya da tarayıcıda kullanılamıyorsa (veya mikrofon izni
  /// verilmediyse) null döner.
  Future<List<String>?> listenOnce() async {
    if (!await _ensureInitialized()) {
      return null;
    }
    await stop();

    final Completer<List<String>> pending = Completer<List<String>>();
    _pending = pending;
    _heard.clear();
    try {
      await _speech.listen(
        onResult: _onResult,
        localeId: _localeId,
        listenFor: const Duration(seconds: 6),
        pauseFor: const Duration(seconds: 2),
        listenOptions: SpeechListenOptions(
          partialResults: false,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
        ),
      );
    } catch (error) {
      debugPrint('SpeechService.listen hatası: $error');
      _finish();
    }
    return pending.future;
  }

  /// Süren dinlemeyi durdurur.
  Future<void> stop() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (error) {
      debugPrint('SpeechService.stop hatası: $error');
    }
    _finish();
  }

  void _onResult(SpeechRecognitionResult result) {
    _heard
      ..clear()
      ..addAll(<String>{
        result.recognizedWords,
        for (final SpeechRecognitionWords alternate in result.alternates)
          alternate.recognizedWords,
      }.where((String text) => text.trim().isNotEmpty));
    if (result.finalResult) {
      _finish();
    }
  }

  void _onStatus(String status) {
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _finish();
    }
  }

  void _onError(SpeechRecognitionError error) {
    debugPrint('SpeechService hata: ${error.errorMsg}');
    _finish();
  }

  /// Bekleyen dinlemeyi o ana kadar duyulanlarla tamamlar.
  void _finish() {
    final Completer<List<String>>? pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) {
      pending.complete(List<String>.unmodifiable(_heard));
    }
  }
}
