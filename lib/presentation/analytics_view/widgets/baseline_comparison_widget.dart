import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Baseline comparison widget displaying current week against established baseline.
/// Shows variance indicators and comparative analysis.
class BaselineComparisonWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const BaselineComparisonWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Baseline Comparison',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                CustomIconWidget(
                  iconName: 'info_outline',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              'Compare current week with your 7-day baseline',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 3.h),

            // Chart container
            SizedBox(
              height: 30.h,
              child: Semantics(
                label:
                    "Baseline Comparison Bar Chart showing current mental load versus baseline values for each day of the week",
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: theme.colorScheme.surface,
                        tooltipRoundedRadius: 8,
                        tooltipPadding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.h,
                        ),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final dataPoint = data[groupIndex];
                          final label = rodIndex == 0 ? 'Current' : 'Baseline';
                          final value = rodIndex == 0
                              ? dataPoint["current"]
                              : dataPoint["baseline"];
                          return BarTooltipItem(
                            '${dataPoint["day"]}\n$label: $value',
                            theme.textTheme.bodySmall!.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 &&
                                value.toInt() < data.length) {
                              return Padding(
                                padding: EdgeInsets.only(top: 1.h),
                                child: Text(
                                  data[value.toInt()]["day"],
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }
                            return Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 25,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.3,
                          ),
                          width: 1,
                        ),
                        left: BorderSide(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.3,
                          ),
                          width: 1,
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    barGroups: List.generate(
                      data.length,
                      (index) => BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: (data[index]["current"] as num).toDouble(),
                            color: theme.colorScheme.primary,
                            width: 12,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                          BarChartRodData(
                            toY: (data[index]["baseline"] as num).toDouble(),
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                            width: 12,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 3.h),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  'Current Week',
                  theme.colorScheme.primary,
                  theme,
                ),
                SizedBox(width: 4.w),
                _buildLegendItem(
                  'Baseline',
                  theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  theme,
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Variance summary
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Variance Analysis',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  _buildVarianceRow(
                    'Average Difference',
                    _calculateAverageDifference(),
                    theme,
                  ),
                  SizedBox(height: 0.5.h),
                  _buildVarianceRow(
                    'Days Above Baseline',
                    _countDaysAboveBaseline().toString(),
                    theme,
                  ),
                  SizedBox(height: 0.5.h),
                  _buildVarianceRow('Overall Trend', _getOverallTrend(), theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 2.w),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _calculateAverageDifference() {
    if (data.isEmpty) return '0.0';
    final totalDiff = data.fold<double>(
      0,
      (prev, item) =>
          prev +
          ((item["current"] as num) - (item["baseline"] as num)).toDouble(),
    );
    final avgDiff = totalDiff / data.length;
    return avgDiff >= 0
        ? '+${avgDiff.toStringAsFixed(1)}'
        : avgDiff.toStringAsFixed(1);
  }

  int _countDaysAboveBaseline() {
    return data
        .where((item) => (item["current"] as num) > (item["baseline"] as num))
        .length;
  }

  String _getOverallTrend() {
    final avgDiff =
        data.fold<double>(
          0,
          (prev, item) =>
              prev +
              ((item["current"] as num) - (item["baseline"] as num)).toDouble(),
        ) /
        data.length;

    if (avgDiff > 5) return 'Above baseline ↑';
    if (avgDiff < -5) return 'Below baseline ↓';
    return 'Near baseline →';
  }

  Widget _buildVarianceRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}