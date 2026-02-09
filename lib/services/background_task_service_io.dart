import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:app_usage/app_usage.dart';
import 'package:workmanager/workmanager.dart' as workmanager;

import '../models/activity_tracking_record.dart';
import '../models/app_usage_record.dart';
import './burnout_prediction_service.dart';
import './data_service.dart';
import './debug_logging_service.dart';
import './notification_service_io.dart';
import '../core/build_config.dart';

/// Background task service for mobile platforms (Android/iOS)
/// Collects screen time, app switching velocity, and activity patterns
class BackgroundTaskService {
  static const String taskName = 'activityTrackingTask';
  static const String taskTag = 'activity_collection';
  static const String predictionTaskName = 'burnoutPredictionTask';
  static const String predictionTaskTag = 'burnout_prediction';

  static BackgroundTaskService? _instance;
  static BackgroundTaskService get instance =>
      _instance ??= BackgroundTaskService._();

  BackgroundTaskService._();

  final Battery _battery = Battery();
  bool _isInitialized = false;
  final _logging = DebugLoggingService.instance;
  final _buildConfig = BuildConfig.instance;

  /// Initialize background task service
  Future<void> initialize() async {
    if (_isInitialized) return;

    int retryCount = 0;
    const maxRetries = 3;
    const retryDelays = [2, 5, 10];

    while (retryCount <= maxRetries) {
      try {
        await workmanager.Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: kDebugMode,
        );
        _isInitialized = true;
        debugPrint('✅ Background task service initialized');

        if (_buildConfig.enableDebugFeatures) {
          _logging.info(
            'Background task service initialized',
            category: 'background_tasks',
          );
        }
        return;
      } catch (e) {
        if (retryCount < maxRetries) {
          retryCount++;
          debugPrint(
            '⚠️ Retry $retryCount/$maxRetries for background task initialization: $e',
          );
          if (_buildConfig.enableDebugFeatures) {
            _logging.warning(
              'Background task initialization retry $retryCount',
              category: 'background_tasks',
              metadata: {'error': e.toString()},
            );
          }
          await Future.delayed(Duration(seconds: retryDelays[retryCount - 1]));
        } else {
          debugPrint('❌ Failed to initialize background task service: $e');
          if (_buildConfig.enableDebugFeatures) {
            _logging.error(
              'Background task service initialization failed',
              category: 'background_tasks',
              error: e,
            );
          }
          rethrow;
        }
      }
    }
  }

  /// Start periodic activity tracking (every 30 minutes)
  Future<void> startPeriodicTracking() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await workmanager.Workmanager().registerPeriodicTask(
        taskName,
        taskTag,
        frequency: const Duration(minutes: 30),
        constraints: workmanager.Constraints(
          networkType: workmanager.NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: workmanager.ExistingPeriodicWorkPolicy.update,
      );
      debugPrint('✅ Periodic activity tracking started (30-minute intervals)');
    } catch (e) {
      debugPrint('❌ Failed to start periodic tracking: $e');
    }
  }

  /// Start periodic burnout prediction analysis (every 6 hours)
  Future<void> startBurnoutPredictionTask() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await workmanager.Workmanager().registerPeriodicTask(
        predictionTaskName,
        predictionTaskTag,
        frequency: const Duration(hours: 6),
        constraints: workmanager.Constraints(
          networkType: workmanager.NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: workmanager.ExistingPeriodicWorkPolicy.update,
      );
      debugPrint('✅ Periodic burnout prediction started (6-hour intervals)');
    } catch (e) {
      debugPrint('❌ Failed to start burnout prediction task: $e');
    }
  }

  /// Start periodic notification processing (every 30 minutes)
  Future<void> startNotificationProcessingTask() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await workmanager.Workmanager().registerPeriodicTask(
        'notificationProcessingTask',
        'notification_processing',
        frequency: const Duration(minutes: 30),
        constraints: workmanager.Constraints(
          networkType: workmanager.NetworkType.connected,
        ),
        existingWorkPolicy: workmanager.ExistingPeriodicWorkPolicy.update,
      );
      debugPrint(
        '✅ Periodic notification processing started (30-minute intervals)',
      );
    } catch (e) {
      debugPrint('❌ Failed to start notification processing task: $e');
    }
  }

  /// Stop periodic burnout prediction
  Future<void> stopBurnoutPredictionTask() async {
    try {
      await workmanager.Workmanager().cancelByUniqueName(predictionTaskName);
      debugPrint('✅ Periodic burnout prediction stopped');
    } catch (e) {
      debugPrint('❌ Failed to stop burnout prediction: $e');
    }
  }

  /// Stop periodic activity tracking
  Future<void> stopPeriodicTracking() async {
    try {
      await workmanager.Workmanager().cancelByUniqueName(taskName);
      debugPrint('✅ Periodic activity tracking stopped');
    } catch (e) {
      debugPrint('❌ Failed to stop periodic tracking: $e');
    }
  }

  /// Collect activity data immediately (for testing or manual trigger)
  Future<void> collectActivityDataNow() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Collect screen time and app usage (Android only)
      if (Platform.isAndroid) {
        await _collectAndroidActivityData(startOfDay, now, batteryLevel);
      } else if (Platform.isIOS) {
        await _collectIOSActivityData(startOfDay, now, batteryLevel);
      }

      debugPrint('✅ Activity data collected successfully');
    } catch (e) {
      debugPrint('❌ Failed to collect activity data: $e');
    }
  }

  /// Collect Android-specific activity data
  Future<void> _collectAndroidActivityData(
    DateTime startOfDay,
    DateTime now,
    int batteryLevel,
  ) async {
    try {
      // Get usage stats for today using app_usage package
      final usageStats = await AppUsage().getAppUsage(startOfDay, now);

      if (usageStats.isEmpty) {
        debugPrint('⚠️ No usage stats available');
        return;
      }

      // Calculate metrics
      int totalScreenTime = 0;
      int appSwitchCount = 0;
      final List<AppUsageRecord> appUsageRecords = [];
      final userId = DataService.instance.currentUserId;

      if (userId == null) {
        debugPrint('⚠️ User not authenticated, skipping data collection');
        return;
      }

      for (var stat in usageStats) {
        final usageMinutes = stat.usage.inMinutes;
        totalScreenTime += usageMinutes;

        if (usageMinutes > 0) {
          appSwitchCount++;

          appUsageRecords.add(
            AppUsageRecord(
              userId: userId,
              trackingDate: startOfDay,
              appPackageName: stat.packageName,
              appName: stat.appName,
              usageDurationMinutes: usageMinutes,
              openCount: 1,
              lastUsedTimestamp: stat.endDate,
              createdAt: now,
            ),
          );
        }
      }

      // Calculate app switching velocity (switches per hour)
      final hoursElapsed = now.difference(startOfDay).inHours.toDouble();
      final appSwitchVelocity = hoursElapsed > 0
          ? appSwitchCount / hoursElapsed
          : 0.0;

      // Determine activity pattern
      final activityPattern = _determineActivityPattern(
        appSwitchVelocity,
        totalScreenTime,
        appSwitchCount,
      );

      // Create activity tracking record
      final activityRecord = ActivityTrackingRecord(
        userId: userId,
        trackingDate: startOfDay,
        totalScreenTimeMinutes: totalScreenTime,
        appSwitchCount: appSwitchCount,
        appSwitchVelocity: appSwitchVelocity,
        focusSessionsCount: _calculateFocusSessions(usageStats),
        focusDurationMinutes: _calculateFocusDuration(usageStats),
        activityPattern: activityPattern,
        batteryLevelStart: 100,
        batteryLevelEnd: batteryLevel,
        dataCollectionTimestamp: now,
        createdAt: now,
      );

      // Save to Supabase
      await DataService.instance.saveActivityTrackingRecord(activityRecord);

      // Save app usage records (batch)
      for (var record in appUsageRecords) {
        await DataService.instance.saveAppUsageRecord(record);
      }

      debugPrint(
        '✅ Android activity data saved: $totalScreenTime min, $appSwitchCount switches',
      );
    } catch (e) {
      debugPrint('❌ Failed to collect Android activity data: $e');
    }
  }

  /// Collect iOS-specific activity data (limited API access)
  Future<void> _collectIOSActivityData(
    DateTime startOfDay,
    DateTime now,
    int batteryLevel,
  ) async {
    try {
      final userId = DataService.instance.currentUserId;
      if (userId == null) return;

      // iOS has limited screen time API access
      // Create minimal activity record with estimated data
      final activityRecord = ActivityTrackingRecord(
        userId: userId,
        trackingDate: startOfDay,
        totalScreenTimeMinutes: 0,
        appSwitchCount: 0,
        appSwitchVelocity: 0.0,
        focusSessionsCount: 0,
        focusDurationMinutes: 0,
        activityPattern: ActivityPatternType.idle,
        batteryLevelStart: 100,
        batteryLevelEnd: batteryLevel,
        dataCollectionTimestamp: now,
        createdAt: now,
      );

      await DataService.instance.saveActivityTrackingRecord(activityRecord);
      debugPrint('✅ iOS activity data saved (limited metrics)');
    } catch (e) {
      debugPrint('❌ Failed to collect iOS activity data: $e');
    }
  }

  /// Determine activity pattern based on metrics
  ActivityPatternType _determineActivityPattern(
    double appSwitchVelocity,
    int totalScreenTime,
    int appSwitchCount,
  ) {
    if (appSwitchVelocity > 10) {
      return ActivityPatternType.distracted;
    } else if (appSwitchVelocity > 5) {
      return ActivityPatternType.multitasking;
    } else if (totalScreenTime > 60 && appSwitchCount < 5) {
      return ActivityPatternType.focused;
    } else {
      return ActivityPatternType.idle;
    }
  }

  /// Calculate focus sessions (continuous usage > 20 minutes)
  int _calculateFocusSessions(List<AppUsageInfo> usageStats) {
    int focusSessions = 0;
    for (var stat in usageStats) {
      final usageMinutes = stat.usage.inMinutes;
      if (usageMinutes > 20) {
        focusSessions++;
      }
    }
    return focusSessions;
  }

  /// Calculate total focus duration
  int _calculateFocusDuration(List<AppUsageInfo> usageStats) {
    int focusDuration = 0;
    for (var stat in usageStats) {
      final usageMinutes = stat.usage.inMinutes;
      if (usageMinutes > 20) {
        focusDuration += usageMinutes;
      }
    }
    return focusDuration;
  }
}

