import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/supabase_analytics_service.dart';

class AnalyticsTrackingService {
  static AnalyticsTrackingService? _instance;
  static AnalyticsTrackingService get instance =>
      _instance ??= AnalyticsTrackingService._();

  AnalyticsTrackingService._();

  final SupabaseClient _supabase = SupabaseService.instance.client;
  final _supabaseAnalytics = SupabaseAnalyticsService.instance;
  String? _currentSessionId;

  // Session Management
  String get sessionId {
    _currentSessionId ??= _generateSessionId();
    return _currentSessionId!;
  }

  String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  void startNewSession() {
    _currentSessionId = _generateSessionId();
    trackEvent(eventType: 'session_start', eventName: 'Session Started');

    // Track session start in Supabase Analytics
    _supabaseAnalytics.startSession();
  }

  void endSession() {
    trackEvent(eventType: 'session_end', eventName: 'Session Ended');

    // Track session end in Supabase Analytics
    _supabaseAnalytics.endSession();

    _currentSessionId = null;
  }

  // User Engagement Tracking
  Future<void> trackEvent({
    required String eventType,
    required String eventName,
    String? screenName,
    Map<String, dynamic>? properties,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('user_engagement_events').insert({
        'user_id': userId,
        'event_type': eventType,
        'event_name': eventName,
        'screen_name': screenName,
        'event_properties': properties,
        'session_id': sessionId,
        'event_timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silent fail for analytics - don't disrupt user experience
    }
  }

  Future<void> trackScreenView(String screenName) async {
    await trackEvent(
      eventType: 'screen_view',
      eventName: 'Screen Viewed',
      screenName: screenName,
    );

    // Track screen view in Supabase Analytics
    await _supabaseAnalytics.trackScreenView(screenName);
  }

  Future<void> trackButtonClick(String buttonName, String screenName) async {
    await trackEvent(
      eventType: 'button_click',
      eventName: buttonName,
      screenName: screenName,
    );
  }

  Future<void> trackFeatureUsed({
    required String featureName,
    String? screenName,
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(
      eventType: 'feature_used',
      eventName: featureName,
      screenName: screenName,
      properties: properties,
    );
  }

  Future<void> trackError(String errorMessage, String screenName) async {
    await trackEvent(
      eventType: 'error_occurred',
      eventName: 'Error',
      screenName: screenName,
      properties: {'error_message': errorMessage},
    );

    // Log error to Supabase Analytics Crashlytics
    await _supabaseAnalytics.logCrash(
      errorMessage: errorMessage,
      stackTrace: 'Error on $screenName',
      screenName: screenName,
      severity: 'error',
    );
  }

  // Feature Adoption Tracking
  Future<void> trackFeatureAdoption({
    required String featureCategory,
    required String featureName,
    int timeSpentSeconds = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now().toIso8601String();

      // Upsert feature adoption record
      await _supabase.from('feature_adoption_metrics').upsert({
        'user_id': userId,
        'feature_category': featureCategory,
        'feature_name': featureName,
        'first_used_at': now,
        'last_used_at': now,
        'usage_count': 1,
        'total_time_spent_seconds': timeSpentSeconds,
        'is_active_user': true,
      }, onConflict: 'user_id,feature_category,feature_name');

      // Update existing record
      await _supabase
          .rpc(
            'increment_feature_usage',
            params: {
              'p_user_id': userId,
              'p_feature_category': featureCategory,
              'p_feature_name': featureName,
              'p_time_spent': timeSpentSeconds,
            },
          )
          .catchError((e) {
            // Fallback if RPC doesn't exist
          });
    } catch (e) {
      // Silent fail
    }
  }

  Future<Map<String, dynamic>?> getFeatureAdoptionStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('feature_adoption_metrics')
          .select()
          .eq('user_id', userId)
          .order('usage_count', ascending: false);

      return {
        'total_features_used': response.length,
        'most_used_features': response.take(5).toList(),
        'total_engagement_time': response.fold<int>(
          0,
          (sum, item) => sum + ((item['total_time_spent_seconds'] ?? 0) as int),
        ),
      };
    } catch (e) {
      return null;
    }
  }

  // Subscription Conversion Tracking
  Future<void> trackConversionStage({
    required String stage,
    String? conversionSource,
    String? pricingPlan,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get days since signup
      final userProfile = await _supabase
          .from('user_profiles')
          .select('created_at')
          .eq('id', userId)
          .single();

      final signupDate = DateTime.parse(userProfile['created_at']);
      final daysSinceSignup = DateTime.now().difference(signupDate).inDays;

      // Get trial days used
      final subscription = await _supabase
          .from('subscription_data')
          .select('trial_days_remaining')
          .eq('user_id', userId)
          .maybeSingle();

      final trialDaysUsed = subscription != null
          ? (7 - (subscription['trial_days_remaining'] ?? 7))
          : 0;

      await _supabase.from('subscription_conversions').insert({
        'user_id': userId,
        'conversion_stage': stage,
        'stage_timestamp': DateTime.now().toIso8601String(),
        'days_since_signup': daysSinceSignup,
        'trial_days_used': trialDaysUsed,
        'conversion_source': conversionSource,
        'pricing_plan': pricingPlan,
        'encrypted_conversion_data': additionalData,
      });
    } catch (e) {
      // Silent fail
    }
  }

  Future<List<Map<String, dynamic>>> getConversionFunnel() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('subscription_conversions')
          .select()
          .eq('user_id', userId)
          .order('stage_timestamp', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Retention Metrics
  Future<void> updateRetentionMetrics({
    required String retentionPeriod,
    required bool isRetained,
    int sessionsCount = 0,
    int engagementMinutes = 0,
    int featuresUsedCount = 0,
    int mentalLoadChecks = 0,
    int recoverySessionsCompleted = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('retention_metrics').upsert({
        'user_id': userId,
        'retention_period': retentionPeriod,
        'is_retained': isRetained,
        'last_active_date': DateTime.now().toIso8601String().split('T')[0],
        'sessions_count': sessionsCount,
        'total_engagement_minutes': engagementMinutes,
        'features_used_count': featuresUsedCount,
        'mental_load_checks': mentalLoadChecks,
        'recovery_sessions_completed': recoverySessionsCompleted,
      }, onConflict: 'user_id,retention_period');
    } catch (e) {
      // Silent fail
    }
  }

  Future<Map<String, dynamic>?> getRetentionStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('retention_metrics')
          .select()
          .eq('user_id', userId)
          .order('retention_period', ascending: true);

      return {
        'retention_data': response,
        'is_retained':
            response.isNotEmpty && response.last['is_retained'] == true,
        'total_sessions': response.fold<int>(
          0,
          (sum, item) => sum + ((item['sessions_count'] ?? 0) as int),
        ),
        'total_engagement_minutes': response.fold<int>(
          0,
          (sum, item) => sum + ((item['total_engagement_minutes'] ?? 0) as int),
        ),
      };
    } catch (e) {
      return null;
    }
  }

  // Privacy Compliance
  Future<void> deleteUserAnalyticsData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await Future.wait([
        _supabase.from('user_engagement_events').delete().eq('user_id', userId),
        _supabase
            .from('feature_adoption_metrics')
            .delete()
            .eq('user_id', userId),
        _supabase
            .from('subscription_conversions')
            .delete()
            .eq('user_id', userId),
        _supabase.from('retention_metrics').delete().eq('user_id', userId),
      ]);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> exportUserAnalyticsData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final results = await Future.wait([
        _supabase.from('user_engagement_events').select().eq('user_id', userId),
        _supabase
            .from('feature_adoption_metrics')
            .select()
            .eq('user_id', userId),
        _supabase
            .from('subscription_conversions')
            .select()
            .eq('user_id', userId),
        _supabase.from('retention_metrics').select().eq('user_id', userId),
      ]);

      return {
        'engagement_events': results[0],
        'feature_adoption': results[1],
        'subscription_conversions': results[2],
        'retention_metrics': results[3],
        'exported_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {};
    }
  }
}