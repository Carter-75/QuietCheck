import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/background_task_service.dart';
import '../../widgets/custom_icon_widget.dart';

/// Splash Screen for QuietCheck mental health monitoring application.
/// Provides branded launch experience while initializing services and determining navigation path.
///
/// Features:
/// - Full-screen branded display with breathing animation
/// - Background service initialization (auth, preferences, health APIs, storage)
/// - Smart navigation routing based on user state
/// - Platform-specific health API initialization
/// - Edge case handling (API unavailable, app updates)
/// - Accessibility support (reduced motion)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _breathingAnimation;
  final bool _isInitializing = true;
  String _initializationStatus = 'Initializing QuietCheck...';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  /// Setup breathing animation for logo
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Check for reduced motion preference
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    if (!reducedMotion) {
      _animationController.repeat(reverse: true);
    }
  }

  /// Initialize app services and determine navigation route
  Future<void> _initializeApp() async {
    try {
      // Start background activity tracking
      await BackgroundTaskService.instance.startPeriodicTracking();

      // Minimum display time for branding
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 1: Check authentication status
      setState(() => _initializationStatus = 'Checking authentication...');
      await Future.delayed(const Duration(milliseconds: 300));
      final isAuthenticated = await _checkAuthenticationStatus();

      // Step 2: Load user preferences
      setState(() => _initializationStatus = 'Loading preferences...');
      await Future.delayed(const Duration(milliseconds: 300));
      final hasCompletedOnboarding = await _loadUserPreferences();

      // Step 3: Initialize health API connections
      setState(
        () => _initializationStatus = 'Connecting to health services...',
      );
      await Future.delayed(const Duration(milliseconds: 400));
      final healthApiStatus = await _initializeHealthAPIs();

      // Step 4: Prepare encrypted local storage
      setState(() => _initializationStatus = 'Securing your data...');
      await Future.delayed(const Duration(milliseconds: 300));
      await _prepareLocalStorage();

      // Step 5: Check for app updates and changelog
      final hasUpdate = await _checkForUpdates();

      // Minimum total splash time (2-3 seconds)
      await Future.delayed(const Duration(milliseconds: 200));

      // Navigation logic
      if (!mounted) return;

      // Haptic feedback for transition
      HapticFeedback.lightImpact();

      if (!isAuthenticated || !hasCompletedOnboarding) {
        // New users or incomplete setup
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/onboarding-flow');
      } else if (!healthApiStatus['available']) {
        // Health API unavailable - show degraded mode notification then go to dashboard
        _showDegradedModeNotification();
        await Future.delayed(const Duration(milliseconds: 1500));
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/dashboard');
      } else if (hasUpdate) {
        // Show changelog modal then go to dashboard
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/dashboard');
        // Changelog would be shown as overlay after navigation
      } else {
        // Normal flow - go to dashboard
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      // Error handling - proceed to onboarding as safe fallback
      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/onboarding-flow');
      }
    }
  }

  /// Check if user is authenticated
  Future<bool> _checkAuthenticationStatus() async {
    // Mock implementation - would check secure storage for auth token
    await Future.delayed(const Duration(milliseconds: 100));
    return true; // Simulating authenticated user
  }

  /// Load user preferences and check onboarding completion
  Future<bool> _loadUserPreferences() async {
    // Mock implementation - would load from shared preferences
    await Future.delayed(const Duration(milliseconds: 100));
    return true; // Simulating completed onboarding
  }

  /// Initialize health API connections (HealthKit/Health Connect)
  Future<Map<String, dynamic>> _initializeHealthAPIs() async {
    // Mock implementation - would initialize platform-specific health APIs
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'available': true,
      'permissions': ['heart_rate', 'activity', 'sleep'],
    };
  }

  /// Prepare encrypted local storage
  Future<void> _prepareLocalStorage() async {
    // Mock implementation - would initialize encrypted storage
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Check for app updates
  Future<bool> _checkForUpdates() async {
    // Mock implementation - would check version against server
    await Future.delayed(const Duration(milliseconds: 100));
    return false;
  }

  /// Show degraded mode notification
  void _showDegradedModeNotification() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Health monitoring unavailable. Running in limited mode.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    // Set system UI overlay style to match brand
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
    );

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.1),
              theme.colorScheme.secondary.withValues(alpha: 0.05),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Spacer for vertical centering
              const Spacer(flex: 2),

              // Logo with breathing animation
              reducedMotion
                  ? _buildStaticLogo(theme)
                  : AnimatedBuilder(
                      animation: _breathingAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _breathingAnimation.value,
                          child: child,
                        );
                      },
                      child: _buildStaticLogo(theme),
                    ),

              SizedBox(height: 6.h),

              // App name
              Text(
                'QuietCheck',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),

              SizedBox(height: 1.h),

              // Tagline
              Text(
                'Your Mental Wellness Companion',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),

              const Spacer(flex: 2),

              // Loading indicator
              SizedBox(
                width: 8.w,
                height: 8.w,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),

              SizedBox(height: 2.h),

              // Initialization status
              Text(
                _initializationStatus,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }

  /// Build static logo (used for both animated and non-animated versions)
  Widget _buildStaticLogo(ThemeData theme) {
    return Container(
      width: 30.w,
      height: 30.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: CustomIconWidget(
          iconName: 'favorite',
          color: theme.colorScheme.onPrimary,
          size: 15.w,
        ),
      ),
    );
  }
}
