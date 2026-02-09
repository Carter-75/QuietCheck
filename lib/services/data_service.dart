import '../models/activity_tracking_record.dart';
import '../models/analytics_record.dart';
import '../models/app_usage_record.dart';
import '../models/billing_history.dart';
import '../models/goal_ai_recommendation.dart';
import '../models/goal_milestone.dart';
import '../models/mental_load_score.dart';
import '../models/notification_delivery_log.dart';
import '../models/recovery_session.dart';
import '../models/subscription_data.dart';
import '../models/user_settings.dart';
import '../models/wellness_goal.dart';
import './encryption_service.dart';
import './supabase_service.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive data service for mental health app with encryption support
class DataService {
  static DataService? _instance;
  static DataService get instance => _instance ??= DataService._();

  DataService._();

  final _supabase = SupabaseService.instance.client;
  final _encryption = EncryptionService.instance;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ==================== Mental Load Scores ====================

  /// Save a new mental load score
  Future<MentalLoadScore?> saveMentalLoadScore({
    required int score,
    String? context,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final zone = _getZoneForScore(score);
      final encryptedContext = context != null
          ? _encryption.encrypt(context)
          : null;

      final response = await _supabase
          .from('mental_load_scores')
          .insert({
            'user_id': currentUserId,
            'score': score,
            'zone': zone,
            'encrypted_context': encryptedContext,
            'recorded_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return MentalLoadScore.fromJson(response);
    } catch (e) {
      throw Exception('Failed to save mental load score: $e');
    }
  }

  /// Get latest mental load score
  Future<MentalLoadScore?> getLatestMentalLoadScore() async {
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelays = [1, 3, 5]; // seconds

    while (retryCount <= maxRetries) {
      try {
        if (currentUserId == null) return null;
        final userId = currentUserId!;

        final response = await _supabase
            .from('mental_load_scores')
            .select()
            .eq('user_id', userId)
            .order('recorded_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (response == null) return null;
        return MentalLoadScore.fromJson(response);
      } catch (e) {
        if (_isTransientError(e) && retryCount < maxRetries) {
          retryCount++;
          debugPrint(
            '⚠️ Retry $retryCount/$maxRetries for getLatestMentalLoadScore: $e',
          );
          await Future.delayed(Duration(seconds: retryDelays[retryCount - 1]));
        } else {
          throw Exception('Failed to get latest mental load score: $e');
        }
      }
    }
    return null;
  }

  /// Get mental load scores for a date range
  Future<List<MentalLoadScore>> getMentalLoadScores({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelays = [1, 3, 5];

    while (retryCount <= maxRetries) {
      try {
        if (currentUserId == null) return [];
        final userId = currentUserId!;

        final response = await _supabase
            .from('mental_load_scores')
            .select()
            .eq('user_id', userId)
            .gte('recorded_at', startDate.toIso8601String())
            .lte('recorded_at', endDate.toIso8601String())
            .order('recorded_at', ascending: true);

        return (response as List)
            .map((e) => MentalLoadScore.fromJson(e))
            .toList();
      } catch (e) {
        if (_isTransientError(e) && retryCount < maxRetries) {
          retryCount++;
          debugPrint(
            '⚠️ Retry $retryCount/$maxRetries for getMentalLoadScores: $e',
          );
          await Future.delayed(Duration(seconds: retryDelays[retryCount - 1]));
        } else {
          throw Exception('Failed to get mental load scores: $e');
        }
      }
    }
    return [];
  }

  // ==================== User Settings ====================

  /// Get user settings
  Future<UserSettings?> getUserSettings() async {
    try {
      if (currentUserId == null) return null;
      final userId = currentUserId!;

      final response = await _supabase
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserSettings.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get user settings: $e');
    }
  }

  /// Update user settings
  Future<UserSettings?> updateUserSettings(UserSettings settings) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');
      final userId = currentUserId!;

      final response = await _supabase
          .from('user_settings')
          .update(settings.toJson())
          .eq('user_id', userId)
          .select()
          .single();

      return UserSettings.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update user settings: $e');
    }
  }

  // ==================== Analytics Records ====================

  /// Save analytics record for a specific date
  Future<AnalyticsRecord?> saveAnalyticsRecord(AnalyticsRecord record) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');
      final userId = currentUserId!;

      // Check if record exists for this date
      final existing = await _supabase
          .from('analytics_records')
          .select()
          .eq('user_id', userId)
          .eq('date', record.date.toIso8601String().split('T')[0])
          .maybeSingle();

      if (existing != null) {
        // Update existing record
        final response = await _supabase
            .from('analytics_records')
            .update(record.toJson())
            .eq('id', existing['id'])
            .select()
            .single();
        return AnalyticsRecord.fromJson(response);
      } else {
        // Insert new record
        final response = await _supabase
            .from('analytics_records')
            .insert(record.toJson())
            .select()
            .single();
        return AnalyticsRecord.fromJson(response);
      }
    } catch (e) {
      throw Exception('Failed to save analytics record: $e');
    }
  }

