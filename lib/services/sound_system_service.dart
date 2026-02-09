import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import './data_service.dart';
import './debug_logging_service.dart';
import '../core/build_config.dart';

/// Sound system service with network-based playback and severity-based sound mapping
/// Plays calming notification sounds based on mental load severity
class SoundSystemService {
  static SoundSystemService? _instance;
  static SoundSystemService get instance =>
      _instance ??= SoundSystemService._();

  SoundSystemService._();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final _dataService = DataService.instance;
  final _logging = DebugLoggingService.instance;
  final _buildConfig = BuildConfig.instance;

  bool _isInitialized = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  // Network-based sound URLs (royalty-free from Pixabay)
  static const Map<String, Map<String, String>> soundPacks = {
    'default': {
      'soft':
          'https://cdn.pixabay.com/audio/2022/03/10/audio_c8c8e1c298.mp3', // Soft bell chime
      'moderate':
          'https://cdn.pixabay.com/audio/2022/03/15/audio_d7e9f8a7c2.mp3', // Ambient tone
      'critical':
          'https://cdn.pixabay.com/audio/2021/08/04/audio_12b0c7443c.mp3', // Deep calming tone
    },
    'nature': {
      'soft':
          'https://cdn.pixabay.com/audio/2022/05/27/audio_1808fbf07a.mp3', // Wind chimes
      'moderate':
          'https://cdn.pixabay.com/audio/2022/03/24/audio_4c3b8c0e43.mp3', // Rain sounds
      'critical':
          'https://cdn.pixabay.com/audio/2022/06/07/audio_0b2c3e8f12.mp3', // Ocean wave
    },
    'ambient': {
      'soft':
          'https://cdn.pixabay.com/audio/2022/08/02/audio_7a8e9c4d21.mp3', // Soft synth pad
      'moderate':
          'https://cdn.pixabay.com/audio/2022/03/18/audio_5d6f7e8a90.mp3', // Ambient bell
      'critical':
          'https://cdn.pixabay.com/audio/2021/11/23/audio_3c4d5e6f78.mp3', // Deep bass tone
    },
  };

  /// Initialize sound system
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      _isInitialized = true;
      debugPrint('✅ Sound system service initialized');

      if (_buildConfig.enableDebugFeatures) {
        _logging.info(
          'Sound system initialized with network-based sounds',
          category: 'sound_system',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize sound system: $e');
      if (_buildConfig.enableDebugFeatures) {
        _logging.error(
          'Sound system initialization failed',
          category: 'sound_system',
          error: e,
        );
      }
    }
  }

  /// Play notification sound based on severity level with retry logic
  Future<void> playNotificationSound(String severityLevel) async {
    if (!_isInitialized) {
      await initialize();
    }

    _retryCount = 0;
    await _playWithRetry(severityLevel);
  }

  /// Internal method with exponential backoff retry logic
  Future<void> _playWithRetry(String severityLevel) async {
    try {
      // Get user settings for sound pack and volume
      final settings = await _dataService.getUserSettings();
      final soundPack = settings?.selectedSoundPack ?? 'default';
      final volume = 0.7; // Default volume 70%

      // Map severity to sound type
      final soundType = _mapSeverityToSoundType(severityLevel);

      // Get sound URL
      final soundUrl =
          soundPacks[soundPack]?[soundType] ??
          soundPacks['default']![soundType]!;

      if (_buildConfig.enableDebugFeatures) {
        _logging.info(
          'Playing sound: pack=$soundPack, type=$soundType, volume=$volume',
          category: 'sound_system',
        );
      }

      // Set volume
      await _audioPlayer.setVolume(volume);

      // Play sound from network URL
      await _audioPlayer.play(UrlSource(soundUrl));

      // Reset retry count on success
      _retryCount = 0;

      if (_buildConfig.enableDebugFeatures) {
        _logging.info('Sound played successfully', category: 'sound_system');
      }
    } catch (e) {
      if (_buildConfig.enableDebugFeatures) {
        _logging.error(
          'Sound playback failed (attempt ${_retryCount + 1}/$_maxRetries)',
          category: 'sound_system',
          error: e,
        );
      }

      // Retry with exponential backoff
      if (_retryCount < _maxRetries) {
        _retryCount++;
        final delayMs = 500 * (1 << (_retryCount - 1)); // 500ms, 1s, 2s
        await Future.delayed(Duration(milliseconds: delayMs));
        await _playWithRetry(severityLevel);
      } else {
        // Max retries reached - fail silently
        debugPrint('❌ Sound playback failed after $_maxRetries attempts');
        if (_buildConfig.enableDebugFeatures) {
          _logging.error(
            'Sound playback failed after max retries',
            category: 'sound_system',
            error: e,
          );
        }
      }
    }
  }

  /// Map severity level to sound type
  String _mapSeverityToSoundType(String severityLevel) {
    switch (severityLevel.toLowerCase()) {
      case 'low':
      case 'soft':
        return 'soft';
      case 'medium':
      case 'moderate':
        return 'moderate';
      case 'high':
      case 'critical':
        return 'critical';
      default:
        return 'soft';
    }
  }

  /// Stop currently playing sound
  Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Failed to stop sound: $e');
    }
  }

  /// Dispose audio player
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      _isInitialized = false;
    } catch (e) {
      debugPrint('Failed to dispose audio player: $e');
    }
  }
}
