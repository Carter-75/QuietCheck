import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class StatusBarWidget extends StatelessWidget {
  final String currentState;
  final String trendDirection;

  const StatusBarWidget({
    super.key,
    required this.currentState,
    required this.trendDirection,
  });

  Color _getStateColor(BuildContext context, String state) {
    switch (state.toLowerCase()) {
      case "optimal":
        return Colors.green;
      case "balanced":
        return Colors.green;
      case "moderate":
        return Colors.yellow.shade700;
      case "elevated":
        return Colors.orange;
      case "critical":
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend.toLowerCase()) {
      case "up":
        return Icons.trending_up;
      case "down":
        return Icons.trending_down;
      case "stable":
      default:
        return Icons.trending_flat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stateColor = _getStateColor(context, currentState);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: stateColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stateColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: stateColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 2.w),
                Flexible(
                  child: Text(
                    "Current State: $currentState",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: stateColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              CustomIconWidget(
                iconName: _getTrendIcon(
                  trendDirection,
                ).codePoint.toRadixString(16),
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              SizedBox(width: 1.w),
              Text(
                trendDirection.toUpperCase(),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
