# QuietCheck - Passive Mental Load & Burnout Detection

## Overview
QuietCheck is a privacy-first Android application that passively monitors mental load and predicts burnout risk using behavioral patterns, app usage data, and optional wearable integration.

## Tech Stack
- **Framework**: Flutter 3.16.0
- **Language**: Dart 3.2.0
- **Backend**: Supabase (authentication, database, analytics)
- **AI**: Google Gemini Pro (behavioral analysis)
- **Analytics**: Supabase Analytics (crash tracking, session analytics, performance monitoring)
- **Payments**: Google Play In-App Purchases
- **Health Data**: Android Health Connect

## Key Features
- **Passive Mental Load Tracking**: Real-time mental load gauge with zone-based alerts
- **Burnout Prediction**: 48-hour advance warning using AI analysis
- **Recovery Guidance**: Breathing exercises, quick relief techniques, emergency resources
- **Analytics Dashboard**: Trend charts, baseline comparison, sleep correlation
- **Wellness Goals**: Personalized goals with AI recommendations and milestone tracking
- **Subscription Management**: 7-day free trial, $1.99/month premium features
- **Privacy Controls**: Encrypted data storage, granular permission management
- **Sound System**: Customizable alert sounds with severity-based playback
- **Diagnostics**: Debug console, crash report viewer, privacy policy generator

## Analytics & Monitoring

### Supabase Analytics (Replaces Firebase)
The app uses Supabase for comprehensive analytics:

**Crash Tracking**:
- Automatic crash capture with stack traces
- Device info, battery level, network status
- Crash severity levels (fatal, error, warning, info)
- Stored in `crash_reports` table

**Session Analytics**:
- Session start/end tracking
- Screens visited and features used
- Mental load checks and recovery sessions
- Stored in `session_analytics` table

**Performance Monitoring**:
- Screen load times
- API call durations
- Mental load calculation performance
- AI analysis timing
- Stored in `performance_metrics` table

### Services
- `SupabaseAnalyticsService`: Main analytics service
- `AnalyticsTrackingService`: User engagement tracking
- `CrashHandlerService`: Crash capture and reporting
- `DebugLoggingService`: Local debug logging

## Environment Variables
Required environment variables (add to `.env` file):

```env
# Supabase (Required)
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-supabase-anon-key

# AI Services
GEMINI_API_KEY=your-gemini-api-key

# Optional AI Services
OPENAI_API_KEY=your-openai-api-key
ANTHROPIC_API_KEY=your-anthropic-api-key
PERPLEXITY_API_KEY=your-perplexity-api-key

# Google Services
GOOGLE_WEB_CLIENT_ID=your-google-client-id
GA_MEASUREMENT_ID=your-ga-measurement-id
```

## Database Schema
See `SUPABASE_SETUP.md` for complete schema documentation.

7 migration files create:
- User profiles and authentication
- Mental health data (encrypted)
- Activity tracking
- Enhanced analytics
- Burnout predictions
- Wellness goals
- Notification logs
- **Crash reports and performance metrics** (NEW)

## Project Structure
```
lib/
├── main.dart                    # App entry point
├── core/
│   ├── app_export.dart         # Core exports
│   └── build_config.dart       # Build configuration
├── models/                      # Data models
├── presentation/                # UI screens
│   ├── dashboard/
│   ├── analytics_view/
│   ├── recovery_guidance/
│   ├── wellness_goals/
│   ├── subscription_management/
│   ├── settings/
│   └── diagnostics_dashboard/
├── services/                    # Business logic
│   ├── supabase_service.dart
│   ├── supabase_analytics_service.dart  # NEW: Replaces Firebase
│   ├── analytics_tracking_service.dart
│   ├── crash_handler_service.dart
│   ├── debug_logging_service.dart
│   ├── data_service.dart
│   ├── gemini_service.dart
│   ├── health_service.dart
│   ├── notification_service.dart
│   ├── background_task_service.dart
│   ├── in_app_purchase_service.dart
│   ├── sound_system_service.dart
│   └── encryption_service.dart
├── routes/
│   └── app_routes.dart         # Navigation routes
├── theme/
│   └── app_theme.dart          # App theming
└── widgets/                     # Reusable widgets

supabase/
└── migrations/                  # Database migrations (7 files)

docs/
├── GOOGLE_PLAY_LISTING.md      # Play Store listing
├── PRODUCTION_RELEASE_CHECKLIST.md
├── PRIVACY_POLICY.md
└── SOUND_ASSETS_GUIDE.md
```

## Build Flavors
- **Debug**: Full diagnostics, crash viewer, debug console
- **Staging**: Production-like with diagnostics
- **Release**: Production build for Google Play Store

## Getting Started

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Configure Supabase**:
   - Create project at https://supabase.com
   - Run migrations in SQL Editor
   - Add credentials to `.env`

3. **Configure Gemini AI**:
   - Get API key from https://ai.google.dev
   - Add to `.env`

4. **Run the app**:
   ```bash
   flutter run
   ```

## Google Play Store Deployment

1. **Review checklist**: `docs/PRODUCTION_RELEASE_CHECKLIST.md`
2. **Build release**: `flutter build appbundle --release`
3. **Upload to Play Console**: Upload `.aab` file
4. **Configure subscription**: Set up in-app product in Play Console
5. **Submit for review**

See `docs/GOOGLE_PLAY_LISTING.md` for complete store listing content.

## Privacy & Compliance
- GDPR, CCPA, PIPEDA compliant
- End-to-end encryption for sensitive data
- Granular permission controls
- User data export/deletion
- Privacy policy generator included

## License
Proprietary - All rights reserved

## Support
For issues or questions, contact: support@quietcheck.app
