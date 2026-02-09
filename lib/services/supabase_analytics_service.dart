import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io' show Platform;

import '../core/build_config.dart';
import './debug_logging_service.dart';
import './supabase_service.dart';

/// Supabase-based analytics service for crash tracking, session analytics,
/// and performance monitoring - replaces Firebase Analytics/Crashlytics
class SupabaseAnalyticsService {
  static SupabaseAnalyticsService? _instance;
  static SupabaseAnalyticsService get instance =>
      _instance ??= SupabaseAnalyticsService._();

  SupabaseAnalyticsService._();

  final _buildConfig = BuildConfig.instance;
  final _logging = DebugLoggingService.instance;
  final SupabaseClient _supabase = SupabaseService.instance.client;

  bool _isInitialized = false;
  String? _currentSessionId;
  DateTime? _sessionStartTime;
  final List<String> _screensVisited = [];
  final List<String> _featuresUsed = [];
  int _eventsCount = 0;
  int _mentalLoadChecks = 0;
  int _recoverySessions = 0;

  String? _appVersion;
  Map<String, dynamic>? _deviceInfo;
  String? _userId;

  /// Initialize analytics service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get app version
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;

      // Get device info
      _deviceInfo = await _getDeviceInfo();

      // Get user ID from Supabase auth
      _userId = _supabase.auth.currentUser?.id;

