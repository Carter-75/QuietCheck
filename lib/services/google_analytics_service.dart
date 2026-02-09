import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../core/build_config.dart';
import './debug_logging_service.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart' as crashlytics_io
    if (dart.library.html) './google_analytics_crashlytics_web.dart'
    if (dart.library.io) './google_analytics_crashlytics_io.dart';

/// Google Analytics service for real-time crash tracking, user session analytics,
/// and app performance monitoring post-launch
class GoogleAnalyticsService {
  static GoogleAnalyticsService? _instance;
  static GoogleAnalyticsService get instance =>
      _instance ??= GoogleAnalyticsService._();

  GoogleAnalyticsService._();

  final _buildConfig = BuildConfig.instance;
  FirebaseAnalytics? _analytics;
  crashlytics_io.FirebaseCrashlytics? _crashlytics;
  bool _isInitialized = false;
  String? _currentSessionId;

  /// Initialize Google Analytics and Crashlytics
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase Core
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
          appId: String.fromEnvironment('FIREBASE_APP_ID'),
          messagingSenderId: String.fromEnvironment(
            'FIREBASE_MESSAGING_SENDER_ID',
          ),
          projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
          storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
        ),
      );

      // Initialize Analytics
      _analytics = FirebaseAnalytics.instance;
      await _analytics?.setAnalyticsCollectionEnabled(true);

      // Initialize Crashlytics (non-web only)
      if (!kIsWeb) {
        _crashlytics = crashlytics_io.FirebaseCrashlytics.instance;

        // Enable crash collection in release builds
        if (_buildConfig.isReleaseBuild) {
          await _crashlytics?.setCrashlyticsCollectionEnabled(true);
        }

        // Pass Flutter errors to Crashlytics
        FlutterError.onError = (FlutterErrorDetails details) {
          _crashlytics?.recordFlutterFatalError(details);
        };

        // Pass platform errors to Crashlytics
        PlatformDispatcher.instance.onError = (error, stack) {
          _crashlytics?.recordError(error, stack, fatal: true);
          return true;
        };
      }

      _isInitialized = true;

      if (_buildConfig.enableDebugFeatures) {
        DebugLoggingService.instance.info(
          'Google Analytics service initialized',
          category: 'analytics',
          metadata: {
            'crashlytics_enabled': !kIsWeb,
            'build_mode': _buildConfig.buildMode,
          },
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to initialize Google Analytics: $e');
      if (_buildConfig.enableDebugFeatures) {
        DebugLoggingService.instance.error(
          'Google Analytics initialization failed',
          category: 'analytics',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Start new analytics session
  void startSession() {
    if (!_isInitialized || _analytics == null) return;

    try {
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _analytics?.logEvent(
        name: 'session_start',
        parameters: {
          'session_id': _currentSessionId!,
          'build_mode': _buildConfig.buildMode,
        },
      );
    } catch (e) {
      // Silent fail for analytics
    }
  }

  /// End current analytics session
  void endSession() {
    if (!_isInitialized || _analytics == null) return;

    try {
      _analytics?.logEvent(
        name: 'session_end',
        parameters: {'session_id': _currentSessionId ?? 'unknown'},
      );
      _currentSessionId = null;
    } catch (e) {
      // Silent fail for analytics
    }
  }

  /// Track screen view
  Future<void> trackScreenView(String screenName) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      await _analytics?.logScreenView(
        screenName: screenName,
        screenClass: screenName,
      );

      if (_buildConfig.enableDebugFeatures) {
        DebugLoggingService.instance.debug(
          'Screen view tracked: $screenName',
          category: 'analytics',
        );
      }
    } catch (e) {
      // Silent fail for analytics
    }
  }

  /// Track custom event
  Future<void> trackEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      await _analytics?.logEvent(
        name: eventName,
        parameters: parameters?.map((key, value) => MapEntry(key, value as Object)),
      );

      if (_buildConfig.enableDebugFeatures) {
        DebugLoggingService.instance.debug(
          'Event tracked: $eventName',
          category: 'analytics',
          metadata: parameters,
        );
      }
    } catch (e) {
      // Silent fail for analytics
    }
  }

  /// Track user engagement
  Future<void> trackUserEngagement({
    required String engagementType,
    required int durationSeconds,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      await _analytics?.logEvent(
        name: 'user_engagement',
        parameters: {
          'engagement_type': engagementType,
          'duration_seconds': durationSeconds,
          'session_id': _currentSessionId ?? 'unknown',
          ...?additionalData,
        },
      );
    } catch (e) {
      // Silent fail for analytics
    }
  }

  /// Track app performance metric
  Future<void> trackPerformanceMetric({
    required String metricName,
    required double value,
    String? unit,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      await _analytics?.logEvent(
        name: 'app_performance',
        parameters: {
          'metric_name': metricName,
          'metric_value': value,
          if (unit != null) 'unit': unit,
          'session_id': _currentSessionId ?? 'unknown',
          ...?metadata,
        },
      );
    } catch (e) {
      // Silent fail for analytics
    }
  }

  /// Track mental load score
  Future<void> trackMentalLoadScore({
    required int score,
    required String state,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent(
      eventName: 'mental_load_score',
      parameters: {
        'score': score,
        'state': state,
        'session_id': _currentSessionId ?? 'unknown',
        ...?additionalData,
      },
    );
  }

  /// Track burnout alert
  Future<void> trackBurnoutAlert({
    required String severity,
    required String triggerReason,
    Map<String, dynamic>? alertData,
  }) async {
    await trackEvent(
      eventName: 'burnout_alert',
      parameters: {
        'severity': severity,
        'trigger_reason': triggerReason,
        'session_id': _currentSessionId ?? 'unknown',
        ...?alertData,
      },
    );
  }

  /// Track recovery session
  Future<void> trackRecoverySession({
    required String sessionType,
    required int durationSeconds,
    required bool completed,
  }) async {
    await trackEvent(
      eventName: 'recovery_session',
      parameters: {
        'session_type': sessionType,
        'duration_seconds': durationSeconds,
        'completed': completed,
        'session_id': _currentSessionId ?? 'unknown',
      },
    );
  }

  /// Track subscription event
  Future<void> trackSubscriptionEvent({
    required String eventType,
    String? subscriptionTier,
    Map<String, dynamic>? subscriptionData,
  }) async {
    await trackEvent(
      eventName: 'subscription_event',
      parameters: {
        'event_type': eventType,
        if (subscriptionTier != null) 'subscription_tier': subscriptionTier,
        'session_id': _currentSessionId ?? 'unknown',
        ...?subscriptionData,
      },
    );
  }

  /// Log non-fatal error to Crashlytics
  Future<void> logError({
    required dynamic error,
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
  }) async {
    if (!_isInitialized || kIsWeb) return;

    try {
      await _crashlytics?.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );

      if (_buildConfig.enableDebugFeatures) {
        DebugLoggingService.instance.error(
          'Error logged to Crashlytics: ${error.toString()}',
          category: 'crashlytics',
          error: error,
          stackTrace: stackTrace,
        );
      }
    } catch (e) {
      // Silent fail for analytics
    }
  }

  /// Set user ID for analytics
  Future<void> setUserId(String userId) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      await _analytics?.setUserId(id: userId);
      if (!kIsWeb) {
        await _crashlytics?.setUserIdentifier(userId);
      }
    } catch (e) {
      // Silent fail for analytics
    }
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      await _analytics?.setUserProperty(name: name, value: value);
    } catch (e) {
      // Silent fail for analytics
    }
  }

  /// Log custom key-value for crash context
  Future<void> setCrashKey(String key, dynamic value) async {
    if (!_isInitialized || kIsWeb) return;

    try {
      await _crashlytics?.setCustomKey(key, value);
    } catch (e) {
      // Silent fail for analytics
    }
  }
}