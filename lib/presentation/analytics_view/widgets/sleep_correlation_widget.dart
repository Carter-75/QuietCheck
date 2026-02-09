import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Sleep correlation widget showing mental load patterns against sleep quality.
/// Features dual-axis chart with correlation analysis.
class SleepCorrelationWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const SleepCorrelationWidget({super.key, required this.data});

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
                  'Sleep Correlation',
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
              'Relationship between mental load and sleep quality',
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
                    "Sleep Correlation Dual-Axis Line Chart showing mental load and sleep quality patterns throughout the week",
                child: LineChart(
                  LineChartData(
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
                          interval: 1,
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
                    minX: 0,
                    maxX: (data.length - 1).toDouble(),
                    minY: 0,
                    maxY: 100,
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: theme.colorScheme.surface,
                        tooltipRoundedRadius: 8,
                        tooltipPadding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.h,
                        ),
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          return touchedBarSpots.map((barSpot) {
                            final index = barSpot.x.toInt();
                            if (index >= 0 && index < data.length) {
                              final dataPoint = data[index];
                              final label = barSpot.barIndex == 0
                                  ? 'Mental Load'
                                  : 'Sleep Quality';
                              final value = barSpot.barIndex == 0
                                  ? dataPoint["mentalLoad"]
                                  : dataPoint["sleepQuality"];
                              return LineTooltipItem(
                                '${dataPoint["day"]}\n$label: $value',
                                theme.textTheme.bodySmall!.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }
                            return null;
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      // Mental Load line
                      LineChartBarData(
                        spots: List.generate(
                          data.length,
                          (index) => FlSpot(
                            index.toDouble(),
                            (data[index]["mentalLoad"] as num).toDouble(),
                          ),
                        ),
                        isCurved: true,
                        color: theme.colorScheme.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: theme.colorScheme.primary,
                              strokeWidth: 2,
                              strokeColor: theme.colorScheme.surface,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(show: false),
                      ),
                      // Sleep Quality line
                      LineChartBarData(
                        spots: List.generate(
                          data.length,
                          (index) => FlSpot(
                            index.toDouble(),
                            (data[index]["sleepQuality"] as num).toDouble(),
                          ),
                        ),
                        isCurved: true,
                        color: Color(0xFFE8B86D),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Color(0xFFE8B86D),
                              strokeWidth: 2,
                              strokeColor: theme.colorScheme.surface,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
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
                  'Mental Load',
                  theme.colorScheme.primary,
                  theme,
                ),
                SizedBox(width: 4.w),
                _buildLegendItem('Sleep Quality', Color(0xFFE8B86D), theme),
              ],
            ),

            SizedBox(height: 2.h),

            // Correlation insights
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
                    'Correlation Insights',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  _buildInsightRow(
                    'Correlation Strength',
                    _getCorrelationStrength(),
                    theme,
                  ),
                  SizedBox(height: 0.5.h),
                  _buildInsightRow(
                    'Average Sleep Quality',
                    _calculateAverageSleep().toStringAsFixed(1),
                    theme,
                  ),
                  SizedBox(height: 0.5.h),
                  _buildInsightRow('Best Sleep Day', _getBestSleepDay(), theme),
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

  String _getCorrelationStrength() {
    // Simple inverse correlation calculation
    double correlation = 0;
    for (var item in data) {
      final mentalLoad = (item["mentalLoad"] as num).toDouble();
      final sleepQuality = (item["sleepQuality"] as num).toDouble();
      correlation += (100 - mentalLoad) * sleepQuality;
    }
    correlation = correlation / (data.length * 10000);

    if (correlation > 0.7) return 'Strong Inverse';
    if (correlation > 0.4) return 'Moderate Inverse';
    return 'Weak Correlation';
  }

  double _calculateAverageSleep() {
    if (data.isEmpty) return 0;
    final sum = data.fold<double>(
      0,
      (prev, item) => prev + (item["sleepQuality"] as num).toDouble(),
    );
    return sum / data.length;
  }

  String _getBestSleepDay() {
    if (data.isEmpty) return 'N/A';
    var maxItem = data.reduce(
      (curr, next) =>
          (curr["sleepQuality"] as num) > (next["sleepQuality"] as num)
          ? curr
          : next,
    );
    return '${maxItem["day"]} (${maxItem["sleepQuality"]})';
  }

  Widget _buildInsightRow(String label, String value, ThemeData theme) {
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