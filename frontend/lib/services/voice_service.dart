// lib/services/voice_service.dart
//
// Extends ChangeNotifier so it can be used with ChangeNotifierProvider.
// This is the FIX for: "Could not find Provider<VoiceService>"
//
// Wraps speech_to_text (STT) and flutter_tts (TTS) in one place.

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _sttAvailable = false;
  String _lastWords = '';
  double _soundLevel = 0.0;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get sttAvailable => _sttAvailable;
  String get lastWords => _lastWords;
  double get soundLevel => _soundLevel;

  VoiceService() {
    _initTts();
  }

  // ── TTS setup ────────────────────────────────────────────────────────────

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });
    _tts.setErrorHandler((_) {
      _isSpeaking = false;
      notifyListeners();
    });
  }

  /// Speak [text] aloud. Strips markdown symbols for cleaner output.
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    final clean = text
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'#+\s'), '')
        .replaceAll(RegExp(r'[-_`>]'), '')
        .replaceAll(RegExp(r'\[.*?\]\(.*?\)'), '')
        .replaceAll(RegExp(r'\n{2,}'), '. ')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true), '')
        .trim();
    if (clean.isEmpty) return;
    await _tts.stop();
    await _tts.speak(clean);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  // ── STT ──────────────────────────────────────────────────────────────────

  Future<bool> initStt() async {
    _sttAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
          notifyListeners();
        }
      },
      onError: (error) {
        _isListening = false;
        notifyListeners();
      },
    );
    notifyListeners();
    return _sttAvailable;
  }

  /// Start listening. [onResult] is called with the partial/final text.
  Future<void> startListening({
    required void Function(String text) onResult,
    void Function()? onDone,
  }) async {
    if (!_sttAvailable) await initStt();
    if (!_sttAvailable) return;

    _lastWords = '';
    _isListening = true;
    notifyListeners();

    await _speech.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords;
        notifyListeners();
        onResult(_lastWords);
        if (result.finalResult && onDone != null) {
          onDone();
        }
      },
      onSoundLevelChange: (level) {
        _soundLevel = level;
        notifyListeners();
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_US',
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _tts.stop();
    _speech.stop();
    super.dispose();
  }
}