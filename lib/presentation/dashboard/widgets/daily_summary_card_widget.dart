import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class DailySummaryCardWidget extends StatelessWidget {
  final String monitoringDuration;
  final int dataPointsCollected;
  final String baselineComparison;

  const DailySummaryCardWidget({
    super.key,
    required this.monitoringDuration,
    required this.dataPointsCollected,
    required this.baselineComparison,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Daily Summary",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildSummaryRow(
            context,
            "Monitoring Duration",
            monitoringDuration,
            Icons.access_time,
          ),
          SizedBox(height: 1.5.h),
          _buildSummaryRow(
            context,
            "Data Points Collected",
            dataPointsCollected.toString(),
            Icons.analytics,
          ),
          SizedBox(height: 1.5.h),
          _buildSummaryRow(
            context,
            "Baseline Comparison",
            baselineComparison,
            Icons.trending_up,
            isComparison: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isComparison = false,
  }) {
    final theme = Theme.of(context);
    final isPositive = isComparison && value.startsWith('+');
    final isNegative = isComparison && value.startsWith('-');

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isPositive
                      ? Colors.green
                      : isNegative
                      ? Colors.red
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
