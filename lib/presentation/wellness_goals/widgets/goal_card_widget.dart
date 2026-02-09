import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../models/wellness_goal.dart';
import '../../../services/data_service.dart';

class GoalCardWidget extends StatelessWidget {
  final WellnessGoal goal;
  final VoidCallback onProgressUpdate;

  const GoalCardWidget({
    super.key,
    required this.goal,
    required this.onProgressUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = goal.isOverdue;

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 2.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and category
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        _getCategoryLabel(goal.category),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (goal.currentStreak > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(51),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '${goal.currentStreak}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            if (goal.description != null) ...[
              SizedBox(height: 1.h),
              Text(
                goal.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            SizedBox(height: 2.h),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${goal.currentValue} / ${goal.targetValue} ${goal.unit}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${goal.progressPercentage.toInt()}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: LinearProgressIndicator(
                    value: goal.progressPercentage / 100,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.outline.withAlpha(51),
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Target date and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isOverdue
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      isOverdue
                          ? 'Overdue'
                          : '${goal.daysRemaining} days left',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isOverdue
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showProgressDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Log Progress'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'stress_reduction':
        return 'Stress Reduction';
      case 'sleep_improvement':
        return 'Sleep Improvement';
      case 'mindfulness_practice':
        return 'Mindfulness Practice';
      case 'work_life_balance':
        return 'Work-Life Balance';
      case 'physical_activity':
        return 'Physical Activity';
      case 'social_connection':
        return 'Social Connection';
      default:
        return 'Custom Goal';
    }
  }

  void _showProgressDialog(BuildContext context) {
    final theme = Theme.of(context);
    int progressValue = 1;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Progress'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How much progress did you make?',
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            StatefulBuilder(
              builder: (context, setState) => Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (progressValue > 1) {
                        setState(() => progressValue--);
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Expanded(
                    child: Text(
                      '$progressValue ${goal.unit}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => progressValue++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await DataService.instance.updateGoalProgress(
                  goalId: goal.id!,
                  progressValue: progressValue,
                  notes: notesController.text.isEmpty
                      ? null
                      : notesController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Progress logged successfully')),
                  );
                  onProgressUpdate();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to log progress: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}