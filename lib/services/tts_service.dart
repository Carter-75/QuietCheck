import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-Speech Service for breathing exercise voice guidance
class TtsService {
  static TtsService? _instance;
  static TtsService get instance => _instance ??= TtsService._();

  TtsService._();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (!kIsWeb) {
        // Mobile: Use natural voice settings
        await _flutterTts.setLanguage('en-US');
        await _flutterTts.setSpeechRate(0.45); // Slower, more calming
        await _flutterTts.setVolume(0.8); // Slightly softer
        await _flutterTts.setPitch(0.9); // Lower pitch for calming effect

        // Try to set a more natural voice if available
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          await _flutterTts.setVoice({"name": "Samantha", "locale": "en-US"});
        } else if (defaultTargetPlatform == TargetPlatform.android) {
          await _flutterTts.setVoice({
            "name": "en-us-x-sfg#female_1-local",
            "locale": "en-US",
          });
        }
      } else {
        // Web-specific settings
        await _flutterTts.setLanguage('en-US');
        await _flutterTts.setSpeechRate(0.45);
        await _flutterTts.setVolume(0.8);
        await _flutterTts.setPitch(0.9);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  Future<void> speakInhale() async {
    await speak('Breathe in slowly and deeply');
  }

  Future<void> speakExhale() async {
    await speak('Breathe out slowly and gently');
  }

  void dispose() {
    _flutterTts.stop();
  }
}
