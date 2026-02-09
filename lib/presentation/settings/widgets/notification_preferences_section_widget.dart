import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class NotificationPreferencesSectionWidget extends StatelessWidget {
  final bool highSeverityEnabled;
  final bool mediumSeverityEnabled;
  final bool lowSeverityEnabled;
  final bool vibrationEnabled;
  final ValueChanged<bool> onHighSeverityChanged;
  final ValueChanged<bool> onMediumSeverityChanged;
  final ValueChanged<bool> onLowSeverityChanged;
  final ValueChanged<bool> onVibrationChanged;

  const NotificationPreferencesSectionWidget({
    super.key,
    required this.highSeverityEnabled,
    required this.mediumSeverityEnabled,
    required this.lowSeverityEnabled,
    required this.vibrationEnabled,
    required this.onHighSeverityChanged,
    required this.onMediumSeverityChanged,
    required this.onLowSeverityChanged,
    required this.onVibrationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'notifications',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notification Preferences',
                        style: theme.textTheme.titleMedium,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Control alert behavior',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 3.h),

            Text(
              'Severity Levels',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            SizedBox(height: 2.h),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Color(0xFFC17B7B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'priority_high',
                  color: Color(0xFFC17B7B),
                  size: 20,
                ),
              ),
              title: Text('High Severity', style: theme.textTheme.bodyMedium),
              subtitle: Text(
                'Critical mental load alerts',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              value: highSeverityEnabled,
              onChanged: onHighSeverityChanged,
            ),

            SizedBox(height: 1.h),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Color(0xFFE8B86D).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'warning',
                  color: Color(0xFFE8B86D),
                  size: 20,
                ),
              ),
              title: Text('Medium Severity', style: theme.textTheme.bodyMedium),
              subtitle: Text(
                'Elevated stress notifications',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              value: mediumSeverityEnabled,
              onChanged: onMediumSeverityChanged,
            ),

            SizedBox(height: 1.h),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'info',
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              title: Text('Low Severity', style: theme.textTheme.bodyMedium),
              subtitle: Text(
                'Informational updates',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              value: lowSeverityEnabled,
              onChanged: onLowSeverityChanged,
            ),

            Divider(height: 4.h),

            Text(
              'Alert Behavior',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            SizedBox(height: 2.h),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'vibration',
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              title: Text('Vibration', style: theme.textTheme.bodyMedium),
              subtitle: Text(
                'Haptic feedback for alerts',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              value: vibrationEnabled,
              onChanged: onVibrationChanged,
            ),
          ],
        ),
      ),
    );
  }
}
