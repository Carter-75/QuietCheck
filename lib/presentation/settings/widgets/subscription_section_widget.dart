import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class SubscriptionSectionWidget extends StatelessWidget {
  final bool isPremium;
  final int trialDaysRemaining;
  final VoidCallback onNavigate;

  const SubscriptionSectionWidget({
    super.key,
    required this.isPremium,
    required this.trialDaysRemaining,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onNavigate,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'workspace_premium',
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subscription',
                          style: theme.textTheme.titleMedium,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Manage your plan and billing',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomIconWidget(
                    iconName: 'chevron_right',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ],
              ),

              SizedBox(height: 3.h),

              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  gradient: isPremium
                      ? LinearGradient(
                          colors: [
                            Color(0xFFE8B86D).withValues(alpha: 0.2),
                            Color(0xFFE8B86D).withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isPremium ? null : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPremium
                        ? Color(0xFFE8B86D).withValues(alpha: 0.3)
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: isPremium
                            ? Color(0xFFE8B86D)
                            : theme.colorScheme.onSurfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: CustomIconWidget(
                        iconName: isPremium ? 'star' : 'schedule',
                        color: isPremium
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.surface,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPremium ? 'Premium Active' : 'Free Trial',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: isPremium
                                  ? Color(0xFFE8B86D)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            isPremium
                                ? '\$1.99/month • Auto-renews'
                                : '$trialDaysRemaining days remaining',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isPremium)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Upgrade',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              if (!isPremium) ...[
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'info_outline',
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          'Upgrade to unlock data export and advanced features',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
