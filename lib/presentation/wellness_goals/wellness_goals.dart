import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../models/wellness_goal.dart';
import '../../models/goal_milestone.dart';
import '../../models/goal_ai_recommendation.dart';
import '../../services/data_service.dart';
import '../../services/gemini_service.dart';
import '../../services/analytics_tracking_service.dart';
import '../../services/supabase_analytics_service.dart';
import './widgets/goal_card_widget.dart';
import './widgets/goal_creation_modal_widget.dart';
import './widgets/milestone_celebration_widget.dart';

class WellnessGoals extends StatefulWidget {
  const WellnessGoals({super.key});

  @override
  State<WellnessGoals> createState() => _WellnessGoalsState();
}

class _WellnessGoalsState extends State<WellnessGoals> {
  final _dataService = DataService.instance;
  final _geminiService = GeminiService.instance;

  List<WellnessGoal> _goals = [];
  List<GoalMilestone> _milestones = [];
  List<GoalAiRecommendation> _recommendations = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  int _currentStreak = 0;
  double _weeklyProgress = 0.0;
  GoalMilestone? _uncelebratedMilestone;

  @override
  void initState() {
    super.initState();
    _loadData(); // Changed from _loadWellnessGoals() to _loadData()

    // Track screen view
    SupabaseAnalyticsService.instance.trackScreenView('wellness_goals');
    AnalyticsTrackingService.instance.trackScreenView('Wellness Goals');
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final goals = await _dataService.getWellnessGoals(status: 'active');
      final milestones = await _dataService.getGoalMilestones();
      final recommendations = await _dataService.getGoalRecommendations();

      // Calculate current streak (max across all goals)
      int maxStreak = 0;
      for (final goal in goals) {
        if (goal.currentStreak > maxStreak) {
          maxStreak = goal.currentStreak;
        }
      }

      // Calculate weekly progress (average across active goals)
      double totalProgress = 0.0;
      if (goals.isNotEmpty) {
        for (final goal in goals) {
          totalProgress += goal.progressPercentage;
        }
        totalProgress = totalProgress / goals.length;
      }

      // Find uncelebrated milestone
      GoalMilestone? uncelebrated;
      for (final milestone in milestones) {
        if (!milestone.celebrated) {
          uncelebrated = milestone;
          break;
        }
      }

      setState(() {
        _goals = goals;
        _milestones = milestones;
        _recommendations = recommendations;
        _currentStreak = maxStreak;
        _weeklyProgress = totalProgress;
        _uncelebratedMilestone = uncelebrated;
        _isLoading = false;
      });

      // Show celebration if there's an uncelebrated milestone
      if (uncelebrated != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showMilestoneCelebration(uncelebrated!);
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load goals: $e')));
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _loadData();
    setState(() => _isRefreshing = false);
  }

  void _showGoalCreationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GoalCreationModalWidget(
        onGoalCreated: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }

  void _showMilestoneCelebration(GoalMilestone milestone) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MilestoneCelebrationWidget(
        milestone: milestone,
        onDismiss: () async {
          await _dataService.celebrateMilestone(milestone.id!);
          if (mounted) {
            Navigator.pop(context);
            setState(() => _uncelebratedMilestone = null);
          }
        },
      ),
    );
  }

  Future<void> _generateAiRecommendations() async {
    try {
      final recentScores = await _dataService.getMentalLoadScores(
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
      );
      if (recentScores.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Need more mental load data to generate recommendations',
              ),
            ),
          );
        }
        return;
      }

      final analysis = await _geminiService.analyzeBehavioralPatterns(
        mentalLoadScores: recentScores,
        activityRecords: [],
        analyticsRecords: [],
        appUsageRecords: [],
      );

      final existingCategories = _goals.map((g) => g.category).toList();
      final recommendations = await _geminiService.generateGoalRecommendations(
        recentScores: recentScores,
        analysis: analysis,
        existingGoalCategories: existingCategories,
      );

      // Save recommendations to database
      for (final rec in recommendations) {
        await _dataService.saveGoalRecommendation(
          recommendationText: rec,
          priority: 1,
        );
      }

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Generated ${recommendations.length} new recommendations',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate recommendations: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Wellness Goals'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology),
            tooltip: 'Generate AI Recommendations',
            onPressed: _generateAiRecommendations,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // Header with streak and progress
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStreakCounter(theme),
                              _buildWeeklyProgress(theme),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // AI Recommendations Section
                  if (_recommendations.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.h,
                        ),
                        child: Text(
                          'AI Recommendations',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: _buildRecommendationsList(theme)),
                  ],

                  // Active Goals Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.h,
                      ),
                      child: Text(
                        'Active Goals',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Goals List
                  _goals.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.flag_outlined,
                                  size: 60,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'No goals yet',
                                  style: theme.textTheme.titleMedium,
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  'Create your first wellness goal',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              return GoalCardWidget(
                                goal: _goals[index],
                                onProgressUpdate: () => _loadData(),
                              );
                            }, childCount: _goals.length),
                          ),
                        ),

                  SliverToBoxAdapter(child: SizedBox(height: 10.h)),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showGoalCreationModal,
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }

  Widget _buildRecommendationsList(ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recommendations.length,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemBuilder: (context, index) {
        final rec = _recommendations[index];
        return Card(
          margin: EdgeInsets.only(bottom: 1.h),
          child: ListTile(
            leading: Icon(
              Icons.lightbulb_outline,
              color: theme.colorScheme.primary,
            ),
            title: Text(rec.recommendationText),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {
                if (rec.id != null) {
                  await _dataService.dismissRecommendation(rec.id!);
                  _loadData();
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStreakCounter(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(51),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                '$_currentStreak',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Day Streak',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgress(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withAlpha(51),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: _weeklyProgress / 100,
                  strokeWidth: 6,
                  backgroundColor: theme.colorScheme.outline.withAlpha(51),
                  color: theme.colorScheme.secondary,
                ),
              ),
              Text(
                '${_weeklyProgress.toInt()}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Weekly Progress',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
