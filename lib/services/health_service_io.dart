import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import '../services/data_service.dart';
import '../models/analytics_record.dart';

/// Mobile health data service for iOS HealthKit and Android Health Connect
class HealthService {
  static HealthService? _instance;
  static HealthService get instance => _instance ??= HealthService._();

  HealthService._();

  final Health _health = Health();
  bool _isInitialized = false;
  bool _hasPermissions = false;

  /// Health data types to request
  final List<HealthDataType> _healthDataTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WORKOUT,
  ];

  /// Initialize health service and request permissions
  Future<bool> initialize() async {
    if (_isInitialized) return _hasPermissions;

    try {
      // Request authorization for health data types
      _hasPermissions = await _health.requestAuthorization(
        _healthDataTypes,
        permissions: [
          HealthDataAccess.READ,
          HealthDataAccess.READ,
          HealthDataAccess.READ,
          HealthDataAccess.READ,
          HealthDataAccess.READ,
          HealthDataAccess.READ,
          HealthDataAccess.READ,
        ],
      );

      _isInitialized = true;
      debugPrint('✅ Health service initialized: permissions=$_hasPermissions');
      return _hasPermissions;
    } catch (e) {
      debugPrint('❌ Failed to initialize health service: $e');
      _isInitialized = true;
      _hasPermissions = false;
      return false;
    }
  }

  /// Check if health data permissions are granted
  Future<bool> hasPermissions() async {
    if (!_isInitialized) {
      return await initialize();
    }
    return _hasPermissions;
  }

  /// Fetch health data for today and update analytics
  Future<Map<String, dynamic>?> fetchTodayHealthData() async {
    if (!_hasPermissions) {
      debugPrint('⚠️ No health permissions granted');
      return null;
    }

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Fetch health data points
      final healthData = await _health.getHealthDataFromTypes(
        types: _healthDataTypes,
        startTime: startOfDay,
        endTime: now,
      );

      if (healthData.isEmpty) {
        debugPrint('ℹ️ No health data available for today');
        return null;
      }

      // Process health data
      int steps = 0;
      double avgHeartRate = 0;
      int heartRateCount = 0;
      int sleepMinutes = 0;
      int workoutMinutes = 0;
      double caloriesBurned = 0;

      for (var data in healthData) {
        switch (data.type) {
          case HealthDataType.STEPS:
            steps += (data.value as num).toInt();
            break;
          case HealthDataType.HEART_RATE:
            avgHeartRate += (data.value as num).toDouble();
            heartRateCount++;
            break;
          case HealthDataType.SLEEP_ASLEEP:
            final duration = data.dateTo.difference(data.dateFrom);
            sleepMinutes += duration.inMinutes;
            break;
          case HealthDataType.ACTIVE_ENERGY_BURNED:
            caloriesBurned += (data.value as num).toDouble();
            break;
          case HealthDataType.WORKOUT:
            final duration = data.dateTo.difference(data.dateFrom);
            workoutMinutes += duration.inMinutes;
            break;
          default:
            break;
        }
      }

      if (heartRateCount > 0) {
        avgHeartRate = avgHeartRate / heartRateCount;
      }

      // Calculate sleep quality (0-100 scale)
      int sleepQuality = _calculateSleepQuality(sleepMinutes);

      final healthMetrics = {
        'steps': steps,
        'avgHeartRate': avgHeartRate.round(),
        'sleepMinutes': sleepMinutes,
        'sleepQuality': sleepQuality,
        'workoutMinutes': workoutMinutes,
        'caloriesBurned': caloriesBurned.round(),
        'lastSyncTime': now.toIso8601String(),
      };

      debugPrint('✅ Health data fetched: $healthMetrics');
      return healthMetrics;
    } catch (e) {
      debugPrint('❌ Failed to fetch health data: $e');
      return null;
    }
  }

  /// Calculate sleep quality score (0-100)
  int _calculateSleepQuality(int sleepMinutes) {
    if (sleepMinutes == 0) return 0;

    // Optimal sleep: 7-9 hours (420-540 minutes)
    const optimalMin = 420;
    const optimalMax = 540;

    if (sleepMinutes >= optimalMin && sleepMinutes <= optimalMax) {
      return 100;
    } else if (sleepMinutes < optimalMin) {
      // Less than optimal: scale from 0-100
      return ((sleepMinutes / optimalMin) * 100).round().clamp(0, 100);
    } else {
      // More than optimal: slight penalty
      final excess = sleepMinutes - optimalMax;
      return (100 - (excess / 60) * 10).round().clamp(50, 100);
    }
  }

  /// Sync health data to analytics records
  Future<void> syncHealthDataToAnalytics() async {
    try {
      final healthData = await fetchTodayHealthData();
      if (healthData == null) return;

      final dataService = DataService.instance;
      final userId = dataService.currentUserId;
      if (userId == null) {
        debugPrint('⚠️ User not authenticated, skipping health data sync');
        return;
      }

      // Get or create today's analytics record
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      final existingRecords = await dataService.getAnalyticsRecords(
        startDate: startOfDay,
        endDate: endOfDay,
      );

      if (existingRecords.isNotEmpty) {
        // Update existing record with health data
        final record = existingRecords.first;
        final updatedRecord = AnalyticsRecord(
          id: record.id,
          userId: userId,
          date: record.date,
          avgMentalLoad: record.avgMentalLoad,
          peakMentalLoad: record.peakMentalLoad,
          dataPointsCollected: record.dataPointsCollected,
          baselineComparison: record.baselineComparison,
          sleepQuality: healthData['sleepQuality'] as int,
          encryptedNotes: record.encryptedNotes,
          createdAt: record.createdAt,
        );
        await dataService.saveAnalyticsRecord(updatedRecord);
        debugPrint('✅ Health data synced to existing analytics record');
      } else {
        // Create new analytics record with health data
        final newRecord = AnalyticsRecord(
          userId: userId,
          date: startOfDay,
          avgMentalLoad: 50.0,
          peakMentalLoad: 50,
          dataPointsCollected: 0,
          sleepQuality: healthData['sleepQuality'] as int,
          createdAt: DateTime.now(),
        );
        await dataService.saveAnalyticsRecord(newRecord);
        debugPrint('✅ Health data synced to new analytics record');
      }
    } catch (e) {
      debugPrint('❌ Failed to sync health data to analytics: $e');
    }
  }

  /// Get device connection status
  Future<Map<String, dynamic>> getDeviceStatus() async {
    try {
      final hasPerms = await hasPermissions();
      final healthData = await fetchTodayHealthData();

      return {
        'connected': hasPerms && healthData != null,
        'deviceName': Platform.isIOS ? 'iPhone Health' : 'Health Connect',
        'lastSync': healthData?['lastSyncTime'] ?? 'Never',
        'dataAvailable': healthData != null,
      };
    } catch (e) {
      return {
        'connected': false,
        'deviceName': 'Unknown',
        'lastSync': 'Never',
        'dataAvailable': false,
      };
    }
  }
}
