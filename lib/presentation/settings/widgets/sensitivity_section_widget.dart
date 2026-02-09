import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class SensitivitySectionWidget extends StatelessWidget {
  final double sensitivityValue;
  final ValueChanged<double> onSensitivityChanged;

  const SensitivitySectionWidget({
    super.key,
    required this.sensitivityValue,
    required this.onSensitivityChanged,
  });

  String _getSensitivityLabel(double value) {
    if (value < 25) return 'Very Low';
    if (value < 50) return 'Low';
    if (value < 75) return 'Medium';
    return 'High';
  }

  Color _getSensitivityColor(BuildContext context, double value) {
    final theme = Theme.of(context);
    if (value < 25) return theme.colorScheme.tertiary;
    if (value < 50) return theme.colorScheme.primary;
    if (value < 75) return Color(0xFFE8B86D);
    return Color(0xFFC17B7B);
  }

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
                  iconName: 'tune',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sensitivity', style: theme.textTheme.titleMedium),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Adjust mental load threshold',
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Current Level:', style: theme.textTheme.bodyMedium),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: _getSensitivityColor(
                      context,
                      sensitivityValue,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getSensitivityLabel(sensitivityValue),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _getSensitivityColor(context, sensitivityValue),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            SliderTheme(
              data: theme.sliderTheme.copyWith(
                activeTrackColor: _getSensitivityColor(
                  context,
                  sensitivityValue,
                ),
                thumbColor: _getSensitivityColor(context, sensitivityValue),
                overlayColor: _getSensitivityColor(
                  context,
                  sensitivityValue,
                ).withValues(alpha: 0.2),
              ),
              child: Slider(
                value: sensitivityValue,
                min: 0,
                max: 100,
                divisions: 100,
                onChanged: onSensitivityChanged,
              ),
            ),

            SizedBox(height: 1.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Less Sensitive',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'More Sensitive',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info_outline',
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Higher sensitivity means earlier alerts for mental load changes',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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
