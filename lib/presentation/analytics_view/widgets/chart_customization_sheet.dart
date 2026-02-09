import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Bottom sheet for chart customization options.
/// Provides metric selection, time range adjustment, and correlation preferences.
class ChartCustomizationSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onApply;

  const ChartCustomizationSheet({super.key, required this.onApply});

  @override
  State<ChartCustomizationSheet> createState() =>
      _ChartCustomizationSheetState();
}

class _ChartCustomizationSheetState extends State<ChartCustomizationSheet> {
  String _selectedMetric = 'Mental Load';
  String _selectedTimeRange = '7 Days';
  bool _showBaseline = true;
  bool _showSleepCorrelation = true;

  final List<String> _metrics = [
    'Mental Load',
    'Sleep Quality',
    'Activity Level',
    'Heart Rate',
  ];
  final List<String> _timeRanges = ['7 Days', '30 Days', '90 Days', 'Custom'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 3.h),

              // Title
              Text(
                'Customize Charts',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3.h),

              // Metric selection
              Text(
                'Primary Metric',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: _metrics.map((metric) {
                  final isSelected = _selectedMetric == metric;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMetric = metric),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                      ),
                      child: Text(
                        metric,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 3.h),

              // Time range selection
              Text(
                'Time Range',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: _timeRanges.map((range) {
                  final isSelected = _selectedTimeRange == range;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTimeRange = range),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                      ),
                      child: Text(
                        range,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 3.h),

              // Display options
              Text(
                'Display Options',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              _buildSwitchOption(
                'Show Baseline Comparison',
                _showBaseline,
                (value) => setState(() => _showBaseline = value),
                theme,
              ),
              _buildSwitchOption(
                'Show Sleep Correlation',
                _showSleepCorrelation,
                (value) => setState(() => _showSleepCorrelation = value),
                theme,
              ),
              SizedBox(height: 3.h),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply({
                          'metric': _selectedMetric,
                          'timeRange': _selectedTimeRange,
                          'showBaseline': _showBaseline,
                          'showSleepCorrelation': _showSleepCorrelation,
                        });
                      },
                      child: Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchOption(
    String label,
    bool value,
    Function(bool) onChanged,
    ThemeData theme,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