  /// Get analytics records for a date range
  Future<List<AnalyticsRecord>> getAnalyticsRecords({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (currentUserId == null) return [];
      final userId = currentUserId!;

      final response = await _supabase
          .from('analytics_records')
          .select()
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('date', ascending: true);

      return (response as List)
          .map((e) => AnalyticsRecord.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to get analytics records: $e');
    }
  }

  // ==================== Subscription Data ====================

  /// Get subscription data
  Future<SubscriptionData?> getSubscriptionData() async {
    try {
      if (currentUserId == null) return null;
      final userId = currentUserId!;

      final response = await _supabase
          .from('subscription_data')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return SubscriptionData.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get subscription data: $e');
    }
  }

  /// Update subscription data
  Future<SubscriptionData?> updateSubscriptionData(
    SubscriptionData data,
  ) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');
      final userId = currentUserId!;

      final response = await _supabase
          .from('subscription_data')
          .update(data.toJson())
          .eq('user_id', userId)
          .select()
          .single();

      return SubscriptionData.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update subscription data: $e');
    }
  }

  // ==================== Billing History ====================

  /// Get billing history
  Future<List<BillingHistory>> getBillingHistory() async {
    try {
      if (currentUserId == null) return [];
      final userId = currentUserId!;

      final response = await _supabase
          .from('billing_history')
          .select()
          .eq('user_id', userId)
          .order('transaction_date', ascending: false);

      return (response as List).map((e) => BillingHistory.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to get billing history: $e');
    }
  }

  /// Add billing history entry
  Future<BillingHistory?> addBillingHistory(BillingHistory history) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('billing_history')
          .insert(history.toJson())
          .select()
          .single();

      return BillingHistory.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add billing history: $e');
    }
  }

  // ==================== Recovery Sessions ====================

  /// Save recovery session
  Future<RecoverySession?> saveRecoverySession(RecoverySession session) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('recovery_sessions')
          .insert(session.toJson())
          .select()
          .single();

      return RecoverySession.fromJson(response);
    } catch (e) {
      throw Exception('Failed to save recovery session: $e');
    }
  }

  /// Update recovery session
  Future<RecoverySession?> updateRecoverySession(
    RecoverySession session,
  ) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      if (session.id == null) {
        throw Exception('Session ID is required for update');
      }

      final response = await _supabase
          .from('recovery_sessions')
          .update(session.toJson())
          .eq('id', session.id!)
          .select()
          .single();

      return RecoverySession.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update recovery session: $e');
    }
  }

  /// Get recovery sessions
  Future<List<RecoverySession>> getRecoverySessions({int limit = 10}) async {
    try {
      if (currentUserId == null) return [];
      final userId = currentUserId!;

      final response = await _supabase
          .from('recovery_sessions')
          .select()
          .eq('user_id', userId)
          .order('session_date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((e) => RecoverySession.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to get recovery sessions: $e');
    }
  }

  // ==================== Activity Tracking ====================

  /// Save activity tracking record
  Future<ActivityTrackingRecord?> saveActivityTrackingRecord(
    ActivityTrackingRecord record,
  ) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('activity_tracking_records')
          .upsert(record.toJson())
          .select()
          .single();

      return ActivityTrackingRecord.fromJson(response);
    } catch (e) {
      throw Exception('Failed to save activity tracking record: $e');
    }
  }

  /// Get activity tracking records for date range
  Future<List<ActivityTrackingRecord>> getActivityTrackingRecords({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (currentUserId == null) return [];
      final userId = currentUserId!;

      final response = await _supabase
          .from('activity_tracking_records')
          .select()
          .eq('user_id', userId)
          .gte('tracking_date', startDate.toIso8601String().split('T')[0])
          .lte('tracking_date', endDate.toIso8601String().split('T')[0])
          .order('tracking_date', ascending: true);

      return (response as List)
          .map((e) => ActivityTrackingRecord.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to get activity tracking records: $e');
    }
  }

  /// Save burnout prediction
  Future<void> saveBurnoutPrediction({
    required DateTime predictedThresholdDate,
    required int currentMentalLoadScore,
    required int predictedMentalLoadScore,
    required int hoursUntilThreshold,
    required String confidenceLevel,
    required List<String> identifiedTriggers,
    required List<String> behavioralPatterns,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      final userId = currentUserId!;

      await _supabase.from('burnout_predictions').insert({
        'user_id': userId,
        'predicted_threshold_date': predictedThresholdDate.toIso8601String(),
        'current_mental_load_score': currentMentalLoadScore,
        'predicted_mental_load_score': predictedMentalLoadScore,
        'hours_until_threshold': hoursUntilThreshold,
        'confidence_level': confidenceLevel,
        'identified_triggers': identifiedTriggers,
        'behavioral_patterns': behavioralPatterns,
        'warning_sent': false,
        'prediction_timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to save burnout prediction: $e');
    }
  }

  /// Get latest burnout prediction
  Future<Map<String, dynamic>?> getLatestBurnoutPrediction() async {
    try {
      if (currentUserId == null) return null;
      final userId = currentUserId!;

      final response = await _supabase
          .from('burnout_predictions')
          .select()
          .eq('user_id', userId)
          .order('prediction_timestamp', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to get latest burnout prediction: $e');
    }
  }

  /// Mark burnout warning as sent
  Future<void> markBurnoutWarningSent(String predictionId) async {
    try {
      await _supabase
          .from('burnout_predictions')
          .update({
            'warning_sent': true,
            'warning_sent_at': DateTime.now().toIso8601String(),
          })
          .eq('id', predictionId);
    } catch (e) {
      throw Exception('Failed to mark burnout warning as sent: $e');
    }
  }

  /// Get latest activity tracking record
  Future<ActivityTrackingRecord?> getLatestActivityTrackingRecord() async {
    try {
      if (currentUserId == null) return null;
      final userId = currentUserId!;

      final response = await _supabase
          .from('activity_tracking_records')
          .select()
          .eq('user_id', userId)
          .order('data_collection_timestamp', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return ActivityTrackingRecord.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get latest activity tracking record: $e');
    }
  }

  // ==================== App Usage Records ====================

  /// Save app usage record
  Future<AppUsageRecord?> saveAppUsageRecord(AppUsageRecord record) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('app_usage_records')
          .upsert(record.toJson())
          .select()
          .single();

      return AppUsageRecord.fromJson(response);
    } catch (e) {
      throw Exception('Failed to save app usage record: $e');
    }
  }

  /// Get app usage records for a specific date
  Future<List<AppUsageRecord>> getAppUsageRecords({
    required DateTime date,
  }) async {
    try {
      if (currentUserId == null) return [];
      final userId = currentUserId!;

      final response = await _supabase
          .from('app_usage_records')
          .select()
          .eq('user_id', userId)
          .eq('tracking_date', date.toIso8601String().split('T')[0])
          .order('usage_duration_minutes', ascending: false);

      return (response as List).map((e) => AppUsageRecord.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to get app usage records: $e');
    }
  }

  /// Get top apps by usage duration
  Future<List<AppUsageRecord>> getTopAppsByUsage({
    required DateTime date,
    int limit = 10,
  }) async {
    try {
      if (currentUserId == null) return [];
      final userId = currentUserId!;

      final response = await _supabase
          .from('app_usage_records')
          .select()
          .eq('user_id', userId)
          .eq('tracking_date', date.toIso8601String().split('T')[0])
          .order('usage_duration_minutes', ascending: false)
          .limit(limit);

      return (response as List).map((e) => AppUsageRecord.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to get top apps by usage: $e');
    }
  }

  // ==================== Wellness Goals ====================

  /// Fetch all wellness goals for current user
  Future<List<WellnessGoal>> getWellnessGoals({String? status}) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      var query = _supabase
          .from('wellness_goals')
          .select()
          .eq('user_id', currentUserId!);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((json) => WellnessGoal.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch wellness goals: $e');
    }
  }

  /// Create a new wellness goal
  Future<WellnessGoal?> createWellnessGoal({
    required String title,
    String? description,
    required String category,
    required int targetValue,
    required String unit,
    required DateTime targetDate,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final response = await _supabase
          .from('wellness_goals')
          .insert({
            'user_id': currentUserId,
            'title': title,
            'description': description,
            'category': category,
            'target_value': targetValue,
            'unit': unit,
            'start_date': now.toIso8601String(),
            'target_date': targetDate.toIso8601String(),
          })
          .select()
          .single();

      return WellnessGoal.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create wellness goal: $e');
    }
  }

  /// Update wellness goal progress
  Future<WellnessGoal?> updateGoalProgress({
    required String goalId,
    required int progressValue,
    String? notes,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      // Get current goal
      final goalResponse = await _supabase
          .from('wellness_goals')
          .select()
          .eq('id', goalId)
          .single();

      final goal = WellnessGoal.fromJson(goalResponse);
      final newValue = goal.currentValue + progressValue;
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // Calculate streak
      int newStreak = goal.currentStreak;
      if (goal.lastProgressDate != null) {
        final lastDate = DateTime(
          goal.lastProgressDate!.year,
          goal.lastProgressDate!.month,
          goal.lastProgressDate!.day,
        );
        final daysDiff = todayDate.difference(lastDate).inDays;

        if (daysDiff == 1) {
          newStreak += 1;
        } else if (daysDiff > 1) {
          newStreak = 1;
        }
      } else {
        newStreak = 1;
      }

      final newLongestStreak = newStreak > goal.longestStreak
          ? newStreak
          : goal.longestStreak;

      // Check if goal is completed
      final isCompleted = newValue >= goal.targetValue;
      final status = isCompleted ? 'completed' : goal.status;

      // Update goal
      final updateData = {
        'current_value': newValue,
        'current_streak': newStreak,
        'longest_streak': newLongestStreak,
        'last_progress_date': todayDate.toIso8601String(),
        'status': status,
        if (isCompleted) 'completed_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('wellness_goals')
          .update(updateData)
          .eq('id', goalId)
          .select()
          .single();

      // Log progress
      await _supabase.from('goal_progress_logs').insert({
        'goal_id': goalId,
        'user_id': currentUserId,
        'progress_value': progressValue,
        'notes': notes,
      });

      // Create milestone if applicable
      if (isCompleted) {
        await _supabase.from('goal_milestones').insert({
          'goal_id': goalId,
          'user_id': currentUserId,
          'milestone_type': 'goal_completion',
          'title': 'Goal Completed!',
          'description':
              'Congratulations on completing your goal: ${goal.title}',
          'achievement_value': goal.targetValue,
        });
      } else if (newStreak > 0 && newStreak % 7 == 0) {
        await _supabase.from('goal_milestones').insert({
          'goal_id': goalId,
          'user_id': currentUserId,
          'milestone_type': 'streak_achievement',
          'title': '$newStreak Day Streak!',
          'description': 'Amazing consistency on ${goal.title}',
          'achievement_value': newStreak,
        });
      }

      return WellnessGoal.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update goal progress: $e');
    }
  }

  /// Get milestones for a goal
  Future<List<GoalMilestone>> getGoalMilestones({String? goalId}) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      var query = _supabase
          .from('goal_milestones')
          .select()
          .eq('user_id', currentUserId!);

      if (goalId != null) {
        query = query.eq('goal_id', goalId);
      }

      final response = await query.order('achieved_at', ascending: false);
      return (response as List)
          .map((json) => GoalMilestone.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch goal milestones: $e');
    }
  }

  /// Mark milestone as celebrated
  Future<void> celebrateMilestone(String milestoneId) async {
    try {
      await _supabase
          .from('goal_milestones')
          .update({'celebrated': true})
          .eq('id', milestoneId);
    } catch (e) {
      throw Exception('Failed to celebrate milestone: $e');
    }
  }

  /// Get AI recommendations for goals
  Future<List<GoalAiRecommendation>> getGoalRecommendations({
    String? goalId,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      var query = _supabase
          .from('goal_ai_recommendations')
          .select()
          .eq('user_id', currentUserId!)
          .eq('dismissed', false);

      if (goalId != null) {
        query = query.eq('goal_id', goalId);
      }

      final response = await query
          .order('priority', ascending: false)
          .order('generated_at', ascending: false);
      return (response as List)
          .map((json) => GoalAiRecommendation.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch recommendations: $e');
    }
  }

  /// Save AI recommendation
  Future<GoalAiRecommendation?> saveGoalRecommendation({
    String? goalId,
    required String recommendationText,
    String? reasoning,
    int priority = 1,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('goal_ai_recommendations')
          .insert({
            'user_id': currentUserId,
            'goal_id': goalId,
            'recommendation_text': recommendationText,
            'reasoning': reasoning,
            'priority': priority,
            'generated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return GoalAiRecommendation.fromJson(response);
    } catch (e) {
      throw Exception('Failed to save recommendation: $e');
    }
  }

  /// Dismiss AI recommendation
  Future<void> dismissRecommendation(String recommendationId) async {
    try {
      await _supabase
          .from('goal_ai_recommendations')
          .update({'dismissed': true})
          .eq('id', recommendationId);
    } catch (e) {
      throw Exception('Failed to dismiss recommendation: $e');
    }
  }

  // ==================== Notification Delivery Logs ====================

  /// Get notification delivery logs
  Future<List<NotificationDeliveryLog>> getNotificationDeliveryLogs({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (currentUserId == null) return [];
      final userId = currentUserId!;

      var query = _supabase
          .from('notification_delivery_logs')
          .select()
          .eq('user_id', userId);

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((e) => NotificationDeliveryLog.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to get notification delivery logs: $e');
    }
  }

  /// Get pending/deferred notifications
  Future<List<NotificationDeliveryLog>> getPendingNotifications() async {
    try {
      if (currentUserId == null) return [];
      final userId = currentUserId!;

      final response = await _supabase
          .from('notification_delivery_logs')
          .select()
          .eq('user_id', userId)
          .inFilter('delivery_status', ['pending', 'deferred'])
          .order('scheduled_time', ascending: true);

      return (response as List)
          .map((e) => NotificationDeliveryLog.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending notifications: $e');
    }
  }

  // ==================== Helper Methods ====================

  String _getZoneForScore(int score) {
    if (score <= 40) return 'optimal';
    if (score <= 65) return 'moderate';
    if (score <= 80) return 'elevated';
    return 'critical';
  }

  /// Calculate daily analytics from mental load scores
  Future<void> calculateDailyAnalytics(DateTime date) async {
    try {
      if (currentUserId == null) return;

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      final scores = await getMentalLoadScores(
        startDate: startOfDay,
        endDate: endOfDay,
      );

      if (scores.isEmpty) return;

      final avgLoad =
          scores.map((e) => e.score).reduce((a, b) => a + b) / scores.length;
      final peakLoad = scores
          .map((e) => e.score)
          .reduce((a, b) => a > b ? a : b);

      final record = AnalyticsRecord(
        userId: currentUserId!,
        date: date,
        avgMentalLoad: avgLoad,
        peakMentalLoad: peakLoad,
        dataPointsCollected: scores.length,
        createdAt: DateTime.now(),
      );

      await saveAnalyticsRecord(record);
    } catch (e) {
      throw Exception('Failed to calculate daily analytics: $e');
    }
  }

  /// Check if error is transient and should be retried
  bool _isTransientError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('socket') ||
        errorString.contains('temporarily unavailable');
  }

  /// Get Supabase client (for notification service)
  dynamic get supabase => _supabase;
}