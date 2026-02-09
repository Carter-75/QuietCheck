import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../services/analytics_tracking_service.dart';
import '../../services/data_service.dart';
import '../../services/health_service.dart';
import '../../services/supabase_analytics_service.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/baseline_comparison_widget.dart';
import './widgets/chart_customization_sheet.dart';
import './widgets/sleep_correlation_widget.dart';
import './widgets/trend_chart_widget.dart';

/// Analytics View screen for QuietCheck mental health application.
/// Displays comprehensive mental load trends and correlations through mobile-optimized charts.
/// Implements segmented time period controls and interactive data visualization.
class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView>
    with SingleTickerProviderStateMixin {
  // Time period selection: 0 = 7 days, 1 = 30 days, 2 = 90 days
  int _selectedPeriod = 0;
  bool _isRefreshing = false;
  final _dataService = DataService.instance;
  final _healthService = HealthService.instance;
  bool _isLoading = true;

  List<Map<String, dynamic>> _mentalLoadData = [];
  List<Map<String, dynamic>> _baselineData = [];
  List<Map<String, dynamic>> _sleepCorrelationData = [];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();

    // Track screen view
    SupabaseAnalyticsService.instance.trackScreenView('analytics_view');
    AnalyticsTrackingService.instance.trackScreenView('Analytics View');
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: _getPeriodDays()));

      final records = await _dataService.getAnalyticsRecords(
        startDate: startDate,
        endDate: endDate,
      );

      if (records.isNotEmpty) {
        setState(() {
          _mentalLoadData = records
              .map(
                (r) => {
                  'day': _formatDay(r.date),
                  'load': r.avgMentalLoad.toInt(),
                  'date': _formatDate(r.date),
                },
              )
              .toList();

          _baselineData = records
              .map(
                (r) => {
                  'day': _formatDay(r.date),
                  'current': r.avgMentalLoad.toInt(),
                  'baseline': (r.baselineComparison ?? 0) + 50,
                },
              )
              .toList();

          _sleepCorrelationData = records
              .map(
                (r) => {
                  'day': _formatDay(r.date),
                  'mentalLoad': r.avgMentalLoad.toInt(),
                  'sleepQuality': r.sleepQuality ?? 70,
                },
              )
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading analytics data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int _getPeriodDays() {
    switch (_selectedPeriod) {
      case 0:
        return 7;
      case 1:
        return 30;
      case 2:
        return 90;
      default:
        return 7;
    }
  }

  String _formatDay(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await _loadAnalyticsData();
    setState(() => _isRefreshing = false);
  }

  void _handlePeriodChange(int period) {
    setState(() => _selectedPeriod = period);
    _loadAnalyticsData();
  }

  void _showCustomizationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChartCustomizationSheet(
        onApply: (settings) {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _exportData() {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export feature available in premium version'),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: theme.colorScheme.primary,
          child: CustomScrollView(
            slivers: [
              // Header with title and export button
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Analytics',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _showCustomizationSheet,
                            icon: CustomIconWidget(
                              iconName: 'tune',
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            tooltip: 'Customize charts',
                          ),
                          IconButton(
                            onPressed: _exportData,
                            icon: CustomIconWidget(
                              iconName: 'share',
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            tooltip: 'Export data',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Time period segmented control
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 3.h),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildPeriodButton('7 Days', 0, theme),
                        _buildPeriodButton('30 Days', 1, theme),
                        _buildPeriodButton('90 Days', 2, theme),
                      ],
                    ),
                  ),
                ),
              ),

              // Trend Chart Card
              SliverToBoxAdapter(
                child: TrendChartWidget(
                  data: _mentalLoadData,
                  period: _selectedPeriod,
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 2.h)),

              // Baseline Comparison Card
              SliverToBoxAdapter(
                child: BaselineComparisonWidget(data: _baselineData),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 2.h)),

              // Sleep Correlation Card
              SliverToBoxAdapter(
                child: SleepCorrelationWidget(data: _sleepCorrelationData),
              ),

              // Bottom padding for scroll
              SliverToBoxAdapter(child: SizedBox(height: 4.h)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, int index, ThemeData theme) {
    final isSelected = _selectedPeriod == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
