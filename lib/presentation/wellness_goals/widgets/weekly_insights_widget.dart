import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../models/goal_ai_recommendation.dart';

class WeeklyInsightsWidget extends StatelessWidget {
  final List<GoalAiRecommendation> recommendations;
  final Function(String) onDismiss;

  const WeeklyInsightsWidget({
    super.key,
    required this.recommendations,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        children: recommendations.take(3).map((rec) {
          return Card(
            elevation: 1,
            margin: EdgeInsets.only(bottom: 1.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(51),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      Icons.lightbulb_outline,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec.recommendationText,
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (rec.reasoning != null) ...[
                          SizedBox(height: 0.5.h),
                          Text(
                            rec.reasoning!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => onDismiss(rec.id!),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}