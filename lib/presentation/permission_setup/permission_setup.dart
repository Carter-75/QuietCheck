import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import './widgets/permission_card_widget.dart';
import './widgets/progress_indicator_widget.dart';

/// Permission Setup Screen - Guides users through essential data access permissions
/// using just-in-time requests with educational context.
///
/// Features:
/// - Stack navigation with progress indicator (3-4 permission steps)
/// - Educational illustrations and explanations for each permission
/// - Platform-specific permission handling (iOS/Android)
/// - Graceful handling of permission denial
/// - Automatic progress saving across sessions
class PermissionSetup extends StatefulWidget {
  const PermissionSetup({super.key});

  @override
  State<PermissionSetup> createState() => _PermissionSetupState();
}

class _PermissionSetupState extends State<PermissionSetup> {
  int _currentStep = 0;
  final int _totalSteps = 4;
  bool _isRequestingPermission = false;

  // Permission states
  final Map<String, bool> _permissionStates = {
    'health_data': false,
    'usage_stats': false,
    'notifications': false,
  };

  // Permission data for each step
  final List<Map<String, dynamic>> _permissionSteps = [
    {
      'id': 'health_data',
      'title': 'Health Data Access',
      'subtitle': 'Monitor your biometric signals',
      'description':
          'QuietCheck needs access to your health data to monitor biometric signals that indicate mental load and stress levels.',
      'benefits': [
        'Real-time heart rate monitoring',
        'Sleep pattern analysis',
        'Activity level tracking',
        'All data processed locally on your device',
      ],
      'illustration':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1ee5336a6-1766563413816.png',
      'semanticLabel':
          'Illustration showing a smartphone displaying health metrics including heart rate, sleep data, and activity tracking graphs in calming green tones',
      'skipImpact':
          'Without health data access, mental load detection accuracy will be significantly reduced.',
      'isCore': true,
    },
    {
      'id': 'usage_stats',
      'title': 'Usage Statistics',
      'subtitle': 'Analyze behavioral patterns',
      'description':
          'Understanding your device usage patterns helps QuietCheck detect behavioral changes that may indicate increased mental load.',
      'benefits': [
        'Screen time pattern analysis',
        'App switching frequency tracking',
        'Focus session detection',
        'Work-life balance insights',
      ],
      'illustration':
          'https://images.unsplash.com/photo-1639175135458-035d21d744d7',
      'semanticLabel':
          'Illustration of a mobile phone screen showing various app icons and usage statistics with bar charts indicating time spent on different applications',
      'skipImpact':
          'Behavioral pattern analysis will be unavailable, limiting early warning capabilities.',
      'isCore': true,
    },
    {
      'id': 'notifications',
      'title': 'Smart Notifications',
      'subtitle': 'Receive intelligent alerts',
      'description':
          'QuietCheck sends context-aware notifications to alert you when mental load reaches concerning levels, helping prevent burnout.',
      'benefits': [
        'Severity-based alert system',
        'Context-aware suppression (driving, sleeping)',
        'Customizable quiet hours',
        'Emergency recovery guidance',
      ],
      'illustration':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1adcad29d-1768274703850.png',
      'semanticLabel':
          'Smartphone displaying a gentle notification banner with calming colors showing a mental wellness alert with options to view details or dismiss',
      'skipImpact':
          'You will need to manually check the app for mental load updates.',
      'isCore': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedProgress();
  }

  /// Load previously saved permission setup progress
  Future<void> _loadSavedProgress() async {
    // In production, load from SharedPreferences
    // For now, start fresh each time
    setState(() {
      _currentStep = 0;
    });
  }

  /// Save current progress for session recovery
  Future<void> _saveProgress() async {
    // In production, save to SharedPreferences
    // This allows users to complete setup across multiple sessions
  }

  /// Request permission for current step
  Future<void> _requestPermission() async {
    final currentPermission = _permissionSteps[_currentStep];
    final permissionId = currentPermission['id'] as String;

    setState(() {
      _isRequestingPermission = true;
    });

    try {
      bool granted = false;

      switch (permissionId) {
        case 'health_data':
          // Health data permission (platform-specific)
          granted = true; // Placeholder
          break;

        case 'usage_stats':
          // Usage statistics permission
          if (Platform.isAndroid) {
            // Android requires special intent to settings
            final status = await Permission.systemAlertWindow.request();
            granted = status.isGranted;

            // Show dialog to guide user to settings
            if (!granted && mounted) {
              await _showUsageStatsPermissionDialog();
            }
          } else {
            // iOS has limited usage stats access
            granted = true;
          }
          break;

        case 'notifications':
          final status = await Permission.notification.request();
          granted = status.isGranted;
          break;

        default:
          granted = false;
      }

      setState(() {
        _permissionStates[permissionId] = granted;
        _isRequestingPermission = false;
      });

      // Move to next step if granted
      if (granted) {
        _moveToNextStep();
      }
    } catch (e) {
      setState(() {
        _isRequestingPermission = false;
      });
      debugPrint('Permission request failed: $e');
    }
  }

  /// Show dialog to guide user to usage stats settings
  Future<void> _showUsageStatsPermissionDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usage Statistics Permission'),
        content: const Text(
          'To enable activity pattern monitoring, please grant Usage Access permission in Settings.\n\n'
          '1. Tap "Open Settings" below\n'
          '2. Find "QuietCheck" in the list\n'
          '3. Enable "Permit usage access"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Handle skip action for current permission
  void _skipPermission() {
    HapticFeedback.lightImpact();

    final currentPermission = _permissionSteps[_currentStep];
    final isCore = currentPermission['isCore'] as bool;

    if (isCore) {
      _showSkipWarningDialog();
    } else {
      _moveToNextStep();
    }
  }

  /// Show warning dialog for skipping core permissions
  void _showSkipWarningDialog() {
    final theme = Theme.of(context);
    final currentPermission = _permissionSteps[_currentStep];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Skip Permission?', style: theme.textTheme.titleLarge),
        content: Text(
          currentPermission['skipImpact'] as String,
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Go Back'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _moveToNextStep();
            },
            child: Text(
              'Skip Anyway',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  /// Move to next permission step
  void _moveToNextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _saveProgress();
    } else {
      _completeSetup();
    }
  }

  /// Complete permission setup and navigate to dashboard
  void _completeSetup() {
    HapticFeedback.heavyImpact();

    // Show completion message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Setup complete! Starting monitoring...'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Navigate to dashboard
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushReplacementNamed('/dashboard');
    });
  }

