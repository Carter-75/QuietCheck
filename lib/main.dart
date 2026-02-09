import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';
import './core/build_config.dart';
import './services/analytics_tracking_service.dart';
import './services/background_task_service_io.dart' as background_io;
import './services/crash_handler_service.dart';
import './services/debug_logging_service.dart';
import './services/gemini_service.dart';
import './services/health_service_io.dart' as health_io;
import './services/notification_service_io.dart' as notification_io;
import './services/supabase_analytics_service.dart';
import './services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize build config
  final buildConfig = BuildConfig.instance;

  // Initialize debug services (debug builds only)
  if (buildConfig.enableDebugFeatures) {
    await DebugLoggingService.instance.initialize();
    await CrashHandlerService.instance.initialize();
    DebugLoggingService.instance.info(
      'App started in ${buildConfig.buildMode} mode',
      category: 'lifecycle',
    );
  }

  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize Supabase Analytics (for crash tracking, session analytics, and performance monitoring)
  await SupabaseAnalyticsService.instance.initialize();

  // Initialize Gemini AI service
  try {
    GeminiService.instance.initialize();
    if (buildConfig.enableDebugFeatures) {
      DebugLoggingService.instance.info(
        'Gemini service initialized',
        category: 'services',
      );
    }
  } catch (e) {
    debugPrint('Gemini service initialization failed: $e');
    if (buildConfig.enableDebugFeatures) {
      DebugLoggingService.instance.error(
        'Gemini service initialization failed',
        category: 'services',
        error: e,
      );
    }
  }

  // Initialize health service
  try {
    await health_io.HealthService.instance.initialize();
    if (buildConfig.enableDebugFeatures) {
      DebugLoggingService.instance.info(
        'Health service initialized',
        category: 'services',
      );
    }
  } catch (e) {
    debugPrint('Health service initialization failed: $e');
    if (buildConfig.enableDebugFeatures) {
      DebugLoggingService.instance.error(
        'Health service initialization failed',
        category: 'services',
        error: e,
      );
    }
  }

  // Initialize notification service
  await notification_io.NotificationService.instance.initialize();

  // Initialize background task service
  await background_io.BackgroundTaskService.instance.initialize();
  await background_io.BackgroundTaskService.instance.startPeriodicTracking();
  await background_io.BackgroundTaskService.instance
      .startBurnoutPredictionTask();
  await background_io.BackgroundTaskService.instance
      .startNotificationProcessingTask();

  // Start analytics session
  AnalyticsTrackingService.instance.startNewSession();
  AnalyticsTrackingService.instance.trackEvent(
    eventType: 'app_open',
    eventName: 'App Launched',
  );

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  ]).then((value) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          title: 'quietcheck',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.initial,
        );
      },
    );
  }
}
