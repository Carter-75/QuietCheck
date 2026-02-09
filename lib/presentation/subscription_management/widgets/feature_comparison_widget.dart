import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Feature Comparison Widget
/// Displays free vs premium capabilities with checkmarks and benefit descriptions
class FeatureComparisonWidget extends StatelessWidget {
  const FeatureComparisonWidget({super.key});

  final List<Map<String, dynamic>> _features = const [
    {
      "feature": "Mental Load Monitoring",
      "free": true,
      "premium": true,
      "description":
          "Basic monitoring (1 hour intervals) vs Real-time monitoring",
    },
    {
      "feature": "Analytics & Insights",
      "free": false,
      "premium": true,
      "description": "Advanced trend analysis and weekly reports",
    },
    {
      "feature": "Data Export",
      "free": false,
      "premium": true,
      "description": "Export your mental health data for personal records",
    },
    {
      "feature": "Premium Sound Packs",
      "free": false,
      "premium": true,
      "description": "Access to calming notification sounds",
    },
    {
      "feature": "Wearable Integration",
      "free": true,
      "premium": true,
      "description": "Basic sync vs Advanced biometric analysis",
    },
    {
      "feature": "Recovery Guidance",
      "free": true,
      "premium": true,
      "description": "Basic techniques vs Personalized routines",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Text(
              'Feature Comparison',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildHeaderRow(theme),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          ..._features.map((feature) => _buildFeatureRow(theme, feature)),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      color: theme.colorScheme.primary.withValues(alpha: 0.05),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Feature',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Free',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Premium',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(ThemeData theme, Map<String, dynamic> feature) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      feature["feature"] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: feature["free"] as bool
                          ? CustomIconWidget(
                              iconName: 'check_circle',
                              color: theme.colorScheme.primary,
                              size: 24,
                            )
                          : CustomIconWidget(
                              iconName: 'remove_circle_outline',
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.3),
                              size: 24,
                            ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: feature["premium"] as bool
                          ? CustomIconWidget(
                              iconName: 'check_circle',
                              color: theme.colorScheme.primary,
                              size: 24,
                            )
                          : CustomIconWidget(
                              iconName: 'remove_circle_outline',
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.3),
                              size: 24,
                            ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 0.5.h),
              Text(
                feature["description"] as String,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ],
    );
  }
}