/// Background task callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  workmanager.Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('🔄 Background task started: $task');

      switch (task) {
        case BackgroundTaskService.taskTag:
          // Activity tracking task
          await BackgroundTaskService.instance.collectActivityDataNow();
          break;

        case BackgroundTaskService.predictionTaskTag:
          // Burnout prediction task
          await _runBurnoutPredictionTask();
          break;

        default:
          debugPrint('⚠️ Unknown task: $task');
      }

      debugPrint('✅ Background task completed: $task');
      return Future.value(true);
    } catch (e) {
      debugPrint('❌ Background task failed: $e');
      return Future.value(false);
    }
  });
}

/// Run burnout prediction analysis and send warnings if needed
Future<void> _runBurnoutPredictionTask() async {
  try {
    final predictionService = BurnoutPredictionService.instance;
    final notificationService = NotificationService.instance;

    // Initialize services
    await notificationService.initialize();

    // Run predictive analysis
    final prediction = await predictionService.runPredictiveAnalysis();

    if (prediction == null) {
      debugPrint('ℹ️ No burnout predicted');
      return;
    }

    // Check if warning should be sent
    if (!predictionService.shouldSendWarning(prediction)) {
      debugPrint('ℹ️ Warning not needed for this prediction');
      return;
    }

    // Check notification permissions
    final hasPermission = await notificationService
        .checkNotificationPermissions();
    if (!hasPermission) {
      debugPrint('⚠️ Notification permissions not granted');
      return;
    }

    // Send burnout warning notification
    await notificationService.sendBurnoutWarning(prediction);

    // Mark warning as sent
    if (prediction.id != null) {
      await predictionService.markWarningSent(prediction.id!);
    }

    debugPrint('✅ Burnout warning sent successfully');
  } catch (e) {
    debugPrint('❌ Failed to run burnout prediction task: $e');
  }
}
