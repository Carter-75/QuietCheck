import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/burnout_prediction.dart';
import '../services/data_service.dart';
import '../models/user_settings.dart';
import '../models/notification_delivery_log.dart';
import '../services/debug_logging_service.dart';
import '../core/build_config.dart';

/// Mobile notification service for Android/iOS
/// Sends local push notifications for burnout warnings
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();

  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  final _logging = DebugLoggingService.instance;
  final _buildConfig = BuildConfig.instance;

  // Retry configuration
  static const int maxRetries = 3;
  static const List<int> retryDelays = [5, 15, 30]; // seconds

  Future<void> initialize() async {
    if (_isInitialized) return;

    int retryCount = 0;
    while (retryCount <= maxRetries) {
      try {
        const androidSettings = AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        );
        const iosSettings = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

        const initSettings = InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );

        await _notificationsPlugin.initialize(settings: initSettings);
        _isInitialized = true;
        debugPrint('✅ Notification service initialized');

        if (_buildConfig.enableDebugFeatures) {
          _logging.info(
            'Notification service initialized',
            category: 'notifications',
          );
        }
        return;
      } catch (e) {
        if (retryCount < maxRetries) {
          retryCount++;
          debugPrint(
            '⚠️ Retry $retryCount/$maxRetries for notification initialization: $e',
          );
          if (_buildConfig.enableDebugFeatures) {
            _logging.warning(
              'Notification initialization retry $retryCount',
              category: 'notifications',
              metadata: {'error': e.toString()},
            );
          }
          await Future.delayed(Duration(seconds: retryDelays[retryCount - 1]));
        } else {
          debugPrint('❌ Failed to initialize notification service: $e');
          if (_buildConfig.enableDebugFeatures) {
            _logging.error(
              'Notification service initialization failed',
              category: 'notifications',
              error: e,
            );
          }
          rethrow;
        }
      }
    }
  }

  /// Send burnout warning notification with retry logic and quiet hours respect
  Future<void> sendBurnoutWarning(BurnoutPrediction prediction) async {
    try {
      // Check user notification preferences
      final settings = await DataService.instance.getUserSettings();
      if (settings == null || !_shouldSendNotification(prediction, settings)) {
        debugPrint('ℹ️ Notification blocked by user preferences');
        return;
      }

      final severityLevel = prediction.getSeverityLevel();
      final title = _getNotificationTitle(severityLevel);
      final body = _getNotificationBody(prediction);
      final severity = _parseSeverity(severityLevel);

      // Check quiet hours
      final now = DateTime.now();
      final deferredUntil = _checkQuietHours(settings, now);

      if (deferredUntil != null) {
        // Defer notification until quiet hours end
        await _createNotificationLog(
          notificationType: 'burnout_warning',
          severity: severity,
          title: title,
          body: body,
          scheduledTime: now,
          status: NotificationDeliveryStatus.deferred,
          deferredUntil: deferredUntil,
        );
        debugPrint(
          'ℹ️ Notification deferred until ${deferredUntil.toString()}',
        );
        return;
      }

      // Create notification log
      final logId = await _createNotificationLog(
        notificationType: 'burnout_warning',
        severity: severity,
        title: title,
        body: body,
        scheduledTime: now,
      );

      // Attempt to send with retry logic
      await _sendWithRetry(
        logId: logId,
        predictionId: prediction.hashCode,
        title: title,
        body: body,
        severityLevel: severityLevel,
        settings: settings,
      );
    } catch (e) {
      debugPrint('❌ Failed to send burnout warning: $e');
    }
  }

  /// Send notification with retry logic
  Future<void> _sendWithRetry({
    required String? logId,
    required int predictionId,
    required String title,
    required String body,
    required String severityLevel,
    required UserSettings settings,
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final androidDetails = AndroidNotificationDetails(
          'burnout_warnings',
          'Burnout Warnings',
          channelDescription: 'Proactive burnout prevention alerts',
          importance: _getImportance(severityLevel),
          priority: _getPriority(severityLevel),
          enableVibration: settings.vibrationEnabled,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        );

        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        final notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _notificationsPlugin.show(
          id: predictionId,
          title: title,
          body: body,
          notificationDetails: notificationDetails,
        );

        // Mark as delivered
        if (logId != null) {
          await _updateNotificationLog(
            logId: logId,
            status: NotificationDeliveryStatus.delivered,
            deliveredAt: DateTime.now(),
          );
        }

        debugPrint(
          '✅ Burnout warning notification sent (attempt ${attempt + 1})',
        );
        return;
      } catch (e) {
        debugPrint('⚠️ Notification send failed (attempt ${attempt + 1}): $e');

        if (attempt < maxRetries) {
          // Update retry count
          if (logId != null) {
            await _updateNotificationLog(
              logId: logId,
              retryCount: attempt + 1,
              lastRetryTime: DateTime.now(),
            );
          }

          // Wait before retry
          await Future.delayed(Duration(seconds: retryDelays[attempt]));
        } else {
          // Mark as failed after max retries
          if (logId != null) {
            await _updateNotificationLog(
              logId: logId,
              status: NotificationDeliveryStatus.failed,
              failedReason: e.toString(),
            );
          }
          debugPrint('❌ Notification failed after $maxRetries retries');
        }
      }
    }
  }

  /// Check if current time is within quiet hours
  DateTime? _checkQuietHours(UserSettings settings, DateTime now) {
    try {
      final startParts = settings.quietHoursStart.split(':');
      final endParts = settings.quietHoursEnd.split(':');

      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);

      final currentMinutes = now.hour * 60 + now.minute;
      final startMinutes = startHour * 60 + startMinute;
      final endMinutes = endHour * 60 + endMinute;

      bool inQuietHours = false;

      if (startMinutes < endMinutes) {
        // Normal case: quiet hours within same day
        inQuietHours =
            currentMinutes >= startMinutes && currentMinutes < endMinutes;
      } else {
        // Quiet hours span midnight
        inQuietHours =
            currentMinutes >= startMinutes || currentMinutes < endMinutes;
      }

      if (inQuietHours) {
        // Calculate when quiet hours end
        final endTime = DateTime(
          now.year,
          now.month,
          now.day,
          endHour,
          endMinute,
        );

        if (endTime.isBefore(now)) {
          // End time is tomorrow
          return endTime.add(Duration(days: 1));
        }
        return endTime;
      }

      return null;
    } catch (e) {
      debugPrint('Error checking quiet hours: $e');
      return null;
    }
  }

  /// Create notification delivery log
  Future<String?> _createNotificationLog({
    required String notificationType,
    required NotificationSeverity severity,
    required String title,
    required String body,
    required DateTime scheduledTime,
    NotificationDeliveryStatus status = NotificationDeliveryStatus.pending,
    DateTime? deferredUntil,
  }) async {
    try {
      final userId = DataService.instance.currentUserId;
      if (userId == null) return null;

      final log = NotificationDeliveryLog(
        userId: userId,
        notificationType: notificationType,
        severity: severity,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        deliveryStatus: status,
        deferredUntil: deferredUntil,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final response = await DataService.instance.supabase
          .from('notification_delivery_logs')
          .insert(log.toJson())
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('Error creating notification log: $e');
      return null;
    }
  }

  /// Update notification delivery log
  Future<void> _updateNotificationLog({
    required String logId,
    NotificationDeliveryStatus? status,
    int? retryCount,
    DateTime? lastRetryTime,
    DateTime? deliveredAt,
    String? failedReason,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status != null) updates['delivery_status'] = status.name;
      if (retryCount != null) updates['retry_count'] = retryCount;
      if (lastRetryTime != null) {
        updates['last_retry_time'] = lastRetryTime.toIso8601String();
      }
      if (deliveredAt != null) {
        updates['delivered_at'] = deliveredAt.toIso8601String();
      }
      if (failedReason != null) updates['failed_reason'] = failedReason;

      await DataService.instance.supabase
          .from('notification_delivery_logs')
          .update(updates)
          .eq('id', logId);
    } catch (e) {
      debugPrint('Error updating notification log: $e');
    }
  }

  NotificationSeverity _parseSeverity(String severity) {
    switch (severity) {
      case 'high':
        return NotificationSeverity.high;
      case 'medium':
        return NotificationSeverity.medium;
      case 'low':
        return NotificationSeverity.low;
      default:
        return NotificationSeverity.medium;
    }
  }

  bool _shouldSendNotification(
    BurnoutPrediction prediction,
    UserSettings settings,
  ) {
    final severity = prediction.getSeverityLevel();

    switch (severity) {
      case 'high':
        return settings.highSeverityNotifications;
      case 'medium':
        return settings.mediumSeverityNotifications;
      case 'low':
        return settings.lowSeverityNotifications;
      default:
        return false;
    }
  }

  String _getNotificationTitle(String severity) {
    switch (severity) {
      case 'high':
        return '⚠️ Critical Burnout Warning';
      case 'medium':
        return '🟡 Burnout Alert';
      case 'low':
        return '🔔 Mental Health Notice';
      default:
        return 'QuietCheck Alert';
    }
  }

  String _getNotificationBody(BurnoutPrediction prediction) {
    final hours = prediction.hoursUntilThreshold;
    final triggers = prediction.identifiedTriggers.take(2).join(', ');

    return 'Predicted burnout in $hours hours. Key triggers: $triggers. Tap to view recommendations.';
  }

  Importance _getImportance(String severity) {
    switch (severity) {
      case 'high':
        return Importance.max;
      case 'medium':
        return Importance.high;
      case 'low':
        return Importance.defaultImportance;
      default:
        return Importance.defaultImportance;
    }
  }

  Priority _getPriority(String severity) {
    switch (severity) {
      case 'high':
        return Priority.max;
      case 'medium':
        return Priority.high;
      case 'low':
        return Priority.defaultPriority;
      default:
        return Priority.defaultPriority;
    }
  }

  Future<bool> checkNotificationPermissions() async {
    if (!_isInitialized) await initialize();

    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      return await androidImpl.areNotificationsEnabled() ?? false;
    }

    final iosImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImpl != null) {
      return await iosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return false;
  }

  Future<bool> requestNotificationPermissions() async {
    if (!_isInitialized) await initialize();

    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      return await androidImpl.requestNotificationsPermission() ?? false;
    }

    final iosImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImpl != null) {
      return await iosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return false;
  }

  /// Process deferred notifications (called by background task)
  Future<void> processDeferredNotifications() async {
    try {
      final pendingNotifications = await DataService.instance
          .getPendingNotifications();
      final now = DateTime.now();

      for (var log in pendingNotifications) {
        if (log.deliveryStatus == NotificationDeliveryStatus.deferred &&
            log.deferredUntil != null &&
            now.isAfter(log.deferredUntil!)) {
          // Quiet hours ended, attempt to send
          await _sendDeferredNotification(log);
        }
      }
    } catch (e) {
      debugPrint('Error processing deferred notifications: $e');
    }
  }

  /// Send a deferred notification
  Future<void> _sendDeferredNotification(NotificationDeliveryLog log) async {
    try {
      final settings = await DataService.instance.getUserSettings();
      if (settings == null) return;

      await _sendWithRetry(
        logId: log.id,
        predictionId: log.hashCode,
        title: log.title,
        body: log.body,
        severityLevel: log.severity.name,
        settings: settings,
      );
    } catch (e) {
      debugPrint('Error sending deferred notification: $e');
    }
  }
}
