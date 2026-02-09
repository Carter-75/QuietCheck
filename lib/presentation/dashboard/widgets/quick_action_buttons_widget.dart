import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class QuickActionButtonsWidget extends StatelessWidget {
  final VoidCallback onSensitivityTap;
  final VoidCallback onQuietHoursTap;
  final VoidCallback onRecoveryTap;

  const QuickActionButtonsWidget({
    super.key,
    required this.onSensitivityTap,
    required this.onQuietHoursTap,
    required this.onRecoveryTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                "Sensitivity",
                Icons.tune,
                onSensitivityTap,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildActionButton(
                context,
                "Quiet Hours",
                Icons.bedtime,
                onQuietHoursTap,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildActionButton(
                context,
                "Recovery",
                Icons.self_improvement,
                onRecoveryTap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: icon.codePoint.toRadixString(16),
              color: theme.colorScheme.primary,
              size: 28,
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
