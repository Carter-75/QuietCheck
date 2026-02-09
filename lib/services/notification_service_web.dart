import 'package:flutter/foundation.dart';
import '../models/burnout_prediction.dart';

/// Web notification service (stub implementation)
/// Web notifications use browser APIs which are not implemented in this version
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();

  NotificationService._();

  Future<void> initialize() async {
    debugPrint('ℹ️ Web notification service initialized (stub)');
  }

  Future<void> sendBurnoutWarning(BurnoutPrediction prediction) async {
    debugPrint(
      'ℹ️ Web notification: Burnout warning (stub) - ${prediction.hoursUntilThreshold}h until threshold',
    );
    // Web notifications would use browser Notification API
    // Not implemented in this version
  }

  Future<bool> checkNotificationPermissions() async {
    return false;
  }

  Future<bool> requestNotificationPermissions() async {
    return false;
  }
}
