import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/analytics_tracking_service.dart';
import '../../services/data_service.dart';
import '../../services/gemini_service.dart';
import '../../services/health_service.dart';
import '../../services/supabase_analytics_service.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/daily_summary_card_widget.dart';
import './widgets/mental_load_gauge_widget.dart';
import './widgets/quick_action_buttons_widget.dart';
import './widgets/status_bar_widget.dart';

class DashboardInitialPage extends StatefulWidget {
  const DashboardInitialPage({super.key});

  @override
  State<DashboardInitialPage> createState() => _DashboardInitialPageState();
}

class _DashboardInitialPageState extends State<DashboardInitialPage> {
  final _dataService = DataService.instance;
  final _geminiService = GeminiService.instance;
  final _healthService = HealthService.instance;
  int _currentScore = 0;
  bool _isLoading = true;
  bool _isAnalyzing = false;
  String _monitoringDuration = "0h 0m";
  int _dataPointsCollected = 0;
  String _baselineComparison = "--";
  String currentState = "Balanced";
  String trendDirection = "stable";
  BehavioralAnalysis? _aiAnalysis;
  List<String>? _aiRecommendations;
  Map<String, dynamic>? _healthMetrics;
  Map<String, dynamic> _deviceStatus = {
    'connected': false,
    'deviceName': 'Not Connected',
    'lastSync': 'Never',
  };

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _trackScreenView();
    _initializeGemini();
    _loadDashboardData();
  }

  void _trackScreenView() {
    AnalyticsTrackingService.instance.trackScreenView('dashboard');
    AnalyticsTrackingService.instance.trackFeatureAdoption(
      featureCategory: 'mental_load_tracking',
      featureName: 'Dashboard View',
    );
  }

  void _initializeServices() {
    SupabaseAnalyticsService.instance.initialize();
  }

  void _initializeGemini() {
    try {
      _geminiService.initialize();
    } catch (e) {
      debugPrint('Gemini initialization error: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final startTime = DateTime.now();
      // Load health data and device status
      await _loadHealthData();

      // Load latest mental load score
      final latestScore = await _dataService.getLatestMentalLoadScore();
      if (latestScore != null) {
        setState(() {
          _currentScore = latestScore.score;
          currentState = latestScore.zone;
        });

        // Track mental load score to Supabase Analytics
        SupabaseAnalyticsService.instance.trackMentalLoadCheck();
        SupabaseAnalyticsService.instance.trackFeatureUsage(
          'mental_load_check',
        );

        // Track mental load check
        AnalyticsTrackingService.instance.trackFeatureUsed(
          featureName: 'Mental Load Check',
          screenName: 'dashboard',
          properties: {'score': latestScore.score},
        );
        AnalyticsTrackingService.instance.trackFeatureAdoption(
          featureCategory: 'mental_load_tracking',
          featureName: 'Mental Load Gauge',
          timeSpentSeconds: 5,
        );
      }

      // Load today's analytics
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      final todayScores = await _dataService.getMentalLoadScores(
        startDate: startOfDay,
        endDate: endOfDay,
      );

      if (todayScores.isNotEmpty) {
        final firstScore = todayScores.first;
        final duration = DateTime.now().difference(firstScore.recordedAt);
        final hours = duration.inHours;
        final minutes = duration.inMinutes % 60;

        final avgScore =
            todayScores.map((e) => e.score).reduce((a, b) => a + b) /
            todayScores.length;
        final baseline = 50.0;
        final comparison = avgScore - baseline;

        setState(() {
          _monitoringDuration = "${hours}h ${minutes}m";
          _dataPointsCollected = todayScores.length;
          _baselineComparison =
              "${comparison >= 0 ? '+' : ''}${comparison.toStringAsFixed(1)}";
        });
      }

      // Load AI analysis if enough data available
      if (todayScores.length >= 3) {
        _loadAiAnalysis();
      }

      // Load wellness goals
      // Remove: await _loadWellnessGoals();

      // Track performance metric
      final loadDuration = DateTime.now().difference(startTime);
      SupabaseAnalyticsService.instance.logPerformance(
        metricType: 'screen_load',
        metricName: 'Dashboard Load',
        durationMs: loadDuration.inMilliseconds,
        screenName: 'dashboard',
        metadata: {
          'data_points': _dataPointsCollected,
          'baseline_comparison': _baselineComparison,
        },
      );
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      AnalyticsTrackingService.instance.trackError(
        'Dashboard load error: $e',
        'Dashboard',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadHealthData() async {
    try {
      final healthData = await _healthService.fetchTodayHealthData();
      final deviceStatus = await _healthService.getDeviceStatus();

      setState(() {
        _healthMetrics = healthData;
        _deviceStatus = deviceStatus;
      });

      // Sync health data to analytics
      if (healthData != null) {
        await _healthService.syncHealthDataToAnalytics();
      }
    } catch (e) {
      debugPrint('Error loading health data: $e');
    }
  }

  Future<void> _handleScoreUpdate(int newScore) async {
    try {
      await _dataService.saveMentalLoadScore(score: newScore);
      setState(() => _currentScore = newScore);

      // Track mental load check
      AnalyticsTrackingService.instance.trackFeatureUsed(
        featureName: 'Mental Load Check',
        screenName: 'dashboard',
        properties: {'score': newScore},
      );
      AnalyticsTrackingService.instance.trackFeatureAdoption(
        featureCategory: 'mental_load_tracking',
        featureName: 'Mental Load Gauge',
        timeSpentSeconds: 5,
      );

      await _loadDashboardData();
    } catch (e) {
      debugPrint('Error saving mental load score: $e');
    }
  }

  Future<void> _loadAiAnalysis() async {
    if (_isAnalyzing) return;

    setState(() => _isAnalyzing = true);

    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(Duration(days: 7));

      // Fetch data for analysis
      final activityRecords = await _dataService.getActivityTrackingRecords(
        startDate: sevenDaysAgo,
        endDate: now,
      );

      final mentalLoadScores = await _dataService.getMentalLoadScores(
        startDate: sevenDaysAgo,
        endDate: now,
      );

      final analyticsRecords = await _dataService.getAnalyticsRecords(
        startDate: sevenDaysAgo,
        endDate: now,
      );

      // Get app usage for today
      final today = DateTime.now();
      final appUsageRecords = await _dataService.getAppUsageRecords(
        date: today,
      );

      // Perform AI analysis
      if (activityRecords.isNotEmpty || mentalLoadScores.isNotEmpty) {
        final analysis = await _geminiService.analyzeBehavioralPatterns(
          activityRecords: activityRecords,
          appUsageRecords: appUsageRecords,
          mentalLoadScores: mentalLoadScores,
          analyticsRecords: analyticsRecords,
        );

        final latestScore = await _dataService.getLatestMentalLoadScore();
        final currentZone = latestScore?.zone ?? 'moderate';

        final recommendations = await _geminiService.generateRecommendations(
          analysis: analysis,
          currentMentalLoadZone: currentZone,
        );

        setState(() {
          _aiAnalysis = analysis;
          _aiRecommendations = recommendations;
        });
      }
    } catch (e) {
      debugPrint('Error loading AI analysis: $e');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with app title
                _buildHeader(theme),

                SizedBox(height: 3.h),

                // Mental Load Gauge - Central focus
                MentalLoadGaugeWidget(
                  score: _currentScore,
                  onLongPress: _showDetailedBreakdown,
                ),

                SizedBox(height: 2.h),

                // Status Bar with current state
                StatusBarWidget(
                  currentState: currentState,
                  trendDirection: trendDirection,
                ),

                SizedBox(height: 3.h),

                // Daily Summary Card
                DailySummaryCardWidget(
                  monitoringDuration: _monitoringDuration,
                  dataPointsCollected: _dataPointsCollected,
                  baselineComparison: _baselineComparison,
                ),

                SizedBox(height: 2.h),

                // AI Insights Card
                // Quick Action Buttons
                QuickActionButtonsWidget(
                  onSensitivityTap: _showSensitivityAdjustment,
                  onQuietHoursTap: _toggleQuietHours,
                  onRecoveryTap: _openRecoveryGuidance,
                ),

                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "QuietCheck",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              "Real-time Mental Load Monitor",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: _openSoundPackSelection,
          icon: CustomIconWidget(
            iconName: 'music_note',
            color: theme.colorScheme.primary,
            size: 24,
          ),
          tooltip: "Sound Pack Selection",
        ),
      ],
    );
  }

  Future<void> _handleRefresh() async {
    await _loadDashboardData();
  }

  void _showDetailedBreakdown() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Contributing Factors", style: theme.textTheme.titleLarge),
              SizedBox(height: 2.h),
              _buildFactorRow(
                theme,
                "Screen Time",
                35,
                theme.colorScheme.primary,
              ),
              _buildFactorRow(
                theme,
                "Heart Rate Variability",
                25,
                Colors.orange,
              ),
              _buildFactorRow(theme, "Activity Level", 20, Colors.green),
              _buildFactorRow(theme, "Sleep Quality", 20, Colors.blue),
              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFactorRow(
    ThemeData theme,
    String label,
    int percentage,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            flex: 5,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: theme.colorScheme.surface,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            "$percentage%",
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showSensitivityAdjustment() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        double sensitivity = 0.5;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.all(4.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sensitivity Adjustment",
                    style: theme.textTheme.titleLarge,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    "Adjust how sensitive the mental load detection is to changes in your behavior and biometric signals.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Text("Low", style: theme.textTheme.bodySmall),
                      Expanded(
                        child: Slider(
                          value: sensitivity,
                          onChanged: (value) {
                            setModalState(() => sensitivity = value);
                          },
                        ),
                      ),
                      Text("High", style: theme.textTheme.bodySmall),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Save Changes"),
                    ),
                  ),
                  SizedBox(height: 2.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _toggleQuietHours() {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Quiet Hours toggled",
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.colorScheme.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openRecoveryGuidance() {
    Navigator.of(context, rootNavigator: true).pushNamed('/recovery-guidance');
  }

  void _openSoundPackSelection() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/sound-pack-selection');
  }
}
