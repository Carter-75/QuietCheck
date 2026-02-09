import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

/// Permission card widget displaying educational content for each permission request
///
/// Features:
/// - Large explanatory illustration
/// - Clear headline and description
/// - Bullet points explaining data usage
/// - Visual distinction for core vs optional permissions
class PermissionCardWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final List<String> benefits;
  final String illustrationUrl;
  final String semanticLabel;
  final bool isCore;

  const PermissionCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.benefits,
    required this.illustrationUrl,
    required this.semanticLabel,
    required this.isCore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Illustration
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomImageWidget(
                imageUrl: illustrationUrl,
                width: double.infinity,
                height: 25.h,
                fit: BoxFit.cover,
                semanticLabel: semanticLabel,
              ),
            ),

            SizedBox(height: 3.h),

            // Core/Optional badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
              decoration: BoxDecoration(
                color: isCore
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : theme.colorScheme.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isCore ? 'CORE PERMISSION' : 'OPTIONAL',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isCore
                      ? theme.colorScheme.primary
                      : theme.colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            SizedBox(height: 2.h),

            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 1.h),

            // Subtitle
            Text(
              subtitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            SizedBox(height: 2.h),

            // Description
            Text(
              description,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),

            SizedBox(height: 2.5.h),

            // Benefits section
            Text(
              'What this enables:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 1.5.h),

            // Benefits list
            ...benefits.map(
              (benefit) => Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 0.3.h),
                      child: CustomIconWidget(
                        iconName: 'check_circle',
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        benefit,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 2.h),

            // Privacy assurance
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'lock',
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'All data is processed locally on your device and never sent to the cloud',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
