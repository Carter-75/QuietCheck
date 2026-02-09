import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class WearableSettingsSectionWidget extends StatefulWidget {
  const WearableSettingsSectionWidget({super.key});

  @override
  State<WearableSettingsSectionWidget> createState() =>
      _WearableSettingsSectionWidgetState();
}

class _WearableSettingsSectionWidgetState
    extends State<WearableSettingsSectionWidget> {
  String _syncFrequency = 'Every 15 minutes';
  final int _batteryLevel = 78;
  bool _isConnected = true;

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
                        'Wearable Settings',
                        style: theme.textTheme.titleMedium,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Manage connected devices',
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

            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: _isConnected
                    ? theme.colorScheme.tertiary.withValues(alpha: 0.1)
                    : theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isConnected
                      ? theme.colorScheme.tertiary.withValues(alpha: 0.3)
                      : theme.colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isConnected
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      _isConnected
                          ? 'Connected to Apple Watch'
                          : 'Disconnected',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _isConnected
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.error,
                      ),
                    ),
                  ),
                  if (_isConnected)
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'battery_charging_full',
                          color: _batteryLevel > 20
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.error,
                          size: 20,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '$_batteryLevel%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            SizedBox(height: 2.h),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'sync',
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              title: Text('Sync Frequency', style: theme.textTheme.bodyMedium),
              subtitle: Text(
                _syncFrequency,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: CustomIconWidget(
                iconName: 'chevron_right',
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Container(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sync Frequency',
                          style: theme.textTheme.titleMedium,
                        ),
                        SizedBox(height: 2.h),
                        ...[
                          'Every 5 minutes',
                          'Every 15 minutes',
                          'Every 30 minutes',
                          'Every hour',
                        ].map(
                          (frequency) => ListTile(
                            title: Text(frequency),
                            trailing: _syncFrequency == frequency
                                ? CustomIconWidget(
                                    iconName: 'check',
                                    color: theme.colorScheme.primary,
                                    size: 24,
                                  )
                                : null,
                            onTap: () {
                              setState(() => _syncFrequency = frequency);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            Divider(height: 3.h),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'link_off',
                  color: theme.colorScheme.error,
                  size: 20,
                ),
              ),
              title: Text(
                'Disconnect Device',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              subtitle: Text(
                'Remove wearable connection',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: CustomIconWidget(
                iconName: 'chevron_right',
                color: theme.colorScheme.error,
                size: 20,
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Disconnect Device'),
                    content: Text(
                      'Are you sure you want to disconnect your wearable device? You will need to pair it again to continue monitoring.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _isConnected = false);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Device disconnected'),
                              backgroundColor: theme.colorScheme.error,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                        ),
                        child: Text('Disconnect'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
