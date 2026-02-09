# Supabase Setup Guide for QuietCheck

## Overview
QuietCheck uses Supabase for:
- User authentication and profiles
- Mental health data storage with encryption
- Activity tracking and analytics
- Wellness goals and burnout predictions
- Notification delivery logs
- **Crash tracking and performance monitoring**
- **Session analytics**

## Environment Variables
The following Supabase credentials are already configured:
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Your Supabase anonymous key

## Database Schema
The project includes 7 migration files that create all necessary tables:

1. **20260203173900_mental_health_data_schema.sql**
   - user_profiles
   - mental_load_scores
   - analytics_records

2. **20260203174800_activity_tracking_schema.sql**
   - activity_tracking_records
   - app_usage_records

3. **20260203184300_enhanced_analytics_tracking.sql**
   - user_engagement_events
   - feature_adoption_metrics
   - subscription_conversions
   - retention_metrics

4. **20260203185000_burnout_prediction_tracking.sql**
   - burnout_predictions

5. **20260203190000_wellness_goals_schema.sql**
   - wellness_goals
   - goal_milestones
   - goal_ai_recommendations

6. **20260203200000_notification_delivery_logs.sql**
   - notification_delivery_logs

7. **20260203210000_crash_tracking_performance_monitoring.sql** (NEW)
   - crash_reports (replaces Firebase Crashlytics)
   - performance_metrics (replaces Firebase Performance)
   - session_analytics (replaces Firebase Analytics sessions)

## Analytics Implementation

### Crash Tracking
The app now uses Supabase instead of Firebase for crash tracking:
- Automatic crash capture via `CrashHandlerService`
- Stack traces stored in `crash_reports` table
- Device info, battery level, network status captured
- Crash severity levels: fatal, error, warning, info

### Session Analytics
User sessions are tracked in the `session_analytics` table:
- Session start/end timestamps
- Screens visited during session
- Features used
- Mental load checks and recovery sessions count
- Crash correlation

### Performance Monitoring
App performance metrics stored in `performance_metrics` table:
- Screen load times
- API call durations
- Mental load calculation performance
- AI analysis timing
- Database query performance

## Services

### SupabaseAnalyticsService
Replaces GoogleAnalyticsService with comprehensive Supabase-based analytics:
- `startSession()` / `endSession()` - Session management
- `trackScreenView(screenName)` - Screen tracking
- `trackFeatureUsage(featureName)` - Feature adoption
- `trackMentalLoadCheck()` - Mental load tracking
- `trackRecoverySession()` - Recovery session tracking
- `logCrash()` - Crash reporting
- `logPerformance()` - Performance metrics
- `measurePerformance()` - Automatic performance measurement

### Integration
All screens now track analytics:
- Dashboard: Load time, mental load checks
- Analytics View: Screen views
- Recovery Guidance: Session completion, breathing exercises
- Wellness Goals: Screen views
- Settings: Screen views
- Subscription: Screen views

## Migration Instructions

1. **Run migrations** in your Supabase dashboard:
   - Go to SQL Editor
   - Run each migration file in order (by timestamp)
   - Verify tables are created successfully

2. **Verify RLS policies**:
   - All tables have Row Level Security enabled
   - Users can only access their own data
   - Check policies in Table Editor → Policies

3. **Test analytics**:
   - Launch the app
   - Navigate through screens
   - Check `session_analytics` table for session data
   - Check `performance_metrics` for load times
   - Trigger an error to test crash reporting

## Data Privacy
- All sensitive data is encrypted before storage
- RLS policies ensure data isolation
- Crash reports include only necessary diagnostic info
- No personally identifiable information in analytics

## Removed Dependencies
The following Firebase packages have been removed:
- `firebase_core` - No longer needed
- `firebase_analytics` - Replaced with Supabase analytics
- `firebase_crashlytics` - Replaced with Supabase crash tracking

All analytics functionality is now handled by Supabase, providing:
- Full data ownership
- Better privacy control
- Unified backend
- No additional third-party dependencies