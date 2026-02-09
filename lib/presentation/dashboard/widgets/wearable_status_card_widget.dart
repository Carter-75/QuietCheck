import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class WearableStatusCardWidget extends StatelessWidget {
  final bool connected;
  final String deviceName;
  final int batteryLevel;
  final String lastSync;
  final Map<String, dynamic>? healthMetrics;

  const WearableStatusCardWidget({
    super.key,
    required this.connected,
    required this.deviceName,
    required this.batteryLevel,
    required this.lastSync,
    this.healthMetrics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Wearable Device",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: connected
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: connected ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      connected ? "Connected" : "Disconnected",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: connected ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          connected
              ? Column(
                  children: [
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'watch',
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deviceName,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                "Last synced: $lastSync",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (healthMetrics != null) ...[
                      SizedBox(height: 2.h),
                      _buildHealthMetricRow(
                        context,
                        'Steps',
                        '${healthMetrics!['steps'] ?? 0}',
                        Icons.directions_walk,
                      ),
                      SizedBox(height: 1.h),
                      _buildHealthMetricRow(
                        context,
                        'Heart Rate',
                        '${healthMetrics!['avgHeartRate'] ?? 0} bpm',
                        Icons.favorite,
                      ),
                      SizedBox(height: 1.h),
                      _buildHealthMetricRow(
                        context,
                        'Sleep',
                        '${(healthMetrics!['sleepMinutes'] ?? 0) ~/ 60}h ${(healthMetrics!['sleepMinutes'] ?? 0) % 60}m',
                        Icons.bedtime,
                      ),
                    ],
                  ],
                )
              : Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Text(
                    "Connect your wearable device to enable real-time biometric monitoring",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Color _getBatteryColor(int level) {
    if (level > 50) return Colors.green;
    if (level > 20) return Colors.orange;
    return Colors.red;
  }

  Widget _buildHealthMetricRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        SizedBox(width: 2.w),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