      _isInitialized = true;
      debugPrint('✅ Supabase Analytics service initialized');
    } catch (e) {
      debugPrint('⚠️ Failed to initialize Supabase Analytics: $e');
    }
  }

  /// Get device information
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        return {
          'platform': 'web',
          'browser': webInfo.browserName.name,
          'user_agent': webInfo.userAgent ?? 'unknown',
        };
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'platform': 'android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'os_version': 'Android ${androidInfo.version.release}',
          'sdk_int': androidInfo.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'os_version': 'iOS ${iosInfo.systemVersion}',
        };
      }
    } catch (e) {
      debugPrint('Failed to get device info: $e');
    }

    return {'platform': 'unknown'};
  }

  /// Start a new session
  Future<void> startSession() async {
    if (!_isInitialized) await initialize();

    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _sessionStartTime = DateTime.now();
    _screensVisited.clear();
    _featuresUsed.clear();
    _eventsCount = 0;
    _mentalLoadChecks = 0;
    _recoverySessions = 0;

    try {
      await _supabase.from('session_analytics').insert({
        'user_id': _userId,
        'session_id': _currentSessionId,
        'session_status': 'active',
        'session_start': _sessionStartTime!.toIso8601String(),
        'app_version': _appVersion,
        'device_info': _deviceInfo,
        'screens_visited': [],
        'features_used': [],
        'events_count': 0,
        'mental_load_checks': 0,
        'recovery_sessions': 0,
      });

      _logging.debug('Session started: $_currentSessionId', category: 'analytics');
    } catch (e) {
      debugPrint('Failed to start session: $e');
    }
  }

  /// End current session
  Future<void> endSession() async {
    if (_currentSessionId == null || _sessionStartTime == null) return;

    try {
      await _supabase
          .from('session_analytics')
          .update({
            'session_status': 'ended',
            'session_end': DateTime.now().toIso8601String(),
            'screens_visited': _screensVisited,
            'features_used': _featuresUsed,
            'events_count': _eventsCount,
            'mental_load_checks': _mentalLoadChecks,
            'recovery_sessions': _recoverySessions,
          })
          .eq('session_id', _currentSessionId!);

      _logging.debug('Session ended: $_currentSessionId', category: 'analytics');
      _currentSessionId = null;
      _sessionStartTime = null;
    } catch (e) {
      debugPrint('Failed to end session: $e');
    }
  }

  /// Track screen view
  Future<void> trackScreenView(String screenName) async {
    if (!_isInitialized) return;

    if (!_screensVisited.contains(screenName)) {
      _screensVisited.add(screenName);
    }
    _eventsCount++;

    _logging.debug('Screen viewed: $screenName', category: 'analytics');
  }

  /// Track feature usage
  Future<void> trackFeatureUsage(String featureName) async {
    if (!_isInitialized) return;

    if (!_featuresUsed.contains(featureName)) {
      _featuresUsed.add(featureName);
    }
    _eventsCount++;

    _logging.debug('Feature used: $featureName', category: 'analytics');
  }

  /// Track mental load check
  void trackMentalLoadCheck() {
    _mentalLoadChecks++;
    _eventsCount++;
  }

  /// Track recovery session
  void trackRecoverySession() {
    _recoverySessions++;
    _eventsCount++;
  }

  /// Log crash report to Supabase
  Future<void> logCrash({
    required String errorMessage,
    required String stackTrace,
    String? errorType,
    String? screenName,
    String severity = 'error',
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      // Get additional context
      final batteryLevel = await _getBatteryLevel();
      final networkStatus = await _getNetworkStatus();
      final memoryUsage = await _getMemoryUsage();

      final crashData = {
        'user_id': _userId,
        'crash_severity': severity,
        'error_message': errorMessage,
        'stack_trace': stackTrace,
        'error_type': errorType ?? 'UnknownError',
        'screen_name': screenName,
        'app_version': _appVersion,
        'device_info': _deviceInfo,
        'os_version': _deviceInfo?['os_version'],
        'memory_usage_mb': memoryUsage,
        'battery_level': batteryLevel,
        'network_status': networkStatus,
        'user_actions_before_crash': metadata,
        'crash_timestamp': DateTime.now().toIso8601String(),
      };

      await _supabase.from('crash_reports').insert(crashData);

      // Update session if crash is fatal
      if (severity == 'fatal' && _currentSessionId != null) {
        await _supabase
            .from('session_analytics')
            .update({'session_status': 'crashed', 'crash_occurred': true})
            .eq('session_id', _currentSessionId!);
      }

      _logging.error(
        'Crash logged: $errorMessage',
        category: 'analytics',
        metadata: {'severity': severity, 'screen': screenName},
      );
    } catch (e) {
      debugPrint('Failed to log crash: $e');
    }
  }

  /// Log performance metric
  Future<void> logPerformance({
    required String metricType,
    required String metricName,
    required int durationMs,
    String? screenName,
    bool success = true,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) return;

    try {
      final networkType = await _getNetworkStatus();

      await _supabase.from('performance_metrics').insert({
        'user_id': _userId,
        'metric_type': metricType,
        'metric_name': metricName,
        'duration_ms': durationMs,
        'screen_name': screenName,
        'success': success,
        'error_message': errorMessage,
        'metadata': metadata,
        'device_info': _deviceInfo,
        'network_type': networkType,
        'recorded_at': DateTime.now().toIso8601String(),
      });

      _logging.info(
        'Performance: $metricName took ${durationMs}ms',
        category: 'analytics',
        metadata: {'type': metricType, 'success': success},
      );
    } catch (e) {
      debugPrint('Failed to log performance: $e');
    }
  }

  /// Measure and log performance of an operation
  Future<T> measurePerformance<T>({
    required String metricType,
    required String metricName,
    required Future<T> Function() operation,
    String? screenName,
    Map<String, dynamic>? metadata,
  }) async {
    final startTime = DateTime.now();

    try {
      final result = await operation();
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      await logPerformance(
        metricType: metricType,
        metricName: metricName,
        durationMs: duration,
        screenName: screenName,
        success: true,
        metadata: metadata,
      );

      return result;
    } catch (e) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      await logPerformance(
        metricType: metricType,
        metricName: metricName,
        durationMs: duration,
        screenName: screenName,
        success: false,
        errorMessage: e.toString(),
        metadata: metadata,
      );

      rethrow;
    }
  }

  /// Get battery level
  Future<int?> _getBatteryLevel() async {
    try {
      if (!kIsWeb) {
        final battery = Battery();
        return await battery.batteryLevel;
      }
    } catch (e) {
      debugPrint('Failed to get battery level: $e');
    }
    return null;
  }

  /// Get network status
  Future<String> _getNetworkStatus() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.first.name;
    } catch (e) {
      debugPrint('Failed to get network status: $e');
      return 'unknown';
    }
  }

  /// Get memory usage (approximate)
  Future<int?> _getMemoryUsage() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        // Approximate memory usage - would need native implementation for accuracy
        return null;
      }
    } catch (e) {
      debugPrint('Failed to get memory usage: $e');
    }
    return null;
  }

  /// Set user ID
  void setUserId(String? userId) {
    _userId = userId;
    _logging.info('User ID set: $userId', category: 'analytics');
  }

  /// Get current session ID
  String? get sessionId => _currentSessionId;

  /// Check if initialized
  bool get isInitialized => _isInitialized;
}