import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../core/app_export.dart';
import '../../core/build_config.dart';
import '../../services/data_service.dart';
import '../../services/health_service.dart';
import '../../services/notification_service.dart';
import '../../services/background_task_service.dart';
import '../../services/in_app_purchase_service.dart';
import '../../widgets/custom_icon_widget.dart';

/// Diagnostics Dashboard - System health and status monitoring
class DiagnosticsDashboardScreen extends StatefulWidget {
  const DiagnosticsDashboardScreen({super.key});

  @override
  State<DiagnosticsDashboardScreen> createState() =>
      _DiagnosticsDashboardScreenState();
}

class _DiagnosticsDashboardScreenState
    extends State<DiagnosticsDashboardScreen> {
  final _buildConfig = BuildConfig.instance;
  final _dataService = DataService.instance;
  final _healthService = HealthService.instance;
  final _notificationService = NotificationService.instance;
  final _backgroundTaskService = BackgroundTaskService.instance;
  final _iapService = InAppPurchaseService.instance;

  Map<String, dynamic> _systemStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSystemStatus();
  }

  Future<void> _loadSystemStatus() async {
    setState(() => _isLoading = true);

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();
      final permissions = await _checkPermissions();
      final healthStatus = await _checkHealthDataStatus();
      final notificationStatus = await _checkNotificationStatus();
      final subscriptionStatus = await _checkSubscriptionStatus();
      final dataStats = await _checkDataPipelineStatus();

      setState(() {
        _systemStatus = {
          'app': {
            'version': packageInfo.version,
            'buildNumber': packageInfo.buildNumber,
            'buildMode': _buildConfig.buildMode,
          },
          'permissions': permissions,
          'health': healthStatus,
          'notifications': notificationStatus,
          'subscription': subscriptionStatus,
          'dataPipeline': dataStats,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _checkPermissions() async {
    return {
      'notifications': await Permission.notification.isGranted,
      'activityRecognition': await Permission.activityRecognition.isGranted,
      'sensors': await Permission.sensors.isGranted,
    };
  }

  Future<Map<String, dynamic>> _checkHealthDataStatus() async {
    try {
      final hasPermission = await _healthService.hasPermissions();
      final recentData = await _dataService.getMentalLoadScores(
        startDate: DateTime.now().subtract(const Duration(hours: 24)),
        endDate: DateTime.now(),
      );

      return {
        'authorized': hasPermission,
        'dataPoints24h': recentData.length,
        'lastSync': recentData.isNotEmpty
            ? recentData.last.recordedAt.toIso8601String()
            : 'Never',
      };
    } catch (e) {
      return {
        'authorized': false,
        'dataPoints24h': 0,
        'lastSync': 'Error',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _checkNotificationStatus() async {
    try {
      final logs = await _dataService.getNotificationDeliveryLogs(
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
      );

      final delivered = logs
          .where((log) => log.deliveryStatus == 'delivered')
          .length;
      final failed = logs.where((log) => log.deliveryStatus == 'failed').length;

      return {
        'total': logs.length,
        'delivered': delivered,
        'failed': failed,
        'successRate': logs.isNotEmpty
            ? (delivered / logs.length * 100).toStringAsFixed(1)
            : '0.0',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _checkSubscriptionStatus() async {
    try {
      final subscription = await _dataService.getSubscriptionData();
      return {
        'tier': subscription?.status ?? 'free',
        'status': subscription?.status ?? 'inactive',
        'trialEndsAt': subscription?.nextPaymentDate?.toIso8601String() ?? 'N/A',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _checkDataPipelineStatus() async {
    try {
      final scores = await _dataService.getMentalLoadScores(
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
      );

      final activities = await _dataService.getActivityTrackingRecords(
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
      );

      return {
        'mentalLoadScores7d': scores.length,
        'activityRecords7d': activities.length,
        'lastScoreTimestamp': scores.isNotEmpty
            ? scores.last.recordedAt.toIso8601String()
            : 'Never',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_buildConfig.enableDebugFeatures) {
      return Scaffold(
        appBar: AppBar(title: const Text('Diagnostics')),
        body: const Center(
          child: Text('Diagnostics disabled in release builds'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSystemStatus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSystemStatus,
              child: ListView(
                padding: EdgeInsets.all(4.w),
                children: [
                  _buildAppInfoSection(theme),
                  SizedBox(height: 2.h),
                  _buildPermissionsSection(theme),
                  SizedBox(height: 2.h),
                  _buildHealthDataSection(theme),
                  SizedBox(height: 2.h),
                  _buildNotificationsSection(theme),
                  SizedBox(height: 2.h),
                  _buildSubscriptionSection(theme),
                  SizedBox(height: 2.h),
                  _buildDataPipelineSection(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildAppInfoSection(ThemeData theme) {
    final appInfo = _systemStatus['app'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomIconWidget(iconName: 'info', size: 24),
                SizedBox(width: 2.w),
                Text('App Information', style: theme.textTheme.titleMedium),
              ],
            ),
            SizedBox(height: 2.h),
            _buildStatusRow('Version', appInfo['version'] ?? 'Unknown'),
            _buildStatusRow(
              'Build Number',
              appInfo['buildNumber'] ?? 'Unknown',
            ),
            _buildStatusRow('Build Mode', appInfo['buildMode'] ?? 'Unknown'),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsSection(ThemeData theme) {
    final permissions =
        _systemStatus['permissions'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomIconWidget(iconName: 'lock', size: 24),
                SizedBox(width: 2.w),
                Text('Permissions', style: theme.textTheme.titleMedium),
              ],
            ),
            SizedBox(height: 2.h),
            _buildPermissionRow(
              'Notifications',
              permissions['notifications'] ?? false,
            ),
            _buildPermissionRow(
              'Activity Recognition',
              permissions['activityRecognition'] ?? false,
            ),
            _buildPermissionRow('Sensors', permissions['sensors'] ?? false),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthDataSection(ThemeData theme) {
    final health = _systemStatus['health'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomIconWidget(iconName: 'favorite', size: 24),
                SizedBox(width: 2.w),
                Text('Health Data', style: theme.textTheme.titleMedium),
              ],
            ),
            SizedBox(height: 2.h),
            _buildStatusRow(
              'Authorization',
              health['authorized'] == true ? 'Granted' : 'Denied',
            ),
            _buildStatusRow(
              'Data Points (24h)',
              health['dataPoints24h']?.toString() ?? '0',
            ),
            _buildStatusRow('Last Sync', health['lastSync'] ?? 'Never'),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection(ThemeData theme) {
    final notifications =
        _systemStatus['notifications'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomIconWidget(iconName: 'notifications', size: 24),
                SizedBox(width: 2.w),
                Text('Notifications', style: theme.textTheme.titleMedium),
              ],
            ),
            SizedBox(height: 2.h),
            _buildStatusRow(
              'Total Sent (7d)',
              notifications['total']?.toString() ?? '0',
            ),
            _buildStatusRow(
              'Delivered',
              notifications['delivered']?.toString() ?? '0',
            ),
            _buildStatusRow(
              'Failed',
              notifications['failed']?.toString() ?? '0',
            ),
            _buildStatusRow(
              'Success Rate',
              '${notifications['successRate'] ?? '0.0'}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionSection(ThemeData theme) {
    final subscription =
        _systemStatus['subscription'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomIconWidget(iconName: 'payment', size: 24),
                SizedBox(width: 2.w),
                Text('Subscription', style: theme.textTheme.titleMedium),
              ],
            ),
            SizedBox(height: 2.h),
            _buildStatusRow('Tier', subscription['tier'] ?? 'free'),
            _buildStatusRow('Status', subscription['status'] ?? 'inactive'),
            _buildStatusRow('Trial Ends', subscription['trialEndsAt'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataPipelineSection(ThemeData theme) {
    final pipeline =
        _systemStatus['dataPipeline'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomIconWidget(iconName: 'analytics', size: 24),
                SizedBox(width: 2.w),
                Text('Data Pipeline', style: theme.textTheme.titleMedium),
              ],
            ),
            SizedBox(height: 2.h),
            _buildStatusRow(
              'Mental Load Scores (7d)',
              pipeline['mentalLoadScores7d']?.toString() ?? '0',
            ),
            _buildStatusRow(
              'Activity Records (7d)',
              pipeline['activityRecords7d']?.toString() ?? '0',
            ),
            _buildStatusRow(
              'Last Score',
              pipeline['lastScoreTimestamp'] ?? 'Never',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14.sp)),
          Text(
            value,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(String label, bool granted) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14.sp)),
          Row(
            children: [
              Icon(
                granted ? Icons.check_circle : Icons.cancel,
                color: granted ? Colors.green : Colors.red,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                granted ? 'Granted' : 'Denied',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: granted ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}