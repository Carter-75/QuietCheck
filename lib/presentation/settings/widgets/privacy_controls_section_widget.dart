import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class PrivacyControlsSectionWidget extends StatelessWidget {
  final bool isPremium;
  final VoidCallback onExportData;
  final VoidCallback onSelectiveDeletion;
  final VoidCallback onCompleteWipe;

  const PrivacyControlsSectionWidget({
    super.key,
    required this.isPremium,
    required this.onExportData,
    required this.onSelectiveDeletion,
    required this.onCompleteWipe,
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
                  iconName: 'shield',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy Controls',
                        style: theme.textTheme.titleMedium,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Manage your data ownership',
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
                color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'lock',
                    color: theme.colorScheme.tertiary,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'All data is stored locally and encrypted',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
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
                  iconName: 'download',
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              title: Row(
                children: [
                  Text('Export Data', style: theme.textTheme.bodyMedium),
                  if (!isPremium) ...[
                    SizedBox(width: 2.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFE8B86D).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Premium',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Color(0xFFE8B86D),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                'Download your data in CSV format',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: CustomIconWidget(
                iconName: 'chevron_right',
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onTap: onExportData,
            ),

            Divider(height: 3.h),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'delete_outline',
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              title: Text(
                'Selective Deletion',
                style: theme.textTheme.bodyMedium,
              ),
              subtitle: Text(
                'Delete specific data types',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: CustomIconWidget(
                iconName: 'chevron_right',
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onTap: onSelectiveDeletion,
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
                  iconName: 'delete_forever',
                  color: theme.colorScheme.error,
                  size: 20,
                ),
              ),
              title: Text(
                'Complete Data Wipe',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              subtitle: Text(
                'Permanently delete all data',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: CustomIconWidget(
                iconName: 'chevron_right',
                color: theme.colorScheme.error,
                size: 20,
              ),
              onTap: onCompleteWipe,
            ),
          ],
        ),
      ),
    );
  }
}
