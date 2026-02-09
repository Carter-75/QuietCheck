import 'package:flutter/material.dart';

import '../presentation/analytics_view/analytics_view.dart';
import '../presentation/crash_report_viewer/crash_report_viewer.dart';
import '../presentation/dashboard/dashboard.dart';
import '../presentation/debug_console/debug_console.dart';
import '../presentation/diagnostics_dashboard/diagnostics_dashboard.dart';
import '../presentation/onboarding_flow/onboarding_flow.dart';
import '../presentation/permission_setup/permission_setup.dart';
import '../presentation/privacy_policy_generator/privacy_policy_generator.dart';
import '../presentation/recovery_guidance/recovery_guidance.dart';
import '../presentation/settings/settings.dart';
import '../presentation/sound_pack_selection/sound_pack_selection.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/subscription_management/subscription_management.dart';
import '../presentation/wellness_goals/wellness_goals.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String settings = '/settings';
  static const String splash = '/splash-screen';
  static const String permissionSetup = '/permission-setup';
  static const String analyticsView = '/analytics-view';
  static const String recoveryGuidance = '/recovery-guidance';
  static const String dashboard = '/dashboard';
  static const String subscriptionManagement = '/subscription-management';
  static const String onboardingFlow = '/onboarding-flow';
  static const String soundPackSelection = '/sound-pack-selection';
  static const String wellnessGoals = '/wellness-goals';
  static const String debugConsole = '/debug-console';
  static const String crashReportViewer = '/crash-report-viewer';
  static const String diagnosticsDashboard = '/diagnostics-dashboard';
  static const String privacyPolicyGenerator = '/privacy-policy-generator';

  static Map<String, WidgetBuilder> get routes => {
    initial: (context) => const SplashScreen(),
    settings: (context) => const Settings(),
    splash: (context) => const SplashScreen(),
    permissionSetup: (context) => const PermissionSetup(),
    analyticsView: (context) => const AnalyticsView(),
    recoveryGuidance: (context) => const RecoveryGuidance(),
    dashboard: (context) => const Dashboard(),
    subscriptionManagement: (context) => const SubscriptionManagement(),
    onboardingFlow: (context) => const OnboardingFlow(),
    soundPackSelection: (context) => const SoundPackSelection(),
    wellnessGoals: (context) => const WellnessGoals(),
    debugConsole: (context) => const DebugConsoleScreen(),
    crashReportViewer: (context) => const CrashReportViewerScreen(),
    diagnosticsDashboard: (context) => const DiagnosticsDashboardScreen(),
    privacyPolicyGenerator: (context) => const PrivacyPolicyGeneratorScreen(),
    // TODO: Add your other routes here
  };
}
