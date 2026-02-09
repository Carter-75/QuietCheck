import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Quick Relief Technique Card
/// Expandable card displaying stress reduction technique with timer and completion tracking
class QuickReliefTechniqueCard extends StatelessWidget {
  final Map<String, dynamic> technique;
  final VoidCallback onToggleExpansion;
  final VoidCallback onToggleTimer;
  final VoidCallback onComplete;

  const QuickReliefTechniqueCard({
    super.key,
    required this.technique,
    required this.onToggleExpansion,
    required this.onToggleTimer,
    required this.onComplete,
  });

  String _formatElapsedTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpanded = technique["isExpanded"] as bool;
    final isCompleted = technique["isCompleted"] as bool;
    final timerActive = technique["timerActive"] as bool;
    final elapsedTime = technique["elapsedTime"] as int;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: isCompleted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggleExpansion,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? theme.colorScheme.primary.withValues(alpha: 0.2)
                          : theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.3,
                            ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: technique["icon"] as String,
                      color: isCompleted
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          technique["title"] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          technique["duration"] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  isCompleted
                      ? CustomIconWidget(
                          iconName: 'check_circle',
                          color: theme.colorScheme.primary,
                          size: 24,
                        )
                      : CustomIconWidget(
                          iconName: isExpanded ? 'expand_less' : 'expand_more',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                ],
              ),
            ),
          ),

          isExpanded
              ? Container(
                  padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      SizedBox(height: 2.h),

                      Text(
                        technique["description"] as String,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),

                      SizedBox(height: 2.h),

                      Text(
                        'Steps:',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),

                      SizedBox(height: 1.h),

                      ...(technique["steps"] as List).asMap().entries.map((
                        entry,
                      ) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 1.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: 0.5.h),
                                width: 6.w,
                                height: 6.w,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Text(
                                  entry.value as String,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      SizedBox(height: 2.h),

                      timerActive
                          ? Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 1.h,
                                horizontal: 3.w,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomIconWidget(
                                    iconName: 'timer',
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  ),
                                  SizedBox(width: 2.w),
                                  Text(
                                    _formatElapsedTime(elapsedTime),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.primary,
                                        ),
                                  ),
                                ],
                              ),
                            )
                          : SizedBox.shrink(),

                      timerActive ? SizedBox(height: 2.h) : SizedBox.shrink(),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onToggleTimer,
                              child: Text(
                                timerActive ? 'Stop Timer' : 'Start Timer',
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isCompleted ? null : onComplete,
                              child: Text(
                                isCompleted ? 'Completed' : 'Mark Complete',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : SizedBox.shrink(),
        ],
      ),
    );
  }
}
