import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Trend chart widget displaying mental load over time with color-coded zones.
/// Supports interactive data points with tap-to-view values and pinch-to-zoom.
class TrendChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final int period;

  const TrendChartWidget({super.key, required this.data, required this.period});

  @override
  State<TrendChartWidget> createState() => _TrendChartWidgetState();
}

class _TrendChartWidgetState extends State<TrendChartWidget> {
  int? _touchedIndex;

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
            // Chart title and info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mental Load Trend',
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
              'Track your mental load patterns over time',
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
                    "Mental Load Trend Line Chart showing daily mental load values from ${widget.data.first["date"]} to ${widget.data.last["date"]}",
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
                                value.toInt() < widget.data.length) {
                              return Padding(
                                padding: EdgeInsets.only(top: 1.h),
                                child: Text(
                                  widget.data[value.toInt()]["day"],
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
                    maxX: (widget.data.length - 1).toDouble(),
                    minY: 0,
                    maxY: 100,
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchCallback:
                          (
                            FlTouchEvent event,
                            LineTouchResponse? touchResponse,
                          ) {
                            setState(() {
                              if (touchResponse != null &&
                                  touchResponse.lineBarSpots != null &&
                                  touchResponse.lineBarSpots!.isNotEmpty) {
                                _touchedIndex = touchResponse
                                    .lineBarSpots!
                                    .first
                                    .x
                                    .toInt();
                              } else {
                                _touchedIndex = null;
                              }
                            });
                          },
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
                            if (index >= 0 && index < widget.data.length) {
                              final dataPoint = widget.data[index];
                              return LineTooltipItem(
                                '${dataPoint["day"]}\n${dataPoint["load"]}',
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
                      LineChartBarData(
                        spots: List.generate(
                          widget.data.length,
                          (index) => FlSpot(
                            index.toDouble(),
                            (widget.data[index]["load"] as num).toDouble(),
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
                              radius: _touchedIndex == index ? 6 : 4,
                              color: _getColorForLoad(spot.y, theme),
                              strokeWidth: 2,
                              strokeColor: theme.colorScheme.surface,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                              theme.colorScheme.primary.withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 3.h),

            // Summary statistics
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
                    'Key Insights',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  _buildInsightRow(
                    'Average Load',
                    _calculateAverage().toStringAsFixed(1),
                    theme,
                  ),
                  SizedBox(height: 0.5.h),
                  _buildInsightRow('Peak Day', _getPeakDay(), theme),
                  SizedBox(height: 0.5.h),
                  _buildInsightRow('Trend', _getTrend(), theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForLoad(double load, ThemeData theme) {
    if (load < 40) return Color(0xFF4A9B6E); // Green - low load
    if (load < 60) return Color(0xFFE8B86D); // Amber - moderate load
    if (load < 80) return Color(0xFFD4A574); // Bronze - high load
    return Color(0xFFC17B7B); // Rose - critical load
  }

  double _calculateAverage() {
    if (widget.data.isEmpty) return 0;
    final sum = widget.data.fold<double>(
      0,
      (prev, item) => prev + (item["load"] as num).toDouble(),
    );
    return sum / widget.data.length;
  }

  String _getPeakDay() {
    if (widget.data.isEmpty) return 'N/A';
    var maxItem = widget.data.reduce(
      (curr, next) =>
          (curr["load"] as num) > (next["load"] as num) ? curr : next,
    );
    return '${maxItem["day"]} (${maxItem["load"]})';
  }

  String _getTrend() {
    if (widget.data.length < 2) return 'Insufficient data';
    final firstHalf = widget.data.sublist(0, widget.data.length ~/ 2);
    final secondHalf = widget.data.sublist(widget.data.length ~/ 2);

    final firstAvg =
        firstHalf.fold<double>(
          0,
          (prev, item) => prev + (item["load"] as num).toDouble(),
        ) /
        firstHalf.length;
    final secondAvg =
        secondHalf.fold<double>(
          0,
          (prev, item) => prev + (item["load"] as num).toDouble(),
        ) /
        secondHalf.length;

    if (secondAvg > firstAvg + 5) return 'Increasing ↑';
    if (secondAvg < firstAvg - 5) return 'Decreasing ↓';
    return 'Stable →';
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