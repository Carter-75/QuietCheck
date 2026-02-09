import 'package:flutter/foundation.dart';

/// Web stub for health service (no health data available on web)
class HealthService {
  static HealthService? _instance;
  static HealthService get instance => _instance ??= HealthService._();

  HealthService._();

  Future<bool> initialize() async {
    debugPrint('ℹ️ Health service not available on web platform');
    return false;
  }

  Future<bool> hasPermissions() async {
    return false;
  }

  Future<Map<String, dynamic>?> fetchTodayHealthData() async {
    return null;
  }

  Future<void> syncHealthDataToAnalytics() async {
    // No-op on web
  }

  Future<Map<String, dynamic>> getDeviceStatus() async {
    return {
      'connected': false,
      'deviceName': 'Not Available',
      'lastSync': 'Web platform',
      'dataAvailable': false,
    };
  }
}