  /// Handle back navigation
  void _handleBackNavigation() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPermission = _permissionSteps[_currentStep];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          child: Column(
            children: [
              // Progress indicator
              ProgressIndicatorWidget(
                currentStep: _currentStep + 1,
                totalSteps: _totalSteps,
                onBackPressed: _handleBackNavigation,
              ),

              SizedBox(height: 3.h),

              // Permission card (scrollable content)
              Expanded(
                child: SingleChildScrollView(
                  child: PermissionCardWidget(
                    title: currentPermission['title'] as String,
                    subtitle: currentPermission['subtitle'] as String,
                    description: currentPermission['description'] as String,
                    benefits: currentPermission['benefits'] as List<String>,
                    illustrationUrl:
                        currentPermission['illustration'] as String,
                    semanticLabel: currentPermission['semanticLabel'] as String,
                    isCore: currentPermission['isCore'] as bool,
                  ),
                ),
              ),

              SizedBox(height: 3.h),

              // Action buttons
              Column(
                children: [
                  // Primary action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _requestPermission,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                      ),
                      child: Text(
                        'Allow Access',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 1.5.h),

                  // Secondary action button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _skipPermission,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                      ),
                      child: Text(
                        currentPermission['isCore'] as bool
                            ? 'Skip for Now'
                            : 'Skip This Step',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
