import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/breathing_exercise_widget.dart';
import './widgets/emergency_resources_widget.dart';
import './widgets/quick_relief_technique_card.dart';
import '../../services/data_service.dart';
import '../../models/recovery_session.dart';
import '../../services/analytics_tracking_service.dart';
import '../../services/supabase_analytics_service.dart';

/// Recovery Guidance Screen
/// Provides immediate stress reduction techniques when mental load reaches concerning levels
/// Accessible via dashboard alert notifications or manual navigation during high-stress periods
class RecoveryGuidance extends StatefulWidget {
  const RecoveryGuidance({super.key});

  @override
  State<RecoveryGuidance> createState() => _RecoveryGuidanceState();
}

class _RecoveryGuidanceState extends State<RecoveryGuidance>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _selectedDuration = 5; // Default 5 minutes
  bool _isBreathingActive = false;
  bool _audioGuidanceEnabled = true;

  // Quick relief techniques data
  final List<Map<String, dynamic>> _reliefTechniques = [
    {
      "id": 1,
      "title": "Progressive Muscle Relaxation",
      "description":
          "Systematically tense and relax different muscle groups to release physical tension and promote deep relaxation.",
      "duration": "10-15 minutes",
      "steps": [
        "Find a comfortable seated or lying position",
        "Start with your feet - tense for 5 seconds, then release",
        "Move up to calves, thighs, abdomen, chest, arms, and face",
        "Focus on the contrast between tension and relaxation",
        "Breathe deeply throughout the exercise",
      ],
      "icon": "self_improvement",
      "isExpanded": false,
      "isCompleted": false,
      "timerActive": false,
      "elapsedTime": 0,
    },
    {
      "id": 2,
      "title": "Grounding Exercise (5-4-3-2-1)",
      "description":
          "Use your five senses to anchor yourself in the present moment and reduce anxiety.",
      "duration": "5-7 minutes",
      "steps": [
        "Acknowledge 5 things you can see around you",
        "Acknowledge 4 things you can touch",
        "Acknowledge 3 things you can hear",
        "Acknowledge 2 things you can smell",
        "Acknowledge 1 thing you can taste",
      ],
      "icon": "visibility",
      "isExpanded": false,
      "isCompleted": false,
      "timerActive": false,
      "elapsedTime": 0,
    },
    {
      "id": 3,
      "title": "Mindful Observation",
      "description":
          "Focus your complete attention on a single object to quiet racing thoughts and promote calm.",
      "duration": "3-5 minutes",
      "steps": [
        "Choose an object in your environment (plant, artwork, etc.)",
        "Observe it as if seeing it for the first time",
        "Notice colors, textures, shapes, and details",
        "When your mind wanders, gently return focus to the object",
        "Continue for 3-5 minutes with gentle awareness",
      ],
      "icon": "center_focus_strong",
      "isExpanded": false,
      "isCompleted": false,
      "timerActive": false,
      "elapsedTime": 0,
    },
  ];

  final _dataService = DataService.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
    _trackScreenView();
    _loadRecoverySessions();
  }

  void _trackScreenView() {
    SupabaseAnalyticsService.instance.trackScreenView('recovery_guidance');
    AnalyticsTrackingService.instance.trackScreenView('Recovery Guidance');
  }

  Future<void> _startRecoverySession(
    String techniqueType,
    String title,
    int durationMinutes,
  ) async {
    try {
      // Remove createRecoverySession call, create session directly
      final userId = _dataService.currentUserId;
      if (userId == null) return;

      final session = RecoverySession(
        userId: userId,
        techniqueType: techniqueType,
        techniqueTitle: title,
        durationMinutes: durationMinutes,
        completed: false,
        elapsedTimeSeconds: 0,
        sessionDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _dataService.saveRecoverySession(session);

      // Track recovery session start
      AnalyticsTrackingService.instance.trackFeatureUsed(
        featureName: 'Recovery Session Started',
        screenName: 'recovery_guidance',
        properties: {
          'technique_type': techniqueType,
          'duration_minutes': durationMinutes,
        },
      );
      AnalyticsTrackingService.instance.trackFeatureAdoption(
        featureCategory: 'recovery_guidance',
        featureName: title,
        timeSpentSeconds: durationMinutes * 60,
      );

      await _loadRecoverySessions();
    } catch (e) {
      debugPrint('Error starting recovery session: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _toggleBreathing() {
    setState(() {
      _isBreathingActive = !_isBreathingActive;
    });
    HapticFeedback.lightImpact();
  }

  void _updateDuration(int minutes) {
    setState(() {
      _selectedDuration = minutes;
    });
  }

  void _toggleAudioGuidance() {
    setState(() {
      _audioGuidanceEnabled = !_audioGuidanceEnabled;
    });
    HapticFeedback.lightImpact();
  }

  void _toggleTechniqueExpansion(int index) {
    setState(() {
      _reliefTechniques[index]["isExpanded"] =
          !(_reliefTechniques[index]["isExpanded"] as bool);
    });
  }

  void _toggleTechniqueTimer(int index) {
    setState(() {
      _reliefTechniques[index]["timerActive"] =
          !(_reliefTechniques[index]["timerActive"] as bool);
      if (_reliefTechniques[index]["timerActive"] as bool) {
        _startTechniqueTimer(index);
      }
    });
    HapticFeedback.lightImpact();
  }

  void _startTechniqueTimer(int index) {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted || !(_reliefTechniques[index]["timerActive"] as bool)) {
        timer.cancel();
        return;
      }
      setState(() {
        _reliefTechniques[index]["elapsedTime"] =
            (_reliefTechniques[index]["elapsedTime"] as int) + 1;
      });
    });
  }

  void _completeTechnique(int index) {
    setState(() {
      _reliefTechniques[index]["isCompleted"] = true;
      _reliefTechniques[index]["timerActive"] = false;
    });
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Great job! Technique completed successfully.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadRecoverySessions() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await _dataService.getRecoverySessions(limit: 10);

      for (var session in sessions) {
        final techniqueIndex = _reliefTechniques.indexWhere(
          (t) => t['title'] == session.techniqueTitle,
        );
        if (techniqueIndex != -1) {
          setState(() {
            _reliefTechniques[techniqueIndex]['isCompleted'] =
                session.completed;
            _reliefTechniques[techniqueIndex]['elapsedTime'] =
                session.elapsedTimeSeconds;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading recovery sessions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRecoverySession({
    required String techniqueType,
    required String techniqueTitle,
    required int durationMinutes,
    required bool completed,
    required int elapsedTimeSeconds,
  }) async {
    try {
      final userId = _dataService.currentUserId;
      if (userId == null) return;

      final session = RecoverySession(
        userId: userId,
        techniqueType: techniqueType,
        techniqueTitle: techniqueTitle,
        durationMinutes: durationMinutes,
        completed: completed,
        elapsedTimeSeconds: elapsedTimeSeconds,
        sessionDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _dataService.saveRecoverySession(session);
    } catch (e) {
      debugPrint('Error saving recovery session: $e');
    }
  }

  void _handleTechniqueComplete(int index) {
    final technique = _reliefTechniques[index];
    _saveRecoverySession(
      techniqueType: _getTechniqueType(technique['icon'] as String),
      techniqueTitle: technique['title'] as String,
      durationMinutes: _parseDuration(technique['duration'] as String),
      completed: true,
      elapsedTimeSeconds: technique['elapsedTime'] as int? ?? 0,
    );
  }

  String _getTechniqueType(String icon) {
    switch (icon) {
      case 'self_improvement':
        return 'muscle_relaxation';
      case 'visibility':
        return 'grounding';
      case 'center_focus_strong':
        return 'mindful_observation';
      default:
        return 'breathing';
    }
  }

  int _parseDuration(String duration) {
    final match = RegExp(r'(\d+)').firstMatch(duration);
    return match != null ? int.parse(match.group(1)!) : 5;
  }

  void _returnToDashboard() {
    HapticFeedback.lightImpact();
    Navigator.of(context, rootNavigator: true).pushNamed('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.05),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header with close button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recovery Guidance',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        onPressed: _returnToDashboard,
                        icon: CustomIconWidget(
                          iconName: 'close',
                          color: theme.colorScheme.onSurface,
                          size: 24,
                        ),
                        tooltip: 'Return to Dashboard',
                      ),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 2.h),

                        // Breathing Exercise Section
                        BreathingExerciseWidget(
                          isActive: _isBreathingActive,
                          selectedDuration: _selectedDuration,
                          audioGuidanceEnabled: _audioGuidanceEnabled,
                          onToggleBreathing: _toggleBreathing,
                          onUpdateDuration: _updateDuration,
                          onToggleAudioGuidance: _toggleAudioGuidance,
                        ),

                        SizedBox(height: 4.h),

                        // Quick Relief Techniques Section
                        Text(
                          'Quick Relief Techniques',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),

                        SizedBox(height: 2.h),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _reliefTechniques.length,
                          itemBuilder: (context, index) {
                            return QuickReliefTechniqueCard(
                              technique: _reliefTechniques[index],
                              onToggleExpansion: () =>
                                  _toggleTechniqueExpansion(index),
                              onToggleTimer: () => _toggleTechniqueTimer(index),
                              onComplete: () => _completeTechnique(index),
                            );
                          },
                        ),

                        SizedBox(height: 4.h),

                        // Emergency Resources Section
                        EmergencyResourcesWidget(),

                        SizedBox(height: 4.h),

                        // Completion message
                        Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              CustomIconWidget(
                                iconName: 'favorite',
                                color: theme.colorScheme.primary,
                                size: 32,
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                'You\'re Taking Care of Yourself',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                'Every moment you spend on recovery is an investment in your well-being. You\'re doing great.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 2.h),
                              ElevatedButton(
                                onPressed: _returnToDashboard,
                                child: Text('Return to Dashboard'),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 4.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
