import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Progress indicator widget showing current step in permission setup flow
///
/// Features:
/// - Visual progress bar with step numbers
/// - Back navigation button
/// - Smooth animations between steps
class ProgressIndicatorWidget extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBackPressed;

  const ProgressIndicatorWidget({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = currentStep / totalSteps;

    return Column(
      children: [
        // Header with back button and step counter
        Row(
          children: [
            // Back button
            IconButton(
              onPressed: onBackPressed,
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              tooltip: 'Go back',
            ),

            Spacer(),

            // Step counter
            Text(
              'Step $currentStep of $totalSteps',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),

        SizedBox(height: 2.h),

        // Progress bar
        Stack(
          children: [
            // Background track
            Container(
              height: 0.6.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // Progress fill
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: 0.6.h,
              width: progress * 100.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
