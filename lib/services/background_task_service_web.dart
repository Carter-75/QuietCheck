import 'package:flutter/foundation.dart';

/// Background task service for web platform (limited functionality)
/// Web browsers have restricted background task capabilities
class BackgroundTaskService {
  static BackgroundTaskService? _instance;
  static BackgroundTaskService get instance =>
      _instance ??= BackgroundTaskService._();

  BackgroundTaskService._();

  /// Initialize background task service (no-op on web)
  Future<void> initialize() async {
    debugPrint('⚠️ Background tasks not supported on web platform');
  }

  /// Start periodic activity tracking (no-op on web)
  Future<void> startPeriodicTracking() async {
    debugPrint('⚠️ Periodic tracking not available on web platform');
  }

  /// Stop periodic activity tracking (no-op on web)
  Future<void> stopPeriodicTracking() async {
    debugPrint('⚠️ Periodic tracking not available on web platform');
  }

  /// Collect activity data immediately (no-op on web)
  Future<void> collectActivityDataNow() async {
    debugPrint('⚠️ Activity data collection not available on web platform');
  }
}
